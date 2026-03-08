package com.nutrinotion.nutrinotion_backend.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Stores one AI-generated personalized meal plan per user per date.
 * Unique constraint on (user_id, meal_date) prevents duplicates.
 */
@Entity
@Data
@Table(
    name = "personalized_meals",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "meal_date"})
)
public class PersonalizedMeal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "meal_date", nullable = false)
    private LocalDate mealDate;

    /** Day name stored for reference — e.g. "Monday" */
    @Column(name = "day_of_week", length = 20)
    private String dayOfWeek;

    // ── Recommended meals (only from today's mess menu) ──────────────────────
    @Column(length = 2000)
    private String breakfast;

    @Column(length = 2000)
    private String lunch;

    @Column(length = 2000)
    private String snacks;

    @Column(length = 2000)
    private String dinner;

    // ── Estimated nutrition for the day ──────────────────────────────────────
    @Column(name = "estimated_calories")
    private Integer estimatedCalories;

    @Column(name = "estimated_protein_grams")
    private Double estimatedProteinGrams;

    @Column(name = "estimated_carbs_grams")
    private Double estimatedCarbsGrams;

    @Column(name = "estimated_fat_grams")
    private Double estimatedFatGrams;

    /** Free-text tip from the AI for this user's goal */
    @Column(name = "nutrition_tip", length = 1000)
    private String nutritionTip;

    @CreationTimestamp
    @Column(name = "generated_at", updatable = false)
    private LocalDateTime generatedAt;
}

