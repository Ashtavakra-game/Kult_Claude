/// =============================================================================
/// BORUTA - AKTUALIZACJA CECH (TICK SYSTEM)
/// =============================================================================
/// System zanikania, nocnych ticków i generowania Esencji Ciemności
/// =============================================================================

// =============================================================================
// TICK NOCNY (główna pętla aktualizacji)
// =============================================================================

/// scr_trait_night_tick()
/// Wywoływane raz na noc (np. przy zmianie fazy na noc)
/// Aktualizuje wszystkie cechy, generuje EC, sprawdza zanikanie
function scr_trait_night_tick() {
    if (!global.trait_system_active) return;
    
    show_debug_message("=== TRAIT NIGHT TICK ===");
    
    // Reset dochodu nocnego
    global.dark_essence_income = 0;
    
    // Iteruj przez wszystkie settlements
    if (is_undefined(global.settlements)) return;
    
    for (var i = 0; i < ds_list_size(global.settlements); i++) {
        var settlement = global.settlements[| i];
        if (instance_exists(settlement)) {
            scr_trait_tick_settlement(settlement);
        }
    }
    
    // Generuj EC z sług (cyrografy)
    scr_trait_generate_ec_from_slaves();
    
    // Dodaj zgromadzony dochód
    scr_dark_essence_add(global.dark_essence_income);
    
    show_debug_message("Night income: +" + string(global.dark_essence_income) + " EC");
    show_debug_message("Total EC: " + string(global.dark_essence));
}

/// scr_trait_tick_settlement(settlement_inst)
/// Aktualizuje cechy pojedynczej lokacji
function scr_trait_tick_settlement(_settlement) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return;
    
    // Przetwórz każdą cechę (od końca, bo możemy usuwać)
    for (var i = ds_list_size(traits_list) - 1; i >= 0; i--) {
        var trait = traits_list[| i];
        
        // --- ZANIKANIE ---
        scr_trait_process_decay(trait, _settlement, i);
        
        // --- GENEROWANIE EC ---
        scr_trait_generate_ec_from_trait(trait, _settlement);
        
        // --- LICZNIK AKTYWNYCH NOCY ---
        trait.active_nights += 1;
        
        // --- EFEKTY GLOBALNE ---
        scr_trait_apply_global_effects(trait);
    }
    
    // Sprawdź synergie i konflikty
    scr_trait_check_synergies(_settlement);
    scr_trait_check_conflicts(_settlement);
    
    // Aktualizuj modyfikatory NPC
    scr_trait_update_settlement_residents(_settlement);
}

// =============================================================================
// ZANIKANIE CECH
// =============================================================================

/// scr_trait_process_decay(trait, settlement, index)
/// Przetwarza zanikanie cechy
function scr_trait_process_decay(_trait, _settlement, _index) {
    // Permanentne cechy nie zanikają
    if (_trait.duration == -1) return;
    
    // Oblicz efektywne tempo zanikania
    var decay = _trait.decay_rate;
    
    // Modyfikator od lokalnej wiary
    var sd = _settlement.settlement_data;
    if (variable_struct_exists(sd, "local_faith")) {
        var faith_mod = sd.local_faith / 100; // 0-1
        decay += global.trait_config.faith_decay_bonus * faith_mod;
    }
    
    // Zastosuj zanikanie
    _trait.duration -= decay * room_speed;
    
    // Usuń jeśli wygasła
    if (_trait.duration <= 0) {
        show_debug_message("TRAIT: '" + _trait.name + "' decayed in settlement " + string(_settlement.id));
        ds_list_delete(sd.traits, _index);
        scr_trait_decrement_usage(_trait.name);
    }
}

/// scr_trait_set_temporary(settlement_inst, trait_name, duration_seconds)
/// Ustawia cechę jako tymczasową z określonym czasem trwania
function scr_trait_set_temporary(_settlement, _trait_name, _duration) {
    var trait = scr_trait_settlement_get(_settlement, _trait_name);
    if (is_undefined(trait)) return false;
    
    trait.duration = _duration * room_speed;
    return true;
}

// =============================================================================
// GENEROWANIE ESENCJI CIEMNOŚCI
// =============================================================================

/// scr_trait_generate_ec_from_trait(trait, settlement)
/// Generuje EC na podstawie efektów cechy
function scr_trait_generate_ec_from_trait(_trait, _settlement) {
    var cfg = global.trait_config;
    var effects = _trait.effects;
    
    // Pasywna generacja EC (np. Sprofanowane Miejsce)
    if (variable_struct_exists(effects, "ec_generation_passive")) {
        global.dark_essence_income += effects.ec_generation_passive;
    }
    
    // EC z akumulacji strachu w encounterach w pobliżu
    scr_trait_generate_ec_from_fear(_settlement);
}

/// scr_trait_generate_ec_from_fear(settlement)
/// Generuje EC z akumulacji strachu w encounterach przypisanych do lokacji
function scr_trait_generate_ec_from_fear(_settlement) {
    if (!instance_exists(_settlement)) return;
    if (is_undefined(global.encounters)) return;
    
    var cfg = global.trait_config;
    var sd = _settlement.settlement_data;
    
    // Znajdź encountery w pobliżu tej lokacji
    var search_radius = 150; // piksele
    
    for (var i = 0; i < ds_list_size(global.encounters); i++) {
        var enc = global.encounters[| i];
        if (!instance_exists(enc)) continue;
        
        var dist = point_distance(_settlement.x, _settlement.y, enc.x, enc.y);
        if (dist <= search_radius) {
            if (!is_undefined(enc.encounter_data)) {
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
    if (is_undefined(global.npcs)) return;
    
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
    var cfg = global.trait_config;
    var ec_amount = cfg.ec_per_sin;
    
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
    var cfg = global.trait_config;
    scr_dark_essence_add(cfg.ec_per_chaos);
    show_debug_message("CHAOS: Conflict in settlement " + string(_settlement.id) + " - +" + string(cfg.ec_per_chaos) + " EC");
}

// =============================================================================
// EFEKTY GLOBALNE
// =============================================================================

/// scr_trait_apply_global_effects(trait)
/// Aplikuje globalne efekty cechy (wpływ na świat)
function scr_trait_apply_global_effects(_trait) {
    var effects = _trait.effects;
    
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
    // Rozpoczęcie nocy - tick nocny
    if (_new_phase == "night" && _old_phase != "night") {
        scr_trait_night_tick();
    }
    
    // Rozpoczęcie dnia - sprawdź ucieczkę NPC
    if (_new_phase == "morning" && _old_phase == "night") {
        scr_trait_morning_check();
    }
}

/// scr_trait_morning_check()
/// Sprawdzenia poranne (ucieczka NPC, mutacje)
function scr_trait_morning_check() {
    if (is_undefined(global.npcs)) return;
    
    for (var i = 0; i < ds_list_size(global.npcs); i++) {
        var npc = global.npcs[| i];
        if (instance_exists(npc)) {
            scr_trait_check_flee(npc);
        }
    }
}
