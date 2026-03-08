package com.nutrinotion.nutrinotion_backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class OnboardingRequest {
    private String name;               // can update name during onboarding
    private Integer age;
    private String gender;             // "Male" | "Female" | "Other"
    private Double heightCm;
    private Double weightKg;
    private String activityLevel;      // "Sedentary" | "Lightly Active" | "Active" | "Very Active"
    private String goal;               // "Lose Weight" | "Maintain Weight" | "Gain Muscle"
    private String dietaryPreferences;
    private List<String> allergies;    // e.g. ["Nuts", "Dairy"]
    private List<String> dislikedFoods; // e.g. ["Broccoli", "Spinach"]
}
