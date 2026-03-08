package com.nutrinotion.nutrinotion_backend.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

/**
 * Maps directly to the structured JSON object that Gemini is instructed to return.
 * Each meal type is now a list of items rather than a plain string.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiMealResponse {

    private List<AiMealItem> breakfast;
    private List<AiMealItem> lunch;
    private List<AiMealItem> snacks;
    private List<AiMealItem> dinner;
    private Integer totalCalories;
    private String nutritionTip;

    /** A single food item inside an AI-generated meal. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AiMealItem {
        private String foodName;
        private String quantity;
        private Integer calories;
    }
}
