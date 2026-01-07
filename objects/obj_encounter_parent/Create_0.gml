// obj_encounter_parent — Create (na samym początku)

// Domyślne wartości jeśli nie zdefiniowane
if (!variable_instance_exists(id, "typ")) typ = "";
if (!variable_instance_exists(id, "zasieg")) zasieg = 0;
if (!variable_instance_exists(id, "sila_bonus")) sila_bonus = 0;
if (!variable_instance_exists(id, "efekt")) efekt = "";
if (!variable_instance_exists(id, "activation_days")) activation_days = 3;
if (!variable_instance_exists(id, "wsm_bonus")) wsm_bonus = 1;      // WwSM - współczynnik (legacy: wsm_bonus)
if (!variable_instance_exists(id, "ofiara_bonus")) ofiara_bonus = 1; // Ofiara - waluta
if (!variable_instance_exists(id, "global_fear_bonus")) global_fear_bonus = 1;

encounter_data = {
    // === LEGACY POLA (zachowane dla kompatybilności) ===
    typ: (typ != "") ? typ : "kapliczka",
    sila: 1.0 + sila_bonus,
    poziom: 1,
    efekt: (efekt != "") ? efekt : "strach",
    rzadkosc: 50,
    akumulacja_strachu: 0,

    // === UJEDNOLICONY SYSTEM MIEJSC ===
    place_type: "encounter",                // typ miejsca
    location_type: (typ != "") ? typ : "kapliczka", // podtyp lokacji
    zasieg: (zasieg != 0) ? zasieg : 120,   // zasięg aktywacji

    // === BAZOWE EFEKTY (gdy encounter AKTYWNY, bez trait) ===
    // Encounter to "statyczny trait" - sam w sobie jest jak trait
    base_effects: {
        strach: global_fear_bonus,          // +1 Strach (domyślnie)
        ofiara: ofiara_bonus,               // +1 Ofiara - waluta (domyślnie)
        wwsm: wsm_bonus                     // +1 WwSM - współczynnik (domyślnie)
    },

    // === SYSTEM AKTYWNOŚCI ENCOUNTERA ===
    // Encounter sam w sobie jest "aktywowany" - to jego główna mechanika
    active: true,
    activation_days: activation_days,       // ile dni pozostaje aktywny (domyślnie 3)
    days_remaining: activation_days,
    last_activated_day: 0,

    // === SYSTEM TRAITS (opcjonalne - encounter może mieć dodatkowy trait) ===
    trait_slots: 1,
    traits: ds_list_create(),               // zmienione z [] na ds_list dla spójności
    active_trait: noone,
    trait_days_remaining: 0,
    trait_last_activated_day: -1,

    // === POLA LEGACY (dla kompatybilności wstecznej) ===
    wsm_bonus: wsm_bonus,           // WwSM - współczynnik
    ofiara_bonus: ofiara_bonus,     // Ofiara - waluta
    fear_bonus: global_fear_bonus,
    global_fear_bonus: global_fear_bonus,
    madness_bonus: 0,
    max_inactive_days: 8,
    days_inactive: 0,
    last_visited_by: noone,
    effective_radius: (zasieg != 0) ? zasieg : 120,
    active_phases: ["evening", "night"],
    npc_traits: [],                         // przemianowane z traits
    sprite_idle: noone,
    sprite_active: noone
};

ds_list_add(global.encounters, id);