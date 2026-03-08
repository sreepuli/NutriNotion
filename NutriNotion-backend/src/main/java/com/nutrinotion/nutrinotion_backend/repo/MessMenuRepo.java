package com.nutrinotion.nutrinotion_backend.repo;

import com.nutrinotion.nutrinotion_backend.model.MessMenu;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MessMenuRepo extends JpaRepository<MessMenu, Long> {

    Optional<MessMenu> findByDayOfWeekIgnoreCase(String dayOfWeek);
}

