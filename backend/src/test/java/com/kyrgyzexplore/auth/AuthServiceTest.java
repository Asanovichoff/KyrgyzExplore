package com.kyrgyzexplore.auth;

import com.kyrgyzexplore.auth.dto.LoginRequest;
import com.kyrgyzexplore.auth.dto.RegisterRequest;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.email.EmailService;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import com.kyrgyzexplore.user.UserRole;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private RefreshTokenRepository refreshTokenRepository;
    @Mock private JwtService jwtService;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private EmailService emailService;

    @InjectMocks
    private AuthService authService;

    // ── Register ──────────────────────────────────────────────────────────────

    @Test
    void register_throwsWhenEmailAlreadyTaken() {
        when(userRepository.existsByEmail("taken@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(registerRequest("taken@example.com")))
                .isInstanceOf(AppException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    void register_succeedsWithNewEmail() {
        when(userRepository.existsByEmail(any())).thenReturn(false);
        when(passwordEncoder.encode(any())).thenReturn("hashed");
        when(userRepository.save(any())).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            ReflectionTestUtils.setField(u, "id", UUID.randomUUID());
            return u;
        });
        when(jwtService.generateAccessToken(any())).thenReturn("access-token");
        when(jwtService.generateRawRefreshToken()).thenReturn("refresh-token");
        when(jwtService.hashToken(any())).thenReturn("hashed-token");
        when(jwtService.getRefreshExpirationMs()).thenReturn(86_400_000L);
        when(refreshTokenRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // Should not throw
        authService.register(registerRequest("new@example.com"));
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    @Test
    void login_throwsWithWrongPassword() {
        User user = activeUser();
        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrong", user.getPasswordHash())).thenReturn(false);

        // WHY BadCredentialsException and not AppException?
        // We throw BadCredentialsException to avoid leaking whether the email or
        // password was wrong (account enumeration prevention).
        assertThatThrownBy(() -> authService.login(loginRequest("user@example.com", "wrong")))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void login_throwsWhenAccountSuspended() {
        User user = activeUser();
        user.setActive(false);
        when(userRepository.findByEmail("suspended@example.com")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(loginRequest("suspended@example.com", "any")))
                .isInstanceOf(AppException.class)
                .hasMessageContaining("suspended");
    }

    @Test
    void login_throwsWhenUserNotFound() {
        when(userRepository.findByEmail(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(loginRequest("ghost@example.com", "any")))
                .isInstanceOf(BadCredentialsException.class);
    }

    // ── Refresh ───────────────────────────────────────────────────────────────

    @Test
    void refresh_throwsWithInvalidToken() {
        when(jwtService.hashToken("bad-token")).thenReturn("bad-hash");
        when(refreshTokenRepository.findByTokenHash("bad-hash")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.refresh("bad-token"))
                .isInstanceOf(AppException.class)
                .hasMessageContaining("invalid or expired");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private RegisterRequest registerRequest(String email) {
        RegisterRequest req = new RegisterRequest();
        ReflectionTestUtils.setField(req, "email", email);
        ReflectionTestUtils.setField(req, "password", "password123");
        ReflectionTestUtils.setField(req, "firstName", "Test");
        ReflectionTestUtils.setField(req, "lastName", "User");
        ReflectionTestUtils.setField(req, "role", UserRole.TRAVELER);
        return req;
    }

    private LoginRequest loginRequest(String email, String password) {
        LoginRequest req = new LoginRequest();
        ReflectionTestUtils.setField(req, "email", email);
        ReflectionTestUtils.setField(req, "password", password);
        return req;
    }

    private User activeUser() {
        User u = User.builder()
                .email("user@example.com")
                .passwordHash("hashed-pw")
                .firstName("Test")
                .lastName("User")
                .role(UserRole.TRAVELER)
                .build();
        ReflectionTestUtils.setField(u, "id", UUID.randomUUID());
        u.setActive(true);
        return u;
    }
}
