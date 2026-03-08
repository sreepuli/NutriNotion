package com.nutrinotion.nutrinotion_backend.controller;

import com.nutrinotion.nutrinotion_backend.dto.AuthResponse;
import com.nutrinotion.nutrinotion_backend.dto.LoginRequest;
import com.nutrinotion.nutrinotion_backend.dto.SignupRequest;
import com.nutrinotion.nutrinotion_backend.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/signup")
    public AuthResponse signup(@RequestBody SignupRequest request) {
        return authService.signup(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }
}
