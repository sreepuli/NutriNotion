package com.nutrinotion.nutrinotion_backend.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

/**
 * Tracks how many calories the user has consumed on a given day,
 * updated incrementally as meal items are checked/unchecked.
 */
@Entity
@Data
@Table(
    name = "daily_calorie_tracking",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "date"})
)
public class DailyCalorieTracking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDate date;

    /**
     * Running total of calories from all checked meal items today.
     * Updated by the check/uncheck endpoint.
     */
    @Column(name = "consumed_calories", nullable = false)
    private int consumedCalories = 0;

    /**
     * Copied from UserProfile.dailyCalorieTarget at the time of first generation
     * so the dashboard can display the target even if the profile changes later.
     */
    @Column(name = "target_calories", nullable = false)
    private int targetCalories = 2000;
}

