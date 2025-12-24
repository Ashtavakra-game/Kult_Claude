/// =============================================================================
/// BORUTA - KATALOG CECH LOKACJI
/// =============================================================================
/// Definicje wszystkich cech możliwych do nadania lokacjom
/// =============================================================================

// =============================================================================
// INICJALIZACJA KATALOGU
// =============================================================================

/// scr_trait_catalog_init()
/// Tworzy katalog wszystkich dostępnych cech
function scr_trait_catalog_init() {
    
    // === NAWIEDZENIE ===
    ds_map_add(global.trait_catalog, "nawiedzenie", {
        name: "nawiedzenie",
        display_name: "Nawiedzenie",
        description: "Coś tu jest. Czuję to w kościach.",
        type: "dynamic",              // dynamic = nabywana, static = wrodzona
        base_cost: 2,                 // bazowy koszt EC
        valid_locations: ["all"],     // gdzie można nadać
        prerequisite: "",             // wymagana inna cecha
        
        // Efekty lokalne PLUS (korzyści dla gracza)
        local_fear_bonus: 15,
        encounter_strength_mult: 1.3,
        nightmare_chance: 0.20,
        
        // Efekty lokalne MINUS (koszty/ryzyka)
        productivity_mult: 0.85,
        flee_chance_base: 0.03,
        
        // Modyfikatory NPC (dodawane do location_mods)
        npc_mods: {
            pracowitosc: -15,
            roztargnienie: 25,
            ciekawosc: 10,
            podatnosc: 10,
            towarzyskosc: 0,
            wanderlust: 0
        },
        
        // Eskalacja poziomów [I, II, III, IV]
        level_scaling: {
            fear_bonus:        [15, 25, 40, 60],
            productivity_mult: [0.85, 0.70, 0.50, 0.30],
            flee_chance:       [0.03, 0.08, 0.15, 0.25]
        }
    });
    
    // === IZOLACJA ===
    ds_map_add(global.trait_catalog, "izolacja", {
        name: "izolacja",
        display_name: "Izolacja",
        description: "Nikt tam nie chodzi. Nikt stamtąd nie wraca.",
        type: "dynamic",
        base_cost: 3,
        valid_locations: ["chata", "las", "bagno"],
        prerequisite: "",
        
        // Efekty lokalne PLUS
        interaction_reduction: 0.50,  // -50% interakcji z innymi
        gossip_block: true,           // plotki nie docierają
        detection_reduction: 0.30,    // trudniej wykryć działania gracza
        
        // Efekty lokalne MINUS
        tavern_block: true,           // mieszkańcy nie chodzą do karczmy
        stress_regen_mult: 0.5,       // wolniejsza regeneracja stresu
        
        // Modyfikatory NPC
        npc_mods: {
            pracowitosc: 0,
            roztargnienie: 0,
            ciekawosc: 0,
            podatnosc: 20,
            towarzyskosc: -80,
            wanderlust: -30
        },
        
        // Synergia z Nawiedzeniem = PARANOJA
        synergy_with: "nawiedzenie",
        synergy_effect: "paranoja",
        synergy_mult: 1.5
    });
    
    // === PLUGAWE MIEJSCE ===
    ds_map_add(global.trait_catalog, "plugawe", {
        name: "plugawe",
        display_name: "Plugawe Miejsce",
        description: "Ziemia tam przeklęta. Nawet zboże gnije.",
        type: "dynamic",
        base_cost: 5,
        valid_locations: ["pole", "las", "resource"],
        prerequisite: "nawiedzenie",  // wymaga poziomu II Nawiedzenia
        prerequisite_level: 2,
        
        // Efekty lokalne PLUS
        ec_harvest_bonus: 0.50,       // +50% EC przy zbiorze
        encounter_strength_mult: 1.3,
        conversion_chance_bonus: 0.15,
        
        // Efekty lokalne MINUS
        resource_productivity_mult: 0.5,
        disease_chance: 0.10,         // szansa na chorobę przy pracy
        global_faith_drain: 2,        // -2 wiara globalna na noc
        
        // Modyfikatory NPC (podczas pracy w lokacji)
        npc_mods: {
            pracowitosc: -25,
            roztargnienie: 0,
            ciekawosc: 0,
            podatnosc: 30,
            towarzyskosc: 0,
            wanderlust: 0
        },
        
        // Dodatkowy stres za dzień pracy
        stress_per_work_day: 5
    });
    
    // === PLOTKARSKA AURA ===
    ds_map_add(global.trait_catalog, "plotkarska", {
        name: "plotkarska",
        display_name: "Plotkarska Aura",
        description: "Baby gadają, że tam diabeł mieszka...",
        type: "dynamic",
        base_cost: 2,
        valid_locations: ["karczma", "chata", "plac"],
        prerequisite: "",
        
        // Efekty lokalne PLUS
        gossip_speed_mult: 3.0,       // plotki 3x szybciej
        fear_spread: true,            // strach przenosi się do domów
        trait_visibility: true,       // cechy w okolicy są "publiczne"
        
        // Efekty lokalne MINUS
        priest_detection_bonus: 0.50, // +50% szans kapłana na wykrycie
        primary_suspect: true,        // pierwsza podejrzana lokacja
        positive_gossip: true,        // też pozytywne plotki (o cudach)
        
        // Modyfikatory NPC
        npc_mods: {
            pracowitosc: 0,
            roztargnienie: 5,
            ciekawosc: 15,
            podatnosc: 5,
            towarzyskosc: 20,
            wanderlust: 10
        },
        
        // Specjalny efekt na karczmie
        tavern_fear_transfer_chance: 0.30
    });
    
    // === ZAPOMNIANE MIEJSCE ===
    ds_map_add(global.trait_catalog, "zapomniane", {
        name: "zapomniane",
        display_name: "Zapomniane Miejsce",
        description: "Było tu coś kiedyś... ale nikt nie pamięta co.",
        type: "dynamic",  // może być też static dla ruin
        base_cost: 1,     // tanie, ale ryzykowne
        valid_locations: ["ruina", "cmentarz", "opuszczone"],
        prerequisite: "",
        
        // Efekty lokalne PLUS
        other_traits_cost_mult: 0.5,  // -50% koszt innych cech tu
        detection_reduction: 0.40,    // trudniejsze do wykrycia przez kapłana
        base_potential: true,         // idealne na bazę
        
        // Efekty lokalne MINUS
        mutation_chance: 0.20,        // 20% szans na mutację co tydzień
        curious_npc_attraction: true, // przyciąga ciekawskich
        effects_mult_inactive: 0.7,   // efekty słabsze przed aktywacją
        
        // Modyfikatory NPC
        npc_mods: {
            pracowitosc: 0,
            roztargnienie: 0,
            ciekawosc: 30,            // przyciąga ciekawych
            podatnosc: 15,
            towarzyskosc: -20,
            wanderlust: 20
        },
        
        // Aktywacja: 3 NPC w ciągu tygodnia
        activation_visitors_required: 3,
        activation_time_window: 7,     // dni
        activation_effect_mult: 1.5
    });
    
    // === POŚWIĘCONE MIEJSCE (defensywna - nie do nadania) ===
    ds_map_add(global.trait_catalog, "poswiecone", {
        name: "poswiecone",
        display_name: "Poświęcone Miejsce",
        description: "Tu diabeł nie ma wstępu. Matka Boska pilnuje.",
        type: "static",               // NIE może być nadana przez gracza
        base_cost: -1,                // -1 = nie do kupienia
        valid_locations: ["kapliczka", "kosciol"],
        prerequisite: "",
        
        // Efekty (przeciwne do cech gracza)
        blocks_slots: true,           // blokuje slot
        stress_regen_per_visit: 10,   // regeneracja stresu
        local_faith_bonus: 20,
        encounter_strength_mult: 0.5, // encountery gracza osłabione
        
        // Modyfikatory NPC (pozytywne)
        npc_mods: {
            pracowitosc: 5,
            roztargnienie: -10,
            ciekawosc: -5,
            podatnosc: -30,
            towarzyskosc: 10,
            wanderlust: 0
        },
        
        // Niszczenie (profanacja)
        profanation_cost: 50,         // EC
        profanation_nights: 5,        // konsekwentnych nocy
        profanation_result: "sprofanowane"
    });
    
    // === SPROFANOWANE MIEJSCE (wynik profanacji) ===
    ds_map_add(global.trait_catalog, "sprofanowane", {
        name: "sprofanowane",
        display_name: "Sprofanowane Miejsce",
        description: "Kiedyś święte. Teraz... coś innego tu mieszka.",
        type: "dynamic",
        base_cost: -1,                // tylko przez profanację
        valid_locations: [],          // nie do normalnego nadania
        prerequisite: "poswiecone",
        
        // Efekty lokalne PLUS (potężne)
        local_fear_bonus: 40,
        encounter_strength_mult: 2.0,
        ec_generation_passive: 3,     // pasywna generacja EC
        
        // Efekty lokalne MINUS (ryzykowne)
        global_faith_drain: 5,        // wysoki spadek wiary globalnej
        priest_attraction: true,      // przyciąga kapłana/egzorcystę
        community_reaction: true,     // społeczność reaguje
        
        // Modyfikatory NPC
        npc_mods: {
            pracowitosc: -30,
            roztargnienie: 40,
            ciekawosc: -20,           // ludzie unikają
            podatnosc: 40,
            towarzyskosc: -40,
            wanderlust: -20
        }
    });
    
    show_debug_message("=== TRAIT CATALOG INITIALIZED ===");
    show_debug_message("Available traits: " + string(ds_map_size(global.trait_catalog)));
}

// =============================================================================
// DOSTĘP DO KATALOGU
// =============================================================================

/// scr_trait_get_definition(trait_name)
/// Zwraca definicję cechy z katalogu
function scr_trait_get_definition(_trait_name) {
    if (ds_map_exists(global.trait_catalog, _trait_name)) {
        return ds_map_find_value(global.trait_catalog, _trait_name);
    }
    show_debug_message("WARNING: Trait '" + _trait_name + "' not found in catalog!");
    return undefined;
}

/// scr_trait_get_available_for_location(location_type)
/// Zwraca listę cech dostępnych dla danego typu lokacji
function scr_trait_get_available_for_location(_loc_type) {
    var result = [];
    var key = ds_map_find_first(global.trait_catalog);
    
    while (!is_undefined(key)) {
        var def = ds_map_find_value(global.trait_catalog, key);
        
        // Sprawdź czy cecha jest dynamiczna (do nadania)
        if (def.type == "dynamic" && def.base_cost > 0) {
            // Sprawdź czy lokacja jest dozwolona
            if (variable_struct_exists(def, "valid_locations")) {
                var valid = def.valid_locations;
                if (array_length(valid) > 0) {
                    if (valid[0] == "all" || array_contains(valid, _loc_type)) {
                        array_push(result, key);
                    }
                }
            } else {
                // Brak valid_locations = dozwolone wszędzie
                array_push(result, key);
            }
        }
        
        key = ds_map_find_next(global.trait_catalog, key);
    }
    
    return result;
}

/// scr_trait_check_prerequisite(trait_name, settlement_inst)
/// Sprawdza czy lokacja spełnia wymagania wstępne cechy
function scr_trait_check_prerequisite(_trait_name, _settlement) {
    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) return false;
    
    // Brak wymagań
    if (!variable_struct_exists(def, "prerequisite") || def.prerequisite == "") return true;
    
    // Sprawdź czy lokacja ma wymaganą cechę
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return false;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        if (trait.name == def.prerequisite) {
            // Sprawdź poziom jeśli wymagany
            if (variable_struct_exists(def, "prerequisite_level")) {
                if (trait.level >= def.prerequisite_level) {
                    return true;
                }
            } else {
                return true;
            }
        }
    }
    
    return false;
}

// =============================================================================
// HELPER - array_contains
// =============================================================================

/// array_contains(arr, value)
/// Sprawdza czy tablica zawiera wartość
function array_contains(_arr, _value) {
    for (var i = 0; i < array_length(_arr); i++) {
        if (_arr[i] == _value) return true;
    }
    return false;
}
