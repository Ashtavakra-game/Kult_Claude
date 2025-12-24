/// =============================================================================
/// BORUTA - SYSTEM CECH LOKACJI
/// =============================================================================
/// Główny plik systemu cech lokacji
/// Wersja 1.0 - Kompatybilny z istniejącym kodem NPC i Settlement
/// =============================================================================

// =============================================================================
// FUNKCJE POMOCNICZE - BEZPIECZNY DOSTĘP DO STRUKTUR
// =============================================================================

/// scr_trait_safe_get_settlement_data(settlement_inst)
/// Bezpiecznie zwraca settlement_data lub undefined
function scr_trait_safe_get_settlement_data(_settlement) {
    if (!instance_exists(_settlement)) return undefined;
    if (!variable_instance_exists(_settlement, "settlement_data")) return undefined;
    return _settlement.settlement_data;
}

/// scr_trait_safe_get_traits(settlement_inst)
/// Bezpiecznie zwraca listę cech lub undefined
function scr_trait_safe_get_traits(_settlement) {
    var sd = scr_trait_safe_get_settlement_data(_settlement);
    if (is_undefined(sd)) return undefined;
    if (!variable_struct_exists(sd, "traits")) return undefined;
    var traits = sd.traits;
    if (is_undefined(traits)) return undefined;
    if (!ds_exists(traits, ds_type_list)) return undefined;
    return traits;
}

/// scr_trait_safe_get_residents(settlement_inst)
/// Bezpiecznie zwraca listę mieszkańców lub undefined
function scr_trait_safe_get_residents(_settlement) {
    var sd = scr_trait_safe_get_settlement_data(_settlement);
    if (is_undefined(sd)) return undefined;
    if (!variable_struct_exists(sd, "residents")) return undefined;
    var residents = sd.residents;
    if (is_undefined(residents)) return undefined;
    if (!ds_exists(residents, ds_type_list)) return undefined;
    return residents;
}

// =============================================================================
// INICJALIZACJA SYSTEMU (wywołaj w o_game Create)
// =============================================================================

/// scr_trait_system_init()
/// Inicjalizuje globalny system cech lokacji i Esencji Ciemności
function scr_trait_system_init() {
    

    // === WIARA W STARE MITY (główna waluta) ===
    global.myth_faith = 0;              // aktualna ilość
    global.myth_faith_max = 200;        // limit puli
    global.myth_faith_income = 0;       // dochód na dzień (obliczany dynamicznie)
    
    // === ESENCJA CIEMNOŚCI (waluta zaawansowana) ===
    // (już istnieje, ale zmień opis)
    global.dark_essence = 0;            // aktualna ilość
    global.dark_essence_max = 100;      // limit puli
    global.dark_essence_income = 0;     // dochód na noc
    
    // === KONFIGURACJA EKONOMII ===
    global.economy_config = {
        // Generowanie WSM
        wsm_per_population: 1.0,        // WSM na NPC na dzień
        wsm_per_encounter_visit: 0.5,   // WSM za odwiedziny encountera (raz na dzień per NPC)
        wsm_from_staying_late: 1,       // bonus za NPC zostającego w karczmie
        
        // Koszty w WSM
        trait_cost_currency: "wsm",     // waluta dla traits
        cyrograf_cost_currency: "wsm",  // waluta dla cyrografów
        cyrograf_base_cost_wsm: 8,      // koszt próby cyrografu w WSM
        
        // Koszty w EC (zaawansowane)
        escalation_level3_ec: 15,       // EC za eskalację do poziomu III
        escalation_level4_ec: 30,       // EC za eskalację do poziomu IV
        
        // Generowanie EC
        ec_per_cyrograf_success: 10,    // EC za udany cyrograf
        ec_per_slave_night: 2,          // EC za sługę na noc
        ec_per_sin: 5,                  // EC za grzech NPC
    };
    
    // === ŚLEDZENIE UŻYCIA CECH ===
    // Klucz: nazwa_cechy, Wartość: ile lokacji ma tę cechę
    global.trait_usage = ds_map_create();
    
    // === KATALOG CECH (definicje) ===
    global.trait_catalog = ds_map_create();
    scr_trait_catalog_init();
    
    // === KONFIGURACJA EKONOMII ===
    global.trait_config = {
        // Mnożnik kosztu geometrycznego (Koszt = Bazowy × 3^n)
        cost_multiplier: 3,
        
        // Źródła EC (wartości na tick/event)
        ec_per_fear_point: 0.1,        // EC za punkt akumulacji strachu
        ec_per_slave: 2.0,             // EC za cyrograf (na noc)
        ec_per_sin: 10.0,              // EC za grzech NPC (jednorazowo)
        ec_per_chaos: 5.0,             // EC za konflikt (jednorazowo)
        
        // Zanikanie cech
        base_decay_rate: 0.001,        // bazowe tempo zanikania
        faith_decay_bonus: 0.002,      // bonus zanikania od wiary
        
        // Eskalacja (ile nocy aktywności do awansu poziomu)
        escalation_nights: [3, 5, 7],  // I→II, II→III, III→IV
        escalation_costs: [0, 10, 25], // dodatkowy koszt EC
    };
    
	
	
    // === FLAGI SYSTEMOWE ===
    global.trait_system_active = true;
    
    show_debug_message("=== TRAIT SYSTEM INITIALIZED ===");
    show_debug_message("Dark Essence: " + string(global.dark_essence) + "/" + string(global.dark_essence_max));
}

// =============================================================================
// ESENCJA CIEMNOŚCI - ZARZĄDZANIE
// =============================================================================

/// scr_dark_essence_add(amount)
/// Dodaje Esencję Ciemności (z limitem max)
function scr_dark_essence_add(_amount) {
    global.dark_essence = min(global.dark_essence + _amount, global.dark_essence_max);
    return global.dark_essence;
}

/// scr_dark_essence_spend(amount)
/// Wydaje Esencję Ciemności. Zwraca true jeśli sukces, false jeśli brak środków.
function scr_dark_essence_spend(_amount) {
    if (global.dark_essence >= _amount) {
        global.dark_essence -= _amount;
        return true;
    }
    return false;
}

/// scr_dark_essence_can_afford(amount)
/// Sprawdza czy gracz stać na wydatek
function scr_dark_essence_can_afford(_amount) {
    return (global.dark_essence >= _amount);
}

/// scr_dark_essence_get()
/// Zwraca aktualną ilość EC
function scr_dark_essence_get() {
    return global.dark_essence;
}

/// scr_myth_faith_add(amount)
/// Dodaje Wiarę w Stare Mity (z limitem max)
function scr_myth_faith_add(_amount) {
    if (!variable_global_exists("myth_faith")) {
        global.myth_faith = 0;
        global.myth_faith_max = 200;
    }
    global.myth_faith = min(global.myth_faith + _amount, global.myth_faith_max);
    return global.myth_faith;
}

/// scr_myth_faith_spend(amount)
/// Wydaje Wiarę w Stare Mity. Zwraca true jeśli sukces.
function scr_myth_faith_spend(_amount) {
    if (!variable_global_exists("myth_faith")) return false;
    if (global.myth_faith >= _amount) {
        global.myth_faith -= _amount;
        return true;
    }
    return false;
}

/// scr_myth_faith_can_afford(amount)
/// Sprawdza czy gracza stać na wydatek w WSM
function scr_myth_faith_can_afford(_amount) {
    if (!variable_global_exists("myth_faith")) return false;
    return (global.myth_faith >= _amount);
}

/// scr_myth_faith_get()
/// Zwraca aktualną ilość WSM
function scr_myth_faith_get() {
    if (!variable_global_exists("myth_faith")) return 0;
    return global.myth_faith;
}

// =============================================================================
// KOSZTY CECH - SKALA GEOMETRYCZNA
// =============================================================================

/// scr_trait_get_cost(trait_name, base_cost)
/// Zwraca aktualny koszt nadania cechy (z uwzględnieniem geometrycznego wzrostu)
function scr_trait_get_cost(_trait_name, _base_cost) {
    var usage = 0;
    if (ds_map_exists(global.trait_usage, _trait_name)) {
        usage = ds_map_find_value(global.trait_usage, _trait_name);
    }
    
    // Koszt = Bazowy × 3^n (gdzie n = liczba istniejących użyć)
    return _base_cost * power(global.trait_config.cost_multiplier, usage);
}

/// scr_trait_increment_usage(trait_name)
/// Zwiększa licznik użycia cechy (wywoływane po nadaniu)
function scr_trait_increment_usage(_trait_name) {
    var usage = 0;
    if (ds_map_exists(global.trait_usage, _trait_name)) {
        usage = ds_map_find_value(global.trait_usage, _trait_name);
        ds_map_replace(global.trait_usage, _trait_name, usage + 1);
    } else {
        ds_map_add(global.trait_usage, _trait_name, 1);
    }
}

/// scr_trait_decrement_usage(trait_name)
/// Zmniejsza licznik użycia cechy (wywoływane gdy cecha zanika)
function scr_trait_decrement_usage(_trait_name) {
    // Sprawdź czy system jeszcze istnieje (może być już zniszczony przy cleanup)
    if (!variable_global_exists("trait_usage")) return;
    if (!ds_exists(global.trait_usage, ds_type_map)) return;

    if (ds_map_exists(global.trait_usage, _trait_name)) {
        var usage = ds_map_find_value(global.trait_usage, _trait_name);
        if (usage > 0) {
            ds_map_replace(global.trait_usage, _trait_name, usage - 1);
        }
    }
}

// =============================================================================
// FUNKCJA LOGISTYCZNA (modelowanie efektów społecznych)
// =============================================================================

/// scr_logistic(value, threshold, steepness, cap)
/// Funkcja logistyczna do modelowania efektów społecznych
/// Interpretacja: 
///   - value < threshold: efekt rośnie wolno (ludzie ignorują)
///   - value ≈ threshold: punkt przełomu (największa dynamika)
///   - value > threshold: nasycenie (odporność lub reakcja obronna)
function scr_logistic(_value, _threshold, _steepness, _cap) {
    var exponent = -_steepness * (_value - _threshold);
    var result = _cap / (1 + exp(exponent));
    return result;
}

/// scr_logistic_fear(raw_fear)
/// Oblicza efektywny strach z funkcją logistyczną
/// Domyślne parametry dla typowej lokacji
function scr_logistic_fear(_raw_fear) {
    // threshold = 50, steepness = 0.1, cap = 100
    return scr_logistic(_raw_fear, 50, 0.1, 100);
}

/// scr_logistic_faith_resistance(faith_level)
/// Oblicza odporność na wpływ gracza bazując na wierze
function scr_logistic_faith_resistance(_faith) {
    // Wysoka wiara = wysoka odporność
    // threshold = 60, steepness = 0.08, cap = 80 (max 80% odporności)
    return scr_logistic(_faith, 60, 0.08, 80);
}

// =============================================================================
// SPRAWDZANIE FAZY DNIA (integracja z obj_daynight)
// =============================================================================

/// scr_trait_is_night()
/// Zwraca true jeśli jest noc (gracz może działać)
function scr_trait_is_night() {
    if (variable_global_exists("daynight_phase")) {
        return (global.daynight_phase == "night");
    }
    // Fallback dla starego systemu
    if (variable_global_exists("is_night")) {
        return global.is_night;
    }
    return false;
}

/// scr_trait_is_evening()
/// Zwraca true jeśli jest wieczór
function scr_trait_is_evening() {
    if (variable_global_exists("daynight_phase")) {
        return (global.daynight_phase == "evening");
    }
    return false;
}

/// scr_trait_is_night_or_evening()
/// Zwraca true jeśli jest noc lub wieczór (czas na cyrografy)
function scr_trait_is_night_or_evening() {
    return scr_trait_is_night() || scr_trait_is_evening();
}

/// scr_trait_can_act()
/// Sprawdza czy gracz może wykonywać akcje (noc + system aktywny)
function scr_trait_can_act() {
    if (!global.trait_system_active) return false;
    return scr_trait_is_night();
}

function scr_economy_day_tick() {
    if (!variable_global_exists("myth_faith")) return;
    
    var cfg = global.economy_config;
    global.myth_faith_income = 0;
    
    // === BAZOWE GENEROWANIE: POPULACJA ===
    var population = scr_economy_get_total_population();
    var base_wsm = population * cfg.wsm_per_population;
    global.myth_faith_income += base_wsm;
    
    // === BONUS OD TRAITS ===
    var trait_bonus = scr_economy_get_trait_wsm_bonus();
    global.myth_faith_income += trait_bonus;
    
    // Dodaj wygenerowane WSM
    scr_myth_faith_add(global.myth_faith_income);
    
    show_debug_message("=== ECONOMY DAY TICK ===");
    show_debug_message("Population: " + string(population));
    show_debug_message("Base WSM: " + string(base_wsm));
    show_debug_message("Trait bonus: " + string(trait_bonus));
    show_debug_message("Total WSM income: " + string(global.myth_faith_income));
    show_debug_message("Current WSM: " + string(global.myth_faith));
}

/// scr_economy_get_total_population()
/// Zwraca całkowitą populację NPC
function scr_economy_get_total_population() {
    if (!variable_global_exists("npcs") || is_undefined(global.npcs)) return 0;

    var count = 0;
    var n = ds_list_size(global.npcs);

    for (var i = 0; i < n; i++) {
        var npc = global.npcs[| i];
        if (instance_exists(npc) && !is_undefined(npc.npc_data)) {
            count++;
        }
    }

    return count;
}

/// scr_economy_get_trait_wsm_bonus()
/// Zwraca bonus WSM z aktywnych cech lokacji
function scr_economy_get_trait_wsm_bonus() {
    var bonus = 0;

    if (!variable_global_exists("settlements") || is_undefined(global.settlements)) return bonus;

    for (var i = 0; i < ds_list_size(global.settlements); i++) {
        var settlement = global.settlements[| i];
        if (!instance_exists(settlement)) continue;

        var traits_list = scr_trait_safe_get_traits(settlement);
        if (is_undefined(traits_list)) continue;

        for (var j = 0; j < ds_list_size(traits_list); j++) {
            var trait = traits_list[| j];
            // Każda aktywna cecha daje bonus WSM bazowany na poziomie
            bonus += trait.level * 0.5;

            // Bonus za cechy "straszne" (generujące strach)
            if (variable_struct_exists(trait.effects, "local_fear_bonus")) {
                bonus += trait.effects.local_fear_bonus * 0.1;
            }
        }
    }

    return bonus;
}

/// scr_economy_on_encounter_visit(encounter_inst)
/// Dodaje WSM za odwiedziny encountera przez NPC
function scr_economy_on_encounter_visit(_encounter) {
    if (!variable_global_exists("myth_faith")) return;

    var cfg = global.economy_config;
    scr_myth_faith_add(cfg.wsm_per_encounter_visit);

    show_debug_message("ECONOMY: +" + string(cfg.wsm_per_encounter_visit) + " WSM from encounter visit");
}

// =============================================================================
// CLEANUP (wywołaj w o_game CleanUp)
// =============================================================================

/// scr_trait_system_cleanup()
/// Czyści zasoby systemu cech
function scr_trait_system_cleanup() {
    if (ds_exists(global.trait_usage, ds_type_map)) {
        ds_map_destroy(global.trait_usage);
    }
    if (ds_exists(global.trait_catalog, ds_type_map)) {
        ds_map_destroy(global.trait_catalog);
    }
    show_debug_message("=== TRAIT SYSTEM CLEANED UP ===");
}
