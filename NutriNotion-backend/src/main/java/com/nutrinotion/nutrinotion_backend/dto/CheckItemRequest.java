package com.nutrinotion.nutrinotion_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Request body for PUT /api/personalized-meals/item/{id}/check */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class CheckItemRequest {
    private boolean checked;
}

