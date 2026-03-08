package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OnboardingResponse {
    private Long userId;
    private String name;
    private String email;
    private Integer age;
    private String gender;
    private Double heightCm;
    private Double weightKg;
    private String activityLevel;
    private String goal;
    private String dietaryPreferences;
    private List<String> allergies;
    private List<String> dislikedFoods;
    private Integer dailyCalorieTarget;
    private Double dailyProteinGrams;
    private Double dailyCarbsGrams;
    private Double dailyFatGrams;
    private boolean onboardingCompleted;
}
