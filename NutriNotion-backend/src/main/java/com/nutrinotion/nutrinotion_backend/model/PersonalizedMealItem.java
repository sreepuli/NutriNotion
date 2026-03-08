package com.nutrinotion.nutrinotion_backend.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

/**
 * One food item inside a daily personalized meal plan.
 * Rows are created when the AI generates today's plan.
 * isChecked is toggled by the user as they eat each item.
 */
@Entity
@Data
@Table(name = "personalized_meal_items")
public class PersonalizedMealItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "meal_date", nullable = false)
    private LocalDate mealDate;

    /**
     * "breakfast" | "lunch" | "snacks" | "dinner"
     */
    @Column(name = "meal_type", nullable = false, length = 20)
    private String mealType;

    @Column(name = "food_name", nullable = false, length = 500)
    private String foodName;

    /**
     * Human-readable quantity — e.g. "1 serving", "200g", "1 cup"
     */
    @Column(length = 100)
    private String quantity;

    /**
     * Estimated calories for this item/quantity.
     */
    private Integer calories;

    /**
     * Toggled by PUT /api/personalized-meals/item/{id}/check.
     * When set to true → calories are added to DailyCalorieTracking.
     * When set to false → calories are subtracted.
     */
    @Column(name = "is_checked", nullable = false)
    private boolean isChecked = false;
}

