package com.nutrinotion.nutrinotion_backend.model;

import jakarta.persistence.*;
import lombok.Data;

/**
 * One row per day of the week stored in the mess_menu table.
 * dayOfWeek must match exactly: "Monday", "Tuesday", … "Sunday"
 */
@Entity
@Data
@Table(name = "mess_menu")
public class MessMenu {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** "Monday" | "Tuesday" | "Wednesday" | "Thursday" | "Friday" | "Saturday" | "Sunday" */
    @Column(name = "day_of_week", nullable = false, unique = true, length = 20)
    private String dayOfWeek;

    @Column(length = 1000)
    private String breakfast;

    @Column(length = 1000)
    private String lunch;

    @Column(length = 1000)
    private String snacks;

    @Column(length = 1000)
    private String dinner;
}

