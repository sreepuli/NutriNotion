package com.nutrinotion.nutrinotion_backend.service;

import com.nutrinotion.nutrinotion_backend.dto.DailyCalorieSummaryDto;
import com.nutrinotion.nutrinotion_backend.model.DailyCalorieTracking;
import com.nutrinotion.nutrinotion_backend.model.User;
import com.nutrinotion.nutrinotion_backend.repo.DailyCalorieTrackingRepo;
import com.nutrinotion.nutrinotion_backend.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
public class CalorieTrackingService {

    @Autowired private DailyCalorieTrackingRepo trackingRepo;
    @Autowired private UserRepo userRepo;

    /**
     * Returns or creates today's calorie tracking row for the user.
     * Called internally by DailyMealGenerationService after items are saved.
     */
    @Transactional
    public DailyCalorieTracking getOrCreate(Long userId, LocalDate date, int targetCalories) {
        return trackingRepo.findByUser_IdAndDate(userId, date)
                .orElseGet(() -> {
                    User user = userRepo.findById(userId)
                            .orElseThrow(() -> new RuntimeException("User not found: " + userId));
                    DailyCalorieTracking t = new DailyCalorieTracking();
                    t.setUser(user);
                    t.setDate(date);
                    t.setConsumedCalories(0);
                    t.setTargetCalories(targetCalories);
                    return trackingRepo.save(t);
                });
    }

    /**
     * Called when the user checks or unchecks a meal item.
     * delta = +calories when checking, -calories when unchecking.
     */
    @Transactional
    public DailyCalorieTracking applyDelta(Long userId, LocalDate date, int delta) {
        DailyCalorieTracking tracking = trackingRepo.findByUser_IdAndDate(userId, date)
                .orElseThrow(() -> new RuntimeException(
                        "No calorie tracking record for user " + userId + " on " + date
                        + ". Call generate-today first."));
        int updated = tracking.getConsumedCalories() + delta;
        tracking.setConsumedCalories(Math.max(0, updated)); // never go below 0
        return trackingRepo.save(tracking);
    }

    /**
     * GET /api/calories/{userId}/today
     */
    public DailyCalorieSummaryDto getSummary(Long userId) {
        LocalDate today = LocalDate.now();
        DailyCalorieTracking tracking = trackingRepo.findByUser_IdAndDate(userId, today)
                .orElseGet(() -> {
                    // Return zeros if nothing generated yet today
                    DailyCalorieTracking empty = new DailyCalorieTracking();
                    empty.setConsumedCalories(0);
                    empty.setTargetCalories(2000);
                    return empty;
                });
        int remaining = Math.max(0, tracking.getTargetCalories() - tracking.getConsumedCalories());
        return new DailyCalorieSummaryDto(
                userId,
                today,
                tracking.getConsumedCalories(),
                tracking.getTargetCalories(),
                remaining
        );
    }
}

