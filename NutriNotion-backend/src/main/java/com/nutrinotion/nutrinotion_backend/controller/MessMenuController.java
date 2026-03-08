package com.nutrinotion.nutrinotion_backend.controller;

import com.nutrinotion.nutrinotion_backend.model.MessMenu;
import com.nutrinotion.nutrinotion_backend.repo.MessMenuRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/menu")
@CrossOrigin(origins = "*")
public class MessMenuController {

    @Autowired
    private MessMenuRepo messMenuRepo;

    /**
     * GET /api/menu/{day}
     * Flutter calls this with e.g. "monday", "tuesday" — case-insensitive.
     */
    @GetMapping("/{day}")
    public ResponseEntity<MessMenu> getMenuByDay(@PathVariable String day) {
        MessMenu menu = messMenuRepo.findByDayOfWeekIgnoreCase(day)
                .orElseThrow(() -> new RuntimeException("Menu not found for day: " + day));
        return ResponseEntity.ok(menu);
    }

    /**
     * GET /api/menu
     * Returns all 7 days — useful for a weekly overview in Flutter.
     */
    @GetMapping
    public ResponseEntity<List<MessMenu>> getAllMenus() {
        return ResponseEntity.ok(messMenuRepo.findAll());
    }
}

