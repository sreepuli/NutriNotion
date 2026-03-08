package com.nutrinotion.nutrinotion_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Phase-1 Security Configuration — password hashing only, no JWT yet.
 *
 * Rules:
 *  - CSRF disabled  (Flutter uses stateless REST — no browser sessions)
 *  - Session stateless (prepares for JWT in Phase 2)
 *  - ALL endpoints permitted for now — JWT role-based restrictions come later
 *  - HTTP Basic and form-login both disabled so Spring's auto-login page never
 *    intercepts API calls
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // ── Disable CSRF — not needed for stateless REST APIs ─────────────
            .csrf(AbstractHttpConfigurer::disable)

            // ── Stateless session — no HttpSession created or used ────────────
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // ── Disable Spring's default HTML login form ──────────────────────
            .formLogin(AbstractHttpConfigurer::disable)

            // ── Disable HTTP Basic popup in browsers ──────────────────────────
            .httpBasic(AbstractHttpConfigurer::disable)

            // ── Authorization rules ───────────────────────────────────────────
            .authorizeHttpRequests(auth -> auth
                // Auth endpoints — always open
                .requestMatchers("/api/auth/**").permitAll()
                // All other endpoints permitted for now (JWT guards added in Phase 2)
                .anyRequest().permitAll()
            );

        return http.build();
    }
}

