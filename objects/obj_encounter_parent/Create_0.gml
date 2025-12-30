// obj_encounter_parent — Create (na samym początku)

// Domyślne wartości jeśli nie zdefiniowane
if (!variable_instance_exists(id, "typ")) typ = "";
if (!variable_instance_exists(id, "zasieg")) zasieg = 0;
if (!variable_instance_exists(id, "sila_bonus")) sila_bonus = 0;
if (!variable_instance_exists(id, "efekt")) efekt = "";
if (!variable_instance_exists(id, "activation_days")) activation_days = 3;
if (!variable_instance_exists(id, "wsm_bonus")) wsm_bonus = 3.0;
if (!variable_instance_exists(id, "global_fear_bonus")) global_fear_bonus = 1.0;

encounter_data = {
    // Istniejące pola
    typ: (typ != "") ? typ : "kapliczka",
    zasieg: (zasieg != 0) ? zasieg : 120,
    sila: 1.0 + sila_bonus,
    poziom: 1,
    efekt: (efekt != "") ? efekt : "strach",
    rzadkosc: 50,
    akumulacja_strachu: 0,

    // Nowe pola - system aktywności
    active: true,                           // czy encounter jest aktywny
    activation_days: activation_days,       // ile dni pozostaje aktywny po wizycie
    days_remaining: activation_days,        // ile dni zostało do dezaktywacji
    last_activated_day: 0,                  // dzień ostatniej aktywacji

    // Nowe pola - bonusy dla systemu populacji
    wsm_bonus: wsm_bonus,                   // bonus do Wiary w Stare Mity
    fear_bonus: global_fear_bonus,          // bonus do Strachu Zbiorowego
    global_fear_bonus: global_fear_bonus,   // (legacy) bonus do global.global_fear
    madness_bonus: 0,                       // bonus do Szaleństwa (zazwyczaj 0)

    // Nowe pola - żywotność encountera
    max_inactive_days: 8,                   // ile dni bez odwiedzin zanim osłabnie
    days_inactive: 0,                       // licznik dni bez odwiedzin
    last_visited_by: noone,                 // kto ostatnio odwiedził

    // Nowe pola - zasięg i aktywność
    effective_radius: (zasieg != 0) ? zasieg : 120, // zasięg działania
    active_phases: ["evening", "night"],    // kiedy działa

    // Nowe pola - traits dla NPC
    traits: [],                             // array cech do nadania odwiedzającym NPC

    // Nowe pola - sprite'y (opcjonalne)
    sprite_idle: noone,                     // sprite dla nieaktywnego encountera
    sprite_active: noone                    // sprite dla aktywnego encountera
};

ds_list_add(global.encounters, id);