package com.nutrinotion.nutrinotion_backend.repo;

import com.nutrinotion.nutrinotion_backend.model.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserProfileRepo extends JpaRepository<UserProfile, Long> {

    Optional<UserProfile> findByUser_Id(Long userId);
}

