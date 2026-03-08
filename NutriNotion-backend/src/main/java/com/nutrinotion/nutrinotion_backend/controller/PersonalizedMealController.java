package com.nutrinotion.nutrinotion_backend.controller;

import com.nutrinotion.nutrinotion_backend.dto.CheckItemRequest;
import com.nutrinotion.nutrinotion_backend.service.DailyMealGenerationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/personalized-meals")
@CrossOrigin(origins = "*")
public class PersonalizedMealController {

    @Autowired
    private DailyMealGenerationService mealService;

    /**
     * POST /api/personalized-meals/{userId}/generate-today
     * Idempotent — returns cached plan if already generated today.
     */
    @PostMapping("/{userId}/generate-today")
    public ResponseEntity<?> generateToday(@PathVariable Long userId) {
        try {
            return ResponseEntity.ok(mealService.generateToday(userId));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(e.getMessage());
        }
    }

    /**
     * GET /api/personalized-meals/{userId}/today
     * Auto-generates via Gemini if no plan exists yet today.
     */
    @GetMapping("/{userId}/today")
    public ResponseEntity<?> getToday(@PathVariable Long userId) {
        try {
            return ResponseEntity.ok(mealService.getToday(userId));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(e.getMessage());
        }
    }

    /**
     * PUT /api/personalized-meals/item/{itemId}/check
     * Body: {"checked": true}
     * Toggles isChecked on the item and updates today's consumedCalories.
     */
    @PutMapping("/item/{itemId}/check")
    public ResponseEntity<?> checkItem(
            @PathVariable Long itemId,
            @RequestBody CheckItemRequest request) {
        try {
            return ResponseEntity.ok(mealService.toggleCheck(itemId, request.isChecked()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(e.getMessage());
        }
    }

    /**
     * GET /api/personalized-meals/gemini/models
     * Debug — lists all Gemini models available for this API key.
     */
    @GetMapping("/gemini/models")
    public ResponseEntity<?> listGeminiModels() {
        try {
            return ResponseEntity.ok(mealService.listSupportedModels());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(e.getMessage());
        }
    }
}
