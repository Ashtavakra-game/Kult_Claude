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
/// CREATE EVENT - obj_settlement_parent (ROZSZERZONA WERSJA)

// Podstawowe dane settlement
settlement_data = {
    name: "Settlement",
    population: 0,
    max_population: 10,
    max_residents: 10,
    npc_object: npc_parent,
    npc_kinds: "mezczyzna",
    residents: ds_list_create(),
    resources: ds_map_create(),
    
    // === NOWE: SYSTEM CECH ===
    trait_slots: 2,              // domyślnie 2 sloty na cechy
    traits: ds_list_create(),    // lista aktywnych cech
    trait_resistance: 0,         // odporność na nadawanie (0-100)
    location_type: "chata",      // typ lokacji (do walidacji cech)
    local_faith: 50,             // lokalna wiara (0-100)
    accumulated_fear: 0          // akumulowany strach lokalny
};

// Sprite'y
settlement_sprite_empty = spr_hut_empty;
settlement_sprite_occupied = spr_hut_occupied;
sprite_index = settlement_sprite_empty;

// Rejestracja w globalnej liście
ds_list_add(global.settlements, id);