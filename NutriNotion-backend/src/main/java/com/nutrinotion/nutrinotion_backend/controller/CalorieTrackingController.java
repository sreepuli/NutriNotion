package com.nutrinotion.nutrinotion_backend.controller;

import com.nutrinotion.nutrinotion_backend.service.CalorieTrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/calories")
@CrossOrigin(origins = "*")
public class CalorieTrackingController {

    @Autowired
    private CalorieTrackingService calorieTrackingService;

    /**
     * GET /api/calories/{userId}/today
     * Returns consumedCalories, targetCalories, remainingCalories for today.
     */
    @GetMapping("/{userId}/today")
    public ResponseEntity<?> getTodaySummary(@PathVariable Long userId) {
        try {
            return ResponseEntity.ok(calorieTrackingService.getSummary(userId));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(e.getMessage());
        }
    }
}

