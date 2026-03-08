package com.nutrinotion.nutrinotion_backend.controller;

import com.nutrinotion.nutrinotion_backend.dto.AuthResponse;
import com.nutrinotion.nutrinotion_backend.model.User;
import com.nutrinotion.nutrinotion_backend.model.UserProfile;
import com.nutrinotion.nutrinotion_backend.repo.UserProfileRepo;
import com.nutrinotion.nutrinotion_backend.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepo userRepo;

    @Autowired
    private UserProfileRepo userProfileRepo;

    @PutMapping("/{id}/onboarding-complete")
    public AuthResponse completeOnboarding(@PathVariable Long id) {
        User user = userRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));

        UserProfile profile = userProfileRepo.findByUser_Id(id)
                .orElseThrow(() -> new RuntimeException("Profile not found for userId: " + id));

        profile.setOnboardingCompleted(true);
        userProfileRepo.save(profile);

        return new AuthResponse(
                user.getId(),
                user.getEmail(),
                profile.getName(),
                profile.isOnboardingCompleted()
        );
    }
}