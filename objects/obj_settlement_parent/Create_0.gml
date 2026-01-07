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

    // === UJEDNOLICONY SYSTEM MIEJSC ===
    place_type: "settlement",    // typ miejsca (settlement/encounter/source/tavern)
    location_type: "chata",      // podtyp lokacji
    zasieg: 80,                  // zasięg aktywacji (jak encounter)

    // === BAZOWE EFEKTY (gdy brak aktywnych traits) ===
    base_effects: {
        strach: -1,              // settlement domyślnie: -1 Strach
        ofiara: 0                // brak wpływu na Ofiarę
    },

    // === SYSTEM TRAITS ===
    trait_slots: 2,              // domyślnie 2 sloty na cechy
    traits: ds_list_create(),    // lista nadanych cech (definicje)
    active_trait: noone,         // aktualnie aktywny trait (po odwiedzeniu)
    trait_days_remaining: 0,     // ile dni pozostało aktywności traitu
    trait_last_activated_day: -1 // dzień ostatniej aktywacji
};

// Sprite'y
settlement_sprite_empty = spr_hut_empty;
settlement_sprite_occupied = spr_hut_occupied;
sprite_index = settlement_sprite_empty;

// Rejestracja w globalnej liście
ds_list_add(global.settlements, id);