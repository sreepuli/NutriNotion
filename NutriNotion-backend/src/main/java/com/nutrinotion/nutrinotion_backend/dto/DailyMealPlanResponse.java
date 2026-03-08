package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/**
 * Full daily meal plan returned to Flutter.
 * Replaces the old flat PersonalizedMealResponse.
 * Items are grouped by mealType for easy display.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class DailyMealPlanResponse {

    private Long userId;
    private LocalDate mealDate;
    private String dayOfWeek;

    private List<MealItemDto> breakfast;
    private List<MealItemDto> lunch;
    private List<MealItemDto> snacks;
    private List<MealItemDto> dinner;

    /** Sum of all item calories for the day (target from onboarding). */
    private int totalSuggestedCalories;
    private int targetCalories;

    private String nutritionTip;
}

