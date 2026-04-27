package com.kyrgyzexplore.config;

import com.kyrgyzexplore.auth.JwtAuthFilter;
import com.kyrgyzexplore.user.UserDetailsServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * WHY disable CSRF?
 * CSRF attacks exploit browser cookie-based sessions. Since we use JWT tokens
 * sent in the Authorization header (not cookies), there is no CSRF risk.
 *
 * WHY STATELESS session?
 * We don't want Spring to create HTTP sessions — every request carries a JWT.
 * This is required for scaling to multiple server instances.
 *
 * WHY add JwtAuthFilter BEFORE UsernamePasswordAuthenticationFilter?
 * The filter chain runs in order. We must stamp the SecurityContext with the
 * authenticated user BEFORE Spring's built-in filters check for authentication.
 * If JwtAuthFilter ran after, all requests would fail with 401 before we could
 * set the auth context.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final UserDetailsServiceImpl userDetailsService;
    private final PasswordEncoder passwordEncoder;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/health").permitAll()
                .requestMatchers("/api/v1/auth/register", "/api/v1/auth/login",
                                 "/api/v1/auth/refresh").permitAll()
                .requestMatchers("/api/v1/webhooks/stripe").permitAll()
                // WebSocket HTTP upgrade must be open — JWT auth happens inside the STOMP CONNECT frame,
                // not in the HTTP handshake. See WebSocketSecurityConfig for the JWT validation logic.
                .requestMatchers("/ws/**").permitAll()
                // Public read-only endpoints — no login needed to browse listings or reviews
                .requestMatchers(org.springframework.http.HttpMethod.GET,
                        "/api/v1/listings", "/api/v1/listings/**",
                        "/api/v1/reviews/listing/**").permitAll()
                .anyRequest().authenticated()
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder);
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }
}
