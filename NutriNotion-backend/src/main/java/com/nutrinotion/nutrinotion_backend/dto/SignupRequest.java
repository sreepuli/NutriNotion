package com.nutrinotion.nutrinotion_backend.dto;

import lombok.Data;

@Data
public class SignupRequest {
    private String name;      // stored in user_profiles at signup
    private String email;
    private String password;
}
