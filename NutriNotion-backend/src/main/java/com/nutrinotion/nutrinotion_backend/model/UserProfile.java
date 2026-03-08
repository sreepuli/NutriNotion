package com.nutrinotion.nutrinotion_backend.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "user_profiles")
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Owning side — holds the FK column user_id in user_profiles table
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    private String name;

    private Integer age;

    private String gender;           // "Male" | "Female" | "Other"

    @Column(name = "height_cm")
    private Double heightCm;

    @Column(name = "weight_kg")
    private Double weightKg;

    @Column(name = "activity_level")
    private String activityLevel;    // "Sedentary" | "Lightly Active" | "Active" | "Very Active"

    private String goal;             // "Lose Weight" | "Maintain Weight" | "Gain Muscle"

    // "Vegetarian" | "Non-Vegetarian" | "Vegan"
    @Column(name = "dietary_preferences", length = 500)
    private String dietaryPreferences;

    // Comma-separated — stored in a single column, no extra join tables
    @Column(length = 500)
    private String allergies;        // e.g. "Nuts,Dairy"

    @Column(name = "disliked_foods", length = 500)
    private String dislikedFoods;    // e.g. "Broccoli,Spinach"

    // ── Calculated nutrition targets ─────────────────────────────────────────
    @Column(name = "daily_calorie_target")
    private Integer dailyCalorieTarget;

    @Column(name = "daily_protein_grams")
    private Double dailyProteinGrams;

    @Column(name = "daily_carbs_grams")
    private Double dailyCarbsGrams;

    @Column(name = "daily_fat_grams")
    private Double dailyFatGrams;

    @Column(name = "onboarding_completed", nullable = false)
    private boolean onboardingCompleted = false;
}

