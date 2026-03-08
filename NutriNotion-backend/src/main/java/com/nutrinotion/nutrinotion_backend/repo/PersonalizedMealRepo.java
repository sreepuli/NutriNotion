package com.nutrinotion.nutrinotion_backend.repo;

import com.nutrinotion.nutrinotion_backend.model.PersonalizedMeal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface PersonalizedMealRepo extends JpaRepository<PersonalizedMeal, Long> {

    /** Returns the cached plan for a user on a specific date — prevents duplicate generation */
    Optional<PersonalizedMeal> findByUser_IdAndMealDate(Long userId, LocalDate mealDate);
}

