// Dane zasobu (ujednolicony system miejsc)
resource_data = {
    typ: "drewno",
    wartosc: 1,
    czas_pracy: room_speed * 2,
    ilosc: 3,

    // === UJEDNOLICONY SYSTEM MIEJSC ===
    place_type: "source",        // typ miejsca
    location_type: "resource",   // podtyp lokacji
    zasieg: 60,                  // zasięg aktywacji

    // === BAZOWE EFEKTY (gdy brak aktywnych traits) ===
    base_effects: {
        strach: 0,               // neutralne
        ofiara: 0,               // neutralne
        wwsm: -1                 // praca odejmuje WwSM (Wiarę w Stare Mity)
    },

    // === SYSTEM TRAITS ===
    trait_slots: 1,              // źródła mają mniej slotów
    traits: ds_list_create(),
    active_trait: noone,
    trait_days_remaining: 0,
    trait_last_activated_day: -1
};

x = x; y = y; // posiadanie x,y
ds_list_add(global.resources, id);
depth = -y;
