package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AuthResponse {
    private Long userId;
    private String email;
    private String name;               // null until onboarding is done
    private boolean onboardingCompleted;
}
