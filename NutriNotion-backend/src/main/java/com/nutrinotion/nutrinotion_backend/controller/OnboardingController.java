package com.nutrinotion.nutrinotion_backend.controller;

import com.nutrinotion.nutrinotion_backend.dto.OnboardingRequest;
import com.nutrinotion.nutrinotion_backend.dto.OnboardingResponse;
import com.nutrinotion.nutrinotion_backend.service.OnboardingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/onboarding")
@CrossOrigin(origins = "*")
public class OnboardingController {

    @Autowired
    private OnboardingService onboardingService;

    /**
     * PUT /api/onboarding/{userId}
     * Submit onboarding data → updates existing user profile, calculates targets,
     * sets onboardingCompleted = true.
     */
    @PutMapping("/{userId}")
    public ResponseEntity<OnboardingResponse> saveOnboarding(
            @PathVariable Long userId,
            @RequestBody OnboardingRequest request) {
        OnboardingResponse response = onboardingService.saveOnboarding(userId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/onboarding/{userId}
     * Fetch saved onboarding / profile data.
     */
    @GetMapping("/{userId}")
    public ResponseEntity<OnboardingResponse> getOnboarding(@PathVariable Long userId) {
        OnboardingResponse response = onboardingService.getOnboarding(userId);
        return ResponseEntity.ok(response);
    }
}
