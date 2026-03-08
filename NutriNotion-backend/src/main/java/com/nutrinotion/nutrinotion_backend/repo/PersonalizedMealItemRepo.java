package com.nutrinotion.nutrinotion_backend.repo;

import com.nutrinotion.nutrinotion_backend.model.PersonalizedMealItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface PersonalizedMealItemRepo extends JpaRepository<PersonalizedMealItem, Long> {

    /** All items for a user on a specific date — used to build the daily meal plan response. */
    List<PersonalizedMealItem> findByUser_IdAndMealDate(Long userId, LocalDate mealDate);

    /** Check if items already exist for today — prevents duplicate AI calls. */
    boolean existsByUser_IdAndMealDate(Long userId, LocalDate mealDate);

    /** All items for a user+date+mealType — used for grouped UI display. */
    List<PersonalizedMealItem> findByUser_IdAndMealDateAndMealType(
            Long userId, LocalDate mealDate, String mealType);
}

