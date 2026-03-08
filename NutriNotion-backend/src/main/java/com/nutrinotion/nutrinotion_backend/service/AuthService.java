package com.nutrinotion.nutrinotion_backend.service;

import com.nutrinotion.nutrinotion_backend.dto.AuthResponse;
import com.nutrinotion.nutrinotion_backend.dto.LoginRequest;
import com.nutrinotion.nutrinotion_backend.dto.SignupRequest;
import com.nutrinotion.nutrinotion_backend.model.User;
import com.nutrinotion.nutrinotion_backend.model.UserProfile;
import com.nutrinotion.nutrinotion_backend.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    @Autowired
    private UserRepo userRepo;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Transactional
    public AuthResponse signup(SignupRequest request) {
        // Guard against duplicate emails
        if (userRepo.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email is already registered.");
        }

        // ── 1. Create auth record — store BCrypt-hashed password ─────────────
        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));

        // ── 2. Create stub profile (linked immediately) ───────────────────────
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setName(request.getName());
        profile.setOnboardingCompleted(false);

        // Set the inverse side so Hibernate cascades correctly
        user.setProfile(profile);

        User saved = userRepo.save(user); // cascades to user_profiles
        return toAuthResponse(saved);
    }

    public AuthResponse login(LoginRequest request) {
        // Fetch the user by email, then verify the raw password against the stored hash
        User user = userRepo.findByEmail(request.getEmail())
                .filter(u -> passwordEncoder.matches(request.getPassword(), u.getPassword()))
                .orElseThrow(() -> new RuntimeException("Invalid email or password."));
        return toAuthResponse(user);
    }

    // ─────────────────────────────────────────────────────────────────────────
    private AuthResponse toAuthResponse(User user) {
        UserProfile profile = user.getProfile();
        String name = (profile != null) ? profile.getName() : null;
        boolean onboardingCompleted = (profile != null) && profile.isOnboardingCompleted();
        return new AuthResponse(user.getId(), user.getEmail(), name, onboardingCompleted);
    }
}


