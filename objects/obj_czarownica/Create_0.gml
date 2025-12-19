/// obj_czarownica - Create Event

// WAŻNE: Najpierw wywołaj event rodzica!
event_inherited();

// Teraz możesz nadpisać wartości
// encounter_data już istnieje dzięki event_inherited()

if (variable_instance_exists(id, "encounter_data")) {
    // Nadpisz tylko jeśli wartości są ustawione w Room Editor
    if (variable_instance_exists(id, "zasieg") && zasieg != 0) {
        encounter_data.zasieg = zasieg;
    }
    if (variable_instance_exists(id, "sila_bonus") && sila_bonus != 0) {
        encounter_data.sila += sila_bonus;
    }
    if (variable_instance_exists(id, "efekt") && efekt != "") {
        encounter_data.efekt = efekt;
    }
    if (variable_instance_exists(id, "typ") && typ != "") {
        encounter_data.typ = typ;
    }
} else {
    show_debug_message("ERROR: obj_czarownica - encounter_data nie zostało utworzone przez rodzica!");
}

// Ustaw nav_offset
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = 30;
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 45;
}