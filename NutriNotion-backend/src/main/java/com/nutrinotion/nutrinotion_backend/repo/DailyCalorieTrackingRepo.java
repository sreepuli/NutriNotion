package com.nutrinotion.nutrinotion_backend.repo;

import com.nutrinotion.nutrinotion_backend.model.DailyCalorieTracking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface DailyCalorieTrackingRepo extends JpaRepository<DailyCalorieTracking, Long> {

    Optional<DailyCalorieTracking> findByUser_IdAndDate(Long userId, LocalDate date);
}

