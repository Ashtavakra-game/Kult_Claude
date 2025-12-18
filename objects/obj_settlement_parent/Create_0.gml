/// CREATE EVENT - obj_settlement_parent

// =============================================================================
// PUNKTY NAWIGACYJNE - NAJPIERW! (żeby dzieci mogły nadpisać po event_inherited)
// =============================================================================
// Sprawdź czy dziecko już nie ustawiło (przez Variable Definitions w edytorze)
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = 0;
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 60;  // domyślnie pod budynkiem
}

// =============================================================================
// SPRITY - z wartościami domyślnymi, dzieci nadpisują PO event_inherited()
// =============================================================================
if (!variable_instance_exists(id, "settlement_sprite_empty")) {
    settlement_sprite_empty = spr_hut_empty;
}
if (!variable_instance_exists(id, "settlement_sprite_occupied")) {
    settlement_sprite_occupied = spr_hut_occupied;
}

// =============================================================================
// DANE OSADY
// =============================================================================
settlement_data = {
    residents: ds_list_create(),
    max_residents: 4,
    resources: ds_map_create(),
    population: 0,
    name: "Osada"
};

// Ustaw początkowy sprite
sprite_index = settlement_sprite_empty;

// =============================================================================
// REJESTRACJA W GLOBALNEJ LIŚCIE
// =============================================================================
if (!is_undefined(global.settlements)) {
    ds_list_add(global.settlements, id);
}

show_debug_message("Settlement utworzony: " + string(id) + 
    " sprite_empty=" + sprite_get_name(settlement_sprite_empty) +
    " sprite_occupied=" + sprite_get_name(settlement_sprite_occupied));
