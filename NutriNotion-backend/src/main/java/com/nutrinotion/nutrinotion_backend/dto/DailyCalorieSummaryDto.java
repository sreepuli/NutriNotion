package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** Returned by GET /api/calories/{userId}/today */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class DailyCalorieSummaryDto {
    private Long userId;
    private LocalDate date;
    private int consumedCalories;
    private int targetCalories;
    private int remainingCalories;
}

