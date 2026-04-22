package com.kyrgyzexplore.auth;

import com.kyrgyzexplore.user.UserDetailsServiceImpl;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Runs once per HTTP request. Extracts the JWT from the Authorization header,
 * validates it, and puts the authenticated user into the SecurityContext.
 *
 * After this filter runs, controllers can use @AuthenticationPrincipal User user
 * to get the current logged-in user — no database lookup needed in the controller.
 *
 * WHY OncePerRequestFilter?
 * Spring's filter chain can call filters multiple times in some edge cases
 * (e.g. error dispatches). OncePerRequestFilter guarantees exactly one execution.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsServiceImpl userDetailsService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        // If there's no Bearer token, skip this filter — the request will hit the
        // security rules and get rejected if the endpoint requires auth.
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7); // remove "Bearer " prefix

        if (!jwtService.isTokenValid(token)) {
            filterChain.doFilter(request, response);
            return;
        }

        // Only set authentication if no auth is already set (avoid double-processing)
        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                UUID userId = jwtService.extractUserId(token);
                UserDetails userDetails = userDetailsService.loadUserByUserId(userId);

                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities());
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            } catch (UsernameNotFoundException | IllegalArgumentException e) {
                // UsernameNotFoundException: user deleted after token was issued
                // IllegalArgumentException: malformed UUID in subject claim
                log.debug("Could not authenticate from JWT: {}", e.getMessage());
            }
        }

        filterChain.doFilter(request, response);
    }
}
