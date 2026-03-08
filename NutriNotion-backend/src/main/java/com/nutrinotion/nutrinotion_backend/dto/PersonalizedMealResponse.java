package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Returned to the Flutter frontend for both generate and fetch endpoints.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class PersonalizedMealResponse {

    private Long id;
    private Long userId;
    private LocalDate mealDate;
    private String dayOfWeek;

    private String breakfast;
    private String lunch;
    private String snacks;
    private String dinner;

    private Integer estimatedCalories;
    private Double estimatedProteinGrams;
    private Double estimatedCarbsGrams;
    private Double estimatedFatGrams;
    private String nutritionTip;
}

