depth = -y;

// === ZMIANA SPRITE NA PODSTAWIE AKTYWNOŚCI ===
if (variable_instance_exists(id, "encounter_data")) {
    var ed = encounter_data;

    // Jeśli encounter ma zdefiniowane sprite'y dla stanów
    if (ed.active) {
        // Aktywny - użyj sprite_active jeśli zdefiniowany
        if (ed.sprite_active != noone) {
            sprite_index = ed.sprite_active;
        }
    } else {
        // Nieaktywny - użyj sprite_idle jeśli zdefiniowany
        if (ed.sprite_idle != noone) {
            sprite_index = ed.sprite_idle;
        }
    }
}