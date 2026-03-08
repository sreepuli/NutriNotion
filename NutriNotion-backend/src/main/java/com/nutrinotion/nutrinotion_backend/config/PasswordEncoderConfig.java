package com.nutrinotion.nutrinotion_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Declares PasswordEncoder as a standalone @Bean so it can be injected
 * into AuthService without any circular dependency through SecurityConfig.
 */
@Configuration
public class PasswordEncoderConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt with default strength (10 rounds) — safe and widely recommended
        return new BCryptPasswordEncoder();
    }
}

