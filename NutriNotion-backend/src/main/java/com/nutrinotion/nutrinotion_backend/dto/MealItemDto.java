package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a single meal item returned to Flutter.
 * Maps 1:1 to a PersonalizedMealItem row.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class MealItemDto {
    private Long id;
    private String foodName;
    private String quantity;
    private Integer calories;
    private String mealType;
    private boolean isChecked;
}

