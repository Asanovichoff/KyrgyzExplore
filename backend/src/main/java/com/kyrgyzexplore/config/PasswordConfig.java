package com.kyrgyzexplore.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * WHY is this in its own class instead of inside SecurityConfig?
 * SecurityConfig needs PasswordEncoder as a constructor dependency.
 * If PasswordEncoder is defined inside SecurityConfig, Spring detects a circular
 * dependency: SecurityConfig → PasswordEncoder → SecurityConfig.
 * Keeping it here breaks the cycle.
 */
@Configuration
public class PasswordConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
