/// =============================================================================
/// BORUTA - AKTUALIZACJA CECH (TICK SYSTEM)
/// =============================================================================
/// System nocnych ticków i generowania Esencji Ciemności
/// NOWY SYSTEM: Traits nie zanikają - wymagają aktywacji przez odwiedzenie
/// =============================================================================

// =============================================================================
// TICK NOCNY (główna pętla aktualizacji)
// =============================================================================

/// scr_trait_night_tick()
/// Wywoływane raz na noc (np. przy zmianie fazy na noc)
/// Aktualizuje wszystkie cechy, generuje EC
function scr_trait_night_tick() {
    if (!variable_global_exists("trait_system_active")) return;
    if (!global.trait_system_active) return;

    show_debug_message("=== TRAIT NIGHT TICK ===");

    // Reset dochodu nocnego
    global.dark_essence_income = 0;

    // Iteruj przez wszystkie settlements
    if (variable_global_exists("settlements") && ds_exists(global.settlements, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.settlements); i++) {
            var settlement = global.settlements[| i];
            if (instance_exists(settlement)) {
                scr_trait_tick_place(settlement);
            }
        }
    }

    // Generuj EC z sług (cyrografy)
    scr_trait_generate_ec_from_slaves();

    // Dodaj zgromadzony dochód
    scr_dark_essence_add(global.dark_essence_income);

    show_debug_message("Night income: +" + string(global.dark_essence_income) + " EC");
    show_debug_message("Total EC: " + string(global.dark_essence));
}

/// scr_trait_tick_place(_place_inst)
/// Aktualizuje cechy pojedynczego miejsca (uniwersalne)
function scr_trait_tick_place(_place_inst) {
    if (!instance_exists(_place_inst)) return;

    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    // Sprawdź traits
    if (!variable_struct_exists(pd, "traits")) return;
    var traits = pd.traits;
    if (!ds_exists(traits, ds_type_list)) return;

    // Przetwórz każdą cechę
    for (var i = ds_list_size(traits) - 1; i >= 0; i--) {
        var trait = traits[| i];
        if (!is_struct(trait)) continue;

        // --- GENEROWANIE EC (jeśli trait jest aktywny) ---
        if (scr_place_has_active_trait(_place_inst)) {
            scr_trait_generate_ec_from_trait(trait, _place_inst);
        }

        // --- EFEKTY GLOBALNE ---
        if (variable_struct_exists(trait, "effects")) {
            scr_trait_apply_global_effects(trait);
        }
    }

    // Aktualizuj modyfikatory NPC (tylko dla settlementów z mieszkańcami)
    if (variable_struct_exists(pd, "residents")) {
        scr_trait_update_settlement_residents(_place_inst);
    }
}

/// scr_trait_tick_settlement(settlement_inst)
/// LEGACY - przekierowanie do nowej funkcji
function scr_trait_tick_settlement(_settlement) {
    scr_trait_tick_place(_settlement);
}

// =============================================================================
// ZANIKANIE CECH - USUNIĘTE W NOWYM SYSTEMIE
// =============================================================================
// W nowym systemie traits nie zanikają automatycznie.
// Traits muszą być aktywowane przez odwiedzenie i wygasają po określonej
// liczbie dni bez ponownej wizyty.
// =============================================================================

/// scr_trait_process_decay(trait, settlement, index)
/// LEGACY - funkcja zachowana dla kompatybilności, ale nie robi nic
function scr_trait_process_decay(_trait, _settlement, _index) {
    // Nowy system nie używa zanikania - traits są aktywowane przez odwiedzenie
    // i wygasają przez scr_traits_daily_tick() w scr_population_system.gml
    return;
}

/// scr_trait_set_temporary(settlement_inst, trait_name, duration_seconds)
/// LEGACY - w nowym systemie traits są aktywowane przez odwiedzenie
function scr_trait_set_temporary(_settlement, _trait_name, _duration) {
    // Nowy system nie używa duration - używaj scr_place_activate_trait()
    return false;
}

// =============================================================================
// GENEROWANIE ESENCJI CIEMNOŚCI
// =============================================================================

/// scr_trait_generate_ec_from_trait(trait, place_inst)
/// Generuje EC na podstawie efektów cechy
function scr_trait_generate_ec_from_trait(_trait, _place_inst) {
    if (!is_struct(_trait)) return;
    if (!variable_global_exists("trait_config")) return;

    var cfg = global.trait_config;

    // Sprawdź czy trait ma effects
    if (!variable_struct_exists(_trait, "effects")) return;
    var effects = _trait.effects;
    if (!is_struct(effects)) return;

    // Pasywna generacja EC (np. Sprofanowane Miejsce - legacy)
    if (variable_struct_exists(effects, "ec_generation_passive")) {
        global.dark_essence_income += effects.ec_generation_passive;
    }

    // EC z akumulacji strachu w encounterach w pobliżu
    scr_trait_generate_ec_from_fear(_place_inst);
}

/// scr_trait_generate_ec_from_fear(_place_inst)
/// Generuje EC z akumulacji strachu w encounterach przypisanych do miejsca
function scr_trait_generate_ec_from_fear(_place_inst) {
    if (!instance_exists(_place_inst)) return;
    if (!variable_global_exists("encounters")) return;
    if (!ds_exists(global.encounters, ds_type_list)) return;
    if (!variable_global_exists("trait_config")) return;

    var cfg = global.trait_config;

    // Znajdź encountery w pobliżu tego miejsca
    var search_radius = 150; // piksele

    for (var i = 0; i < ds_list_size(global.encounters); i++) {
        var enc = global.encounters[| i];
        if (!instance_exists(enc)) continue;

        var dist = point_distance(_place_inst.x, _place_inst.y, enc.x, enc.y);
        if (dist <= search_radius) {
            if (variable_instance_exists(enc, "encounter_data") && !is_undefined(enc.encounter_data)) {
                var ed = enc.encounter_data;
                if (variable_struct_exists(ed, "akumulacja_strachu") && ed.akumulacja_strachu > 0) {
                    var ec_from_fear = ed.akumulacja_strachu * cfg.ec_per_fear_point;
                    global.dark_essence_income += ec_from_fear;

                    // Reset akumulacji po zebraniu
                    ed.akumulacja_strachu = 0;
                }
            }
        }
    }
}

/// scr_trait_generate_ec_from_slaves()
/// Generuje EC z NPC ze statusem sługa (cyrograf)
function scr_trait_generate_ec_from_slaves() {
    if (!variable_global_exists("npcs")) return;
    if (!ds_exists(global.npcs, ds_type_list)) return;
    if (!variable_global_exists("trait_config")) return;

    var cfg = global.trait_config;
    var slave_count = 0;
    
    // Inicjalizuj listę sług jeśli nie istnieje (integracja z scr_cyrograf)
    if (!variable_global_exists("slugi") || is_undefined(global.slugi)) {
        global.slugi = ds_list_create();
    }
    
    for (var i = 0; i < ds_list_size(global.npcs); i++) {
        var npc = global.npcs[| i];
        if (!instance_exists(npc)) continue;
        if (!variable_instance_exists(npc, "npc_data") || is_undefined(npc.npc_data)) continue;
        
        var traits = npc.npc_data.traits;
        if (variable_struct_exists(traits, "sluga") && traits.sluga) {
            global.dark_essence_income += cfg.ec_per_slave;
            slave_count++;
            
            // Dodaj do listy sług jeśli nie ma
            if (ds_list_find_index(global.slugi, npc) < 0) {
                ds_list_add(global.slugi, npc);
            }
        }
    }
    
    // Wyczyść nieaktywnych sług z listy
    for (var i = ds_list_size(global.slugi) - 1; i >= 0; i--) {
        var npc = global.slugi[| i];
        if (!instance_exists(npc) || is_undefined(npc.npc_data) || !npc.npc_data.traits.sluga) {
            ds_list_delete(global.slugi, i);
        }
    }
    
    if (slave_count > 0) {
        show_debug_message("CYROGRAF: Generated " + string(slave_count * cfg.ec_per_slave) + " EC from " + string(slave_count) + " slugi");
    }
}

/// scr_trait_on_sin_committed(npc_inst, sin_type)
/// Wywoływane gdy NPC popełni grzech - generuje jednorazowe EC
function scr_trait_on_sin_committed(_npc, _sin_type) {
    if (!variable_global_exists("trait_config")) return;
    var cfg = global.trait_config;
    var ec_amount = variable_struct_exists(cfg, "ec_per_sin") ? cfg.ec_per_sin : 5;
    
    // Różne grzechy mogą dawać różne ilości
    switch (_sin_type) {
        case "pycha":
            ec_amount = 8;
            break;
        case "chciwosc":
            ec_amount = 10;
            break;
        case "zaznosc":
            ec_amount = 7;
            break;
        case "gniew":
            ec_amount = 12;
            break;
        case "nieczystosc":
            ec_amount = 15;
            break;
        case "obzarstwo":
            ec_amount = 5;
            break;
        case "lenistwo":
            ec_amount = 6;
            break;
        case "cyrograf":
            ec_amount = 15;  // Podpisanie paktu z diabłem - ciężki grzech
            break;
    }
    
    scr_dark_essence_add(ec_amount);
    show_debug_message("SIN: NPC " + string(_npc.id) + " committed '" + _sin_type + "' - +" + string(ec_amount) + " EC");
}

/// scr_trait_on_chaos_event(settlement_inst)
/// Wywoływane przy konflikcie między NPC - generuje EC
function scr_trait_on_chaos_event(_settlement) {
    if (!variable_global_exists("trait_config")) return;
    var cfg = global.trait_config;
    var ec_amount = variable_struct_exists(cfg, "ec_per_chaos") ? cfg.ec_per_chaos : 3;
    scr_dark_essence_add(ec_amount);
    show_debug_message("CHAOS: Conflict in settlement " + string(_settlement.id) + " - +" + string(ec_amount) + " EC");
}

// =============================================================================
// EFEKTY GLOBALNE
// =============================================================================

/// scr_trait_apply_global_effects(trait)
/// Aplikuje globalne efekty cechy (wpływ na świat)
function scr_trait_apply_global_effects(_trait) {
    if (!is_struct(_trait)) return;
    if (!variable_struct_exists(_trait, "effects")) return;
    var effects = _trait.effects;
    if (!is_struct(effects)) return;
    
    // Drenaż globalnej wiary
    if (variable_struct_exists(effects, "global_faith_drain")) {
        if (variable_global_exists("global_faith")) {
            global.global_faith -= effects.global_faith_drain;
            global.global_faith = max(0, global.global_faith);
        }
    }
}

// =============================================================================
// EFEKTY NA ENCOUNTERY
// =============================================================================

/// scr_trait_get_encounter_modifier(settlement_inst)
/// Zwraca mnożnik siły encounterów dla lokacji
function scr_trait_get_encounter_modifier(_settlement) {
    var mult = 1.0;
    
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return mult;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        if (variable_struct_exists(trait, "effects") && variable_struct_exists(trait.effects, "encounter_strength_mult")) {
            mult *= trait.effects.encounter_strength_mult;
        }
    }
    
    return mult;
}

/// scr_trait_get_fear_bonus(settlement_inst)
/// Zwraca bonus do generowania strachu dla lokacji
function scr_trait_get_fear_bonus(_settlement) {
    var bonus = 0;
    
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return bonus;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        if (variable_struct_exists(trait, "effects") && variable_struct_exists(trait.effects, "local_fear_bonus")) {
            bonus += trait.effects.local_fear_bonus;
        }
    }
    
    return bonus;
}

// =============================================================================
// EFEKTY NA PRODUKTYWNOŚĆ
// =============================================================================

/// scr_trait_get_productivity_modifier(settlement_inst)
/// Zwraca mnożnik produktywności dla lokacji
function scr_trait_get_productivity_modifier(_settlement) {
    var mult = 1.0;
    
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return mult;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        if (variable_struct_exists(trait, "effects") && variable_struct_exists(trait.effects, "productivity_mult")) {
            mult *= trait.effects.productivity_mult;
        }
    }
    
    return mult;
}

// =============================================================================
// UCIECZKKA NPC Z LOKACJI (flee chance)
// =============================================================================

/// scr_trait_check_flee(npc_inst)
/// Sprawdza czy NPC ucieka z nawiedzonej lokacji
/// Wywoływane raz na noc dla każdego NPC
function scr_trait_check_flee(_npc) {
    if (!instance_exists(_npc)) return false;
    if (!variable_instance_exists(_npc, "npc_data")) return false;
    if (is_undefined(_npc.npc_data)) return false;
    
    if (!variable_struct_exists(_npc.npc_data, "home")) return false;
    var home = _npc.npc_data.home;
    
    var traits_list = scr_trait_safe_get_traits(home);
    if (is_undefined(traits_list)) return false;
    
    var total_flee_chance = 0;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        if (variable_struct_exists(trait, "effects") && variable_struct_exists(trait.effects, "flee_chance_base")) {
            total_flee_chance += trait.effects.flee_chance_base;
        }
    }
    
    if (total_flee_chance > 0 && random(1) < total_flee_chance) {
        show_debug_message("FLEE: NPC " + string(_npc.id) + " fled from settlement " + string(home.id) + "!");
        return true;
    }
    
    return false;
}


// =============================================================================
// INTEGRACJA Z ISTNIEJĄCYM SYSTEMEM NPC
// =============================================================================

/// Zmodyfikowana wersja scr_npc_trait (dodaje location_mods)
/// UWAGA: Ta funkcja zastępuje istniejącą scr_npc_trait w scr_npc_system.gml
function scr_npc_trait_with_location(_inst, _trait) {
    if (!instance_exists(_inst)) return 0;
    if (is_undefined(_inst.npc_data)) return 0;
    
    var base = 0;
    var ind_mod = 0;
    var glob_mod = 0;
    var loc_mod = 0;
    
    // Bazowa wartość cechy
    if (variable_struct_exists(_inst.npc_data.traits, _trait)) {
        base = variable_struct_get(_inst.npc_data.traits, _trait);
    }
    
    // Modyfikator indywidualny
    if (variable_struct_exists(_inst.npc_data.modifiers, _trait)) {
        ind_mod = variable_struct_get(_inst.npc_data.modifiers, _trait);
    }
    
    // Modyfikator globalny
    if (!is_undefined(global.npc_mod) && variable_struct_exists(global.npc_mod, _trait)) {
        glob_mod = variable_struct_get(global.npc_mod, _trait);
    }
    
    // NOWE: Modyfikator lokacyjny (z cech lokacji)
    if (!is_undefined(_inst.npc_data.location_mods)) {
        if (variable_struct_exists(_inst.npc_data.location_mods, _trait)) {
            loc_mod = variable_struct_get(_inst.npc_data.location_mods, _trait);
        }
    }
    
    return clamp(base + ind_mod + glob_mod + loc_mod, 0, 100);
}

// =============================================================================
// HOOK: ZMIANA FAZY DNIA
// =============================================================================

/// scr_trait_on_phase_change(new_phase, old_phase)
/// Wywoływane przy zmianie fazy dnia (z obj_daynight)
function scr_trait_on_phase_change(_new_phase, _old_phase) {
    // === EVENING: Generowanie WSM (koniec dnia) ===
    if (_new_phase == "evening" && _old_phase != "evening") {
        scr_economy_day_tick();
        show_debug_message("PHASE: Evening - WSM generated");
    }

    // Rozpoczęcie nocy - tick nocny (EC, cechy, cyrografy)
    if (_new_phase == "night" && _old_phase != "night") {
        scr_trait_night_tick();
    }

    // Rozpoczęcie dnia - tick dzienny dla encounterów i NPC traits
    if (_new_phase == "morning" && _old_phase == "night") {
        // Tick dzienny encounterów (zmniejsza days_remaining, dezaktywuje wygasłe)
        scr_encounter_daily_tick();

        // Tick dzienny tymczasowych traits NPC z encounterów
        scr_encounter_npc_traits_daily_tick();

        // Tick populacji (zanik wskaźników, przyrost szaleństwa, warunki końca gry)
        scr_population_night_tick();

        // Sprawdź ucieczkę NPC
        scr_trait_morning_check();
    }
}

/// scr_trait_morning_check()
/// Sprawdzenia poranne (ucieczka NPC, mutacje)
function scr_trait_morning_check() {
    if (!variable_global_exists("npcs")) return;
    if (!ds_exists(global.npcs, ds_type_list)) return;

    for (var i = 0; i < ds_list_size(global.npcs); i++) {
        var npc = global.npcs[| i];
        if (instance_exists(npc)) {
            scr_trait_check_flee(npc);
        }
    }
}
