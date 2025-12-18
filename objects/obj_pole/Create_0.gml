event_inherited();

// Create event obj_encounter_parent

// Ustaw domyślne wartości TYLKO jeśli nie istnieją
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = -65;  // domyślna wartość
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 55;  // domyślna wartość
}

// re