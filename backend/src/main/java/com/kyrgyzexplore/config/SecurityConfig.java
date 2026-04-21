package com.kyrgyzexplore.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Minimal security config for Phase 1 scaffold.
 * Only /api/v1/health is public — everything else requires auth.
 * We will expand this in Phase 2 when we add JWT authentication.
 *
 * WHY disable CSRF?
 * CSRF attacks exploit browser cookie-based sessions. Since we use JWT tokens
 * sent in the Authorization header (not cookies), there is no CSRF risk.
 * Disabling it keeps our REST API stateless.
 *
 * WHY STATELESS session?
 * We don't want Spring to create HTTP sessions at all — every request must
 * carry a JWT. This forces us to be truly stateless, which is required for
 * scaling to multiple server instances.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/health").permitAll()
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
