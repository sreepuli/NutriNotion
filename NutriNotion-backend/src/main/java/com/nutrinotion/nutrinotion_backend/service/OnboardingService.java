package com.nutrinotion.nutrinotion_backend.service;

import com.nutrinotion.nutrinotion_backend.dto.OnboardingRequest;
import com.nutrinotion.nutrinotion_backend.dto.OnboardingResponse;
import com.nutrinotion.nutrinotion_backend.model.User;
import com.nutrinotion.nutrinotion_backend.model.UserProfile;
import com.nutrinotion.nutrinotion_backend.repo.UserProfileRepo;
import com.nutrinotion.nutrinotion_backend.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class OnboardingService {

    @Autowired
    private UserRepo userRepo;

    @Autowired
    private UserProfileRepo userProfileRepo;

    // ── helpers ───────────────────────────────────────────────────────────────
    private String listToString(List<String> list) {
        if (list == null || list.isEmpty()) return null;
        return list.stream().map(String::trim).collect(Collectors.joining(","));
    }

    private List<String> stringToList(String value) {
        if (value == null || value.isBlank()) return Collections.emptyList();
        return Arrays.stream(value.split(",")).map(String::trim).collect(Collectors.toList());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PUT /api/onboarding/{userId}
    // ─────────────────────────────────────────────────────────────────────────
    @Transactional
    public OnboardingResponse saveOnboarding(Long userId, OnboardingRequest req) {


        // ── 1. Validate required fields ───────────────────────────────────────
        if (req.getAge() == null || req.getHeightCm() == null || req.getWeightKg() == null) {
            throw new IllegalArgumentException("age, heightCm and weightKg are required.");
        }
        if (req.getGender() == null || req.getGender().isBlank()) {
            throw new IllegalArgumentException("gender is required.");
        }
        if (req.getActivityLevel() == null || req.getActivityLevel().isBlank()) {
            throw new IllegalArgumentException("activityLevel is required.");
        }
        if (req.getGoal() == null || req.getGoal().isBlank()) {
            throw new IllegalArgumentException("goal is required.");
        }

        // ── 2. Load the User (auth record must exist) ─────────────────────────
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        // ── 3. Load or create UserProfile ────────────────────────────────────
        // findByUser_Id returns the existing profile row — guaranteed UPDATE, never INSERT
        UserProfile profile = userProfileRepo.findByUser_Id(userId)
                .orElseGet(() -> {
                    UserProfile p = new UserProfile();
                    p.setUser(user);
                    return p;
                });

        // ── 4. Map request fields onto profile ───────────────────────────────
        if (req.getName() != null && !req.getName().isBlank()) {
            profile.setName(req.getName());
        }
        profile.setAge(req.getAge());
        profile.setGender(req.getGender());
        profile.setHeightCm(req.getHeightCm());
        profile.setWeightKg(req.getWeightKg());
        profile.setActivityLevel(req.getActivityLevel());
        profile.setGoal(req.getGoal());
        profile.setDietaryPreferences(req.getDietaryPreferences());
        // List<String> → comma-separated String for storage
        profile.setAllergies(listToString(req.getAllergies()));
        profile.setDislikedFoods(listToString(req.getDislikedFoods()));

        // ── 5. Calculate BMR (Mifflin-St Jeor) ───────────────────────────────
        double bmr;
        if ("female".equalsIgnoreCase(req.getGender())) {
            bmr = (10 * req.getWeightKg()) + (6.25 * req.getHeightCm()) - (5 * req.getAge()) - 161;
        } else {
            bmr = (10 * req.getWeightKg()) + (6.25 * req.getHeightCm()) - (5 * req.getAge()) + 5;
        }

        // ── 6. Activity multiplier ────────────────────────────────────────────
        double activityMultiplier = switch (req.getActivityLevel().trim().toLowerCase()) {
            case "lightly active" -> 1.375;
            case "active"         -> 1.55;
            case "very active"    -> 1.725;
            default               -> 1.2;  // Sedentary
        };
        double tdee = bmr * activityMultiplier;

        // ── 7. Goal adjustment ────────────────────────────────────────────────
        double calories = switch (req.getGoal().trim().toLowerCase()) {
            case "lose weight"  -> tdee - 500;
            case "gain muscle"  -> tdee + 300;
            default             -> tdee;   // Maintain Weight
        };
        int dailyCalories = (int) Math.round(calories);

        // ── 8. Macro split: 30% protein | 40% carbs | 30% fat ────────────────
        double proteinGrams = Math.round((dailyCalories * 0.30) / 4.0 * 10) / 10.0;
        double carbsGrams   = Math.round((dailyCalories * 0.40) / 4.0 * 10) / 10.0;
        double fatGrams     = Math.round((dailyCalories * 0.30) / 9.0 * 10) / 10.0;

        profile.setDailyCalorieTarget(dailyCalories);
        profile.setDailyProteinGrams(proteinGrams);
        profile.setDailyCarbsGrams(carbsGrams);
        profile.setDailyFatGrams(fatGrams);
        profile.setOnboardingCompleted(true);

        // ── 9. Save profile (UPDATE if exists, INSERT only on very first time) ─
        UserProfile saved = userProfileRepo.save(profile);
        return toResponse(user, saved);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET /api/onboarding/{userId}
    // ─────────────────────────────────────────────────────────────────────────
    public OnboardingResponse getOnboarding(Long userId) {
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        UserProfile profile = userProfileRepo.findByUser_Id(userId)
                .orElseThrow(() -> new RuntimeException("Profile not found for userId: " + userId));
        return toResponse(user, profile);
    }

    // ─────────────────────────────────────────────────────────────────────────
    private OnboardingResponse toResponse(User user, UserProfile p) {
        return new OnboardingResponse(
                user.getId(),
                p.getName(),
                user.getEmail(),
                p.getAge(),
                p.getGender(),
                p.getHeightCm(),
                p.getWeightKg(),
                p.getActivityLevel(),
                p.getGoal(),
                p.getDietaryPreferences(),
                stringToList(p.getAllergies()),
                stringToList(p.getDislikedFoods()),
                p.getDailyCalorieTarget(),
                p.getDailyProteinGrams(),
                p.getDailyCarbsGrams(),
                p.getDailyFatGrams(),
                p.isOnboardingCompleted()
        );
    }
}
