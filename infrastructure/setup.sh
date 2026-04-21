#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# KyrgyzExplore — Local Environment Setup Script
# ═══════════════════════════════════════════════════════════════
# Run once after cloning the repo:
#   chmod +x infrastructure/setup.sh
#   ./infrastructure/setup.sh

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   KyrgyzExplore — Environment Setup  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Check prerequisites ───────────────────────────────────────
echo -e "${BOLD}1. Checking prerequisites...${NC}"

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "   ${GREEN}✓${NC} $1 found"
    else
        echo -e "   ${RED}✗ $1 not found — please install it${NC}"
        MISSING=true
    fi
}

check_command docker
check_command docker-compose
check_command java
check_command mvn
check_command flutter
check_command git

if [ "$MISSING" = true ]; then
    echo ""
    echo -e "${RED}Please install missing prerequisites and re-run.${NC}"
    exit 1
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 21 ]; then
    echo -e "   ${RED}✗ Java 21+ required (found Java $JAVA_VERSION)${NC}"
    echo "   Install from: https://adoptium.net/"
    exit 1
else
    echo -e "   ${GREEN}✓${NC} Java $JAVA_VERSION found"
fi

echo ""

# ── Environment file ──────────────────────────────────────────
echo -e "${BOLD}2. Setting up environment file...${NC}"
cd "$(dirname "$0")"

if [ -f ".env" ]; then
    echo -e "   ${YELLOW}⚠ .env already exists — skipping (edit manually if needed)${NC}"
else
    cp .env.example .env
    echo -e "   ${GREEN}✓${NC} Created .env from .env.example"
    echo -e "   ${YELLOW}➜ Open infrastructure/.env and fill in your secrets before continuing${NC}"
    echo ""
    read -p "   Have you filled in your secrets in .env? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Exiting. Re-run after filling in .env"
        exit 1
    fi
fi
echo ""

# ── Docker services ───────────────────────────────────────────
echo -e "${BOLD}3. Starting Docker services (PostgreSQL, Redis, PgAdmin, MailHog)...${NC}"
docker-compose up -d

echo -e "   Waiting for PostgreSQL to be ready..."
until docker-compose exec -T postgres pg_isready -U kyrgyz -d kyrgyzexplore &>/dev/null; do
    sleep 2
done
echo -e "   ${GREEN}✓${NC} PostgreSQL is ready"

echo -e "   Waiting for Redis to be ready..."
REDIS_PASS=$(grep REDIS_PASSWORD .env | cut -d'=' -f2)
until docker-compose exec -T redis redis-cli -a "$REDIS_PASS" ping &>/dev/null; do
    sleep 2
done
echo -e "   ${GREEN}✓${NC} Redis is ready"
echo ""

# ── Backend dependencies ──────────────────────────────────────
echo -e "${BOLD}4. Downloading backend dependencies...${NC}"
cd ../backend
if [ -f "mvnw" ]; then
    ./mvnw dependency:resolve -q
    echo -e "   ${GREEN}✓${NC} Backend dependencies downloaded"
else
    echo -e "   ${YELLOW}⚠ backend/pom.xml not found yet — skipping (run after Backend Agent scaffolds the project)${NC}"
fi
cd ../infrastructure
echo ""

# ── Flutter dependencies ──────────────────────────────────────
echo -e "${BOLD}5. Downloading Flutter dependencies...${NC}"
cd ../frontend
if [ -f "pubspec.yaml" ]; then
    flutter pub get
    echo -e "   ${GREEN}✓${NC} Flutter packages installed"

    echo -e "   Running code generation (Riverpod + JSON serialization)..."
    dart run build_runner build --delete-conflicting-outputs 2>/dev/null || \
        echo -e "   ${YELLOW}⚠ build_runner not yet set up — run manually after Frontend Agent scaffolds the project${NC}"
else
    echo -e "   ${YELLOW}⚠ frontend/pubspec.yaml not found yet — skipping${NC}"
fi
cd ../infrastructure
echo ""

# ── Git hooks ─────────────────────────────────────────────────
echo -e "${BOLD}6. Installing git hooks...${NC}"
cd ..
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit: block .env files from being committed
if git diff --cached --name-only | grep -qE '\.env$'; then
    echo "ERROR: Attempted to commit a .env file. This is blocked for security."
    echo "Use .env.example for templates instead."
    exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
echo -e "   ${GREEN}✓${NC} Git hooks installed (blocks .env commits)"
cd infrastructure
echo ""

# ── Summary ───────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Setup complete! 🎉${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Services running:${NC}"
echo -e "    PostgreSQL   → localhost:5432"
echo -e "    Redis        → localhost:6379"
echo -e "    PgAdmin      → http://localhost:5050  (admin@kyrgyz.local / admin)"
echo -e "    MailHog      → http://localhost:8025"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    1. Start backend:   cd backend && ./mvnw spring-boot:run"
echo -e "    2. Start frontend:  cd frontend && flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1"
echo ""
echo -e "  ${BOLD}Claude Code agents:${NC}"
echo -e "    Architecture:  claude --system-prompt agents/architecture-agent.md"
echo -e "    Backend:       cd backend && claude --system-prompt ../agents/backend-agent.md"
echo -e "    Frontend:      cd frontend && claude --system-prompt ../agents/frontend-agent.md"
echo -e "    Database:      cd database && claude --system-prompt ../agents/database-agent.md"
echo ""
