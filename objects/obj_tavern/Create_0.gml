/// obj_tavern - Create Event

// Zarejestruj w globalnej liście karczm
scr_tavern_register(self);

// Punkt nawigacyjny
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = 0;
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 65;
}

// Dane karczmy (ujednolicony system miejsc)
tavern_data = {
    nazwa: "Karczma",
    pojemnosc: 10,

    // === UJEDNOLICONY SYSTEM MIEJSC ===
    place_type: "tavern",        // typ miejsca
    location_type: "karczma",    // podtyp lokacji
    zasieg: 100,                 // zasięg aktywacji

    // === BAZOWE EFEKTY (gdy brak aktywnych traits) ===
    // Karczma jest neutralna - reaguje tylko na gracza
    base_effects: {
        strach: 0,               // neutralne
        ofiara: 0                // neutralne (gracz aktywuje osobno)
    },

    // === SYSTEM TRAITS ===
    trait_slots: 2,
    traits: ds_list_create(),
    active_trait: noone,
    trait_days_remaining: 0,
    trait_last_activated_day: -1
};

show_debug_message("obj_tavern utworzony: " + string(id));