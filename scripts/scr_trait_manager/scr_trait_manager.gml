/// =============================================================================
/// BORUTA - ZARZĄDZANIE CECHAMI LOKACJI (TRAITS)
/// =============================================================================
/// Funkcje do nadawania, usuwania i aktualizacji cech w lokacjach
/// NOWY SYSTEM: Traits są uniwersalne dla wszystkich typów miejsc
/// =============================================================================

// =============================================================================
// TWORZENIE INSTANCJI CECHY
// =============================================================================

/// scr_trait_create_instance(trait_name, level)
/// Tworzy instancję cechy do umieszczenia w lokacji
function scr_trait_create_instance(_trait_name, _level) {
    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) return undefined;

    _level = clamp(_level, 1, 4);

    // Bezpieczne pobieranie npc_mods z definicji (domyślne wartości jeśli brak)
    var has_npc_mods = variable_struct_exists(def, "npc_mods") && !is_undefined(def.npc_mods);

    var instance = {
        name: _trait_name,
        display_name: def.display_name,
        level: _level,

        // Czas trwania aktywacji (nowy system)
        activation_days: variable_struct_exists(def, "activation_days") ? def.activation_days : 1,

        // Efekty przy odwiedzeniu
        strach_bonus: variable_struct_exists(def, "strach_bonus") ? def.strach_bonus : 0,
        ofiara_bonus: variable_struct_exists(def, "ofiara_bonus") ? def.ofiara_bonus : 0,

        // Czy nadpisuje bazowe efekty miejsca
        overrides_base_effects: variable_struct_exists(def, "overrides_base_effects") ? def.overrides_base_effects : true,

        // Kopiuj modyfikatory NPC z definicji (bezpieczne odczytywanie)
        npc_mods: {
            pracowitosc: has_npc_mods ? (variable_struct_exists(def.npc_mods, "pracowitosc") ? def.npc_mods.pracowitosc : 0) : 0,
            roztargnienie: has_npc_mods ? (variable_struct_exists(def.npc_mods, "roztargnienie") ? def.npc_mods.roztargnienie : 0) : 0,
            ciekawosc: has_npc_mods ? (variable_struct_exists(def.npc_mods, "ciekawosc") ? def.npc_mods.ciekawosc : 0) : 0,
            podatnosc: has_npc_mods ? (variable_struct_exists(def.npc_mods, "podatnosc") ? def.npc_mods.podatnosc : 0) : 0,
            towarzyskosc: has_npc_mods ? (variable_struct_exists(def.npc_mods, "towarzyskosc") ? def.npc_mods.towarzyskosc : 0) : 0,
            wanderlust: has_npc_mods ? (variable_struct_exists(def.npc_mods, "wanderlust") ? def.npc_mods.wanderlust : 0) : 0
        },

        // Efekty (kompatybilność wsteczna)
        effects: scr_trait_calculate_effects(def, _level)
    };

    return instance;
}

/// scr_trait_calculate_effects(definition, level)
/// Oblicza efekty cechy dla danego poziomu
function scr_trait_calculate_effects(_def, _level) {
    var effects = {};

    // Nowe efekty z systemu Plotka
    if (variable_struct_exists(_def, "strach_bonus")) {
        effects.strach_bonus = _def.strach_bonus;
    }
    if (variable_struct_exists(_def, "ofiara_bonus")) {
        effects.ofiara_bonus = _def.ofiara_bonus;
    }

    // Legacy efekty (dla kompatybilności)
    var effect_keys = [
        "local_fear_bonus", "encounter_strength_mult", "nightmare_chance",
        "productivity_mult", "flee_chance_base", "interaction_reduction",
        "gossip_block", "detection_reduction", "tavern_block", "stress_regen_mult",
        "ec_harvest_bonus", "disease_chance", "global_faith_drain",
        "gossip_speed_mult", "fear_spread", "priest_detection_bonus",
        "other_traits_cost_mult", "mutation_chance", "ec_generation_passive"
    ];

    for (var i = 0; i < array_length(effect_keys); i++) {
        var key = effect_keys[i];
        if (variable_struct_exists(_def, key)) {
            effects[$ key] = variable_struct_get(_def, key);
        }
    }

    return effects;
}

// =============================================================================
// NADAWANIE CECH LOKACJOM
// =============================================================================

/// scr_trait_apply_to_settlement(settlement_inst, trait_name)
/// Nadaje cechę lokacji. Zwraca true jeśli sukces.

function scr_trait_apply_to_settlement(_settlement, _trait_name) {
    
    // === WALIDACJA ===
    
    // Sprawdź czy jest noc
    if (!scr_trait_can_act()) {
        show_debug_message("TRAIT: Cannot apply - not night phase!");
        return false;
    }
    
    // Sprawdź instancję
    if (!instance_exists(_settlement)) {
        show_debug_message("TRAIT: Settlement does not exist!");
        return false;
    }
    
    // Sprawdź settlement_data
    if (is_undefined(_settlement.settlement_data)) {
        show_debug_message("TRAIT: No settlement_data!");
        return false;
    }
    
    var sd = _settlement.settlement_data;
    
    // Inicjalizuj traits jeśli brak
    if (is_undefined(sd.traits)) {
        sd.traits = ds_list_create();
    }
    if (is_undefined(sd.trait_slots)) {
        sd.trait_slots = 2; // domyślnie 2 sloty
    }
    
    // Sprawdź wolne sloty
    if (ds_list_size(sd.traits) >= sd.trait_slots) {
        show_debug_message("TRAIT: No free slots in settlement!");
        return false;
    }
    
    // Sprawdź czy cecha już istnieje
    for (var i = 0; i < ds_list_size(sd.traits); i++) {
        var existing = sd.traits[| i];
        if (existing.name == _trait_name) {
            show_debug_message("TRAIT: Settlement already has this trait!");
            return false;
        }
    }
    
    // Pobierz definicję
    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) {
        show_debug_message("TRAIT: Unknown trait '" + _trait_name + "'!");
        return false;
    }
    
    // Sprawdź czy cecha jest dynamiczna (do nadania)
    if (def.type != "dynamic" || def.base_cost < 0) {
        show_debug_message("TRAIT: Trait '" + _trait_name + "' cannot be applied!");
        return false;
    }
    
    // Sprawdź wymagania wstępne
    if (!scr_trait_check_prerequisite(_trait_name, _settlement)) {
        show_debug_message("TRAIT: Prerequisites not met for '" + _trait_name + "'!");
        return false;
    }
    
    // === OBLICZ KOSZT (w WSM - Wiara w Stare Mity) ===
    var cost = scr_trait_get_cost(_trait_name, def.base_cost);

    // Modyfikator kosztu od lokacji (np. Zapomniane Miejsce)
    cost = scr_trait_apply_cost_modifiers(_settlement, cost);

    // Sprawdź czy stać (używamy WSM dla traits)
    if (!scr_myth_faith_can_afford(cost)) {
        show_debug_message("TRAIT: Not enough Myth Faith! Need " + string(cost) + " WSM, have " + string(global.myth_faith));
        return false;
    }

    // === ZASTOSUJ CECHĘ ===

    // Wydaj WSM
    scr_myth_faith_spend(cost);
    
    // Utwórz instancję cechy
    var trait_inst = scr_trait_create_instance(_trait_name, 1);
    
    // Dodaj do lokacji
    ds_list_add(sd.traits, trait_inst);
    
    // Zaktualizuj globalny licznik użycia
    scr_trait_increment_usage(_trait_name);
    
    // Natychmiastowa aktualizacja modyfikatorów NPC
    scr_trait_update_settlement_residents(_settlement);
    
    show_debug_message("TRAIT: Applied '" + _trait_name + "' to settlement " + string(_settlement.id) + " for " + string(cost) + " WSM");

    return true;
}
/// scr_trait_apply_to_settlement_v2(settlement_inst, trait_name)
/// Nowa wersja używająca Wiary w Stare Mity
function scr_trait_apply_to_settlement_v2(_settlement, _trait_name) {
    if (!scr_trait_can_act()) return false;
    if (!instance_exists(_settlement)) return false;
    
    var sd = _settlement.settlement_data;
    
    // Sprawdź sloty
    var max_slots = variable_struct_exists(sd, "trait_slots") ? sd.trait_slots : 2;
    if (is_undefined(sd.traits)) {
        sd.traits = ds_list_create();
    }
    
    if (ds_list_size(sd.traits) >= max_slots) {
        show_debug_message("TRAIT: No free slots!");
        return false;
    }
    
    // Sprawdź czy cecha już istnieje
    for (var i = 0; i < ds_list_size(sd.traits); i++) {
        var existing = sd.traits[| i];
        if (existing.name == _trait_name) {
            show_debug_message("TRAIT: Settlement already has this trait!");
            return false;
        }
    }
    
    // Pobierz definicję
    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) {
        show_debug_message("TRAIT: Unknown trait '" + _trait_name + "'!");
        return false;
    }
    
    // Sprawdź czy cecha jest dynamiczna
    if (def.type != "dynamic" || def.base_cost < 0) {
        show_debug_message("TRAIT: Trait '" + _trait_name + "' cannot be applied!");
        return false;
    }
    
    // Sprawdź wymagania wstępne
    if (!scr_trait_check_prerequisite(_trait_name, _settlement)) {
        show_debug_message("TRAIT: Prerequisites not met!");
        return false;
    }
    
    // === OBLICZ KOSZT W WSM ===
    var cost = scr_trait_get_cost(_trait_name, def.base_cost);
    cost = scr_trait_apply_cost_modifiers(_settlement, cost);
    
    // === SPRAWDŹ CZY STAĆ (WSM) ===
    if (!scr_myth_faith_can_afford(cost)) {
        show_debug_message("TRAIT: Not enough Myth Faith! Need " + string(cost) + " WSM, have " + string(global.myth_faith));
        return false;
    }
    
    // === WYDAJ WSM ===
    scr_myth_faith_spend(cost);
    
    // Utwórz instancję cechy
    var trait_inst = scr_trait_create_instance(_trait_name, 1);
    
    // Dodaj do lokacji
    ds_list_add(sd.traits, trait_inst);
    
    // Zaktualizuj globalny licznik
    scr_trait_increment_usage(_trait_name);
    
    // Aktualizuj NPC
    scr_trait_update_settlement_residents(_settlement);
    
    show_debug_message("TRAIT: Applied '" + _trait_name + "' for " + string(cost) + " WSM");
    
    return true;
}
/// scr_trait_apply_cost_modifiers(settlement_inst, base_cost)
/// Modyfikuje koszt na podstawie cech lokacji
function scr_trait_apply_cost_modifiers(_settlement, _base_cost) {
    var cost = _base_cost;
    var pd = scr_place_get_data(_settlement);
    if (is_undefined(pd)) return cost;

    if (!variable_struct_exists(pd, "traits")) return cost;
    var traits = pd.traits;
    if (!ds_exists(traits, ds_type_list)) return cost;

    // Sprawdź modyfikatory od istniejących cech
    for (var i = 0; i < ds_list_size(traits); i++) {
        var trait = traits[| i];
        if (variable_struct_exists(trait, "effects") && variable_struct_exists(trait.effects, "other_traits_cost_mult")) {
            cost *= trait.effects.other_traits_cost_mult;
        }
    }

    return round(cost);
}

// =============================================================================
// UNIWERSALNE NADAWANIE TRAITS (wszystkie typy miejsc)
// =============================================================================

/// scr_trait_apply_to_place(_place_inst, _trait_name)
/// Uniwersalna funkcja - nadaje trait do dowolnego miejsca
/// @param _place_inst - instancja miejsca (settlement, encounter, source, tavern)
/// @param _trait_name - nazwa traitu do nadania
/// @return bool - czy sukces
function scr_trait_apply_to_place(_place_inst, _trait_name) {
    // === WALIDACJA ===
    if (!scr_trait_can_act()) {
        show_debug_message("TRAIT: Cannot apply - not night phase!");
        return false;
    }

    if (!instance_exists(_place_inst)) {
        show_debug_message("TRAIT: Place does not exist!");
        return false;
    }

    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) {
        show_debug_message("TRAIT: No place_data!");
        return false;
    }

    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";

    // Inicjalizuj traits jeśli brak
    if (!variable_struct_exists(pd, "traits") || is_undefined(pd.traits)) {
        pd.traits = ds_list_create();
    }
    if (!variable_struct_exists(pd, "trait_slots") || is_undefined(pd.trait_slots)) {
        pd.trait_slots = 2;
    }

    var traits = pd.traits;

    // Sprawdź wolne sloty
    if (ds_list_size(traits) >= pd.trait_slots) {
        show_debug_message("TRAIT: No free slots in " + place_type + "!");
        return false;
    }

    // Sprawdź czy cecha już istnieje
    for (var i = 0; i < ds_list_size(traits); i++) {
        var existing = traits[| i];
        if (is_struct(existing) && variable_struct_exists(existing, "name")) {
            if (existing.name == _trait_name) {
                show_debug_message("TRAIT: " + place_type + " already has trait '" + _trait_name + "'!");
                return false;
            }
        }
    }

    // Pobierz definicję
    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) {
        show_debug_message("TRAIT: Unknown trait '" + _trait_name + "'!");
        return false;
    }

    // Sprawdź czy cecha jest dynamiczna (do nadania)
    if (def.type != "dynamic" || def.base_cost < 0) {
        show_debug_message("TRAIT: Trait '" + _trait_name + "' cannot be applied!");
        return false;
    }

    // Sprawdź valid_locations
    var loc_type = variable_struct_exists(pd, "location_type") ? pd.location_type : place_type;
    if (variable_struct_exists(def, "valid_locations")) {
        var valid = def.valid_locations;
        if (array_length(valid) > 0 && valid[0] != "all") {
            if (!array_contains(valid, loc_type) && !array_contains(valid, place_type)) {
                show_debug_message("TRAIT: Trait '" + _trait_name + "' not valid for " + loc_type + "!");
                return false;
            }
        }
    }

    // === OBLICZ KOSZT ===
    var cost = scr_trait_get_cost(_trait_name, def.base_cost);
    cost = scr_trait_apply_cost_modifiers(_place_inst, cost);

    // Sprawdź czy stać (używamy WSM)
    if (!scr_myth_faith_can_afford(cost)) {
        show_debug_message("TRAIT: Not enough WSM! Need " + string(cost) + ", have " + string(scr_myth_faith_get()));
        return false;
    }

    // === ZASTOSUJ CECHĘ ===
    scr_myth_faith_spend(cost);

    // Utwórz instancję cechy
    var trait_inst = scr_trait_create_instance(_trait_name, 1);

    // Dodaj do miejsca
    ds_list_add(traits, trait_inst);

    // Zaktualizuj globalny licznik użycia
    scr_trait_increment_usage(_trait_name);

    show_debug_message("TRAIT: Applied '" + _trait_name + "' to " + place_type + " " + string(_place_inst.id) + " for " + string(cost) + " WSM");

    return true;
}

/// scr_trait_remove_from_place(_place_inst, _trait_name)
/// Usuwa trait z dowolnego miejsca
function scr_trait_remove_from_place(_place_inst, _trait_name) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return false;

    if (!variable_struct_exists(pd, "traits")) return false;
    var traits = pd.traits;
    if (!ds_exists(traits, ds_type_list)) return false;

    for (var i = ds_list_size(traits) - 1; i >= 0; i--) {
        var trait = traits[| i];
        if (is_struct(trait) && variable_struct_exists(trait, "name")) {
            if (trait.name == _trait_name) {
                ds_list_delete(traits, i);
                scr_trait_decrement_usage(_trait_name);

                // Reset aktywnego traitu jeśli to był ten
                if (variable_struct_exists(pd, "active_trait") && pd.active_trait == _trait_name) {
                    pd.active_trait = noone;
                    pd.trait_days_remaining = 0;
                }

                var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";
                show_debug_message("TRAIT: Removed '" + _trait_name + "' from " + place_type);
                return true;
            }
        }
    }

    return false;
}

// =============================================================================
// USUWANIE CECH
// =============================================================================

/// scr_trait_remove_from_settlement(settlement_inst, trait_name)
/// Usuwa cechę z lokacji
function scr_trait_remove_from_settlement(_settlement, _trait_name) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return false;
    
    for (var i = ds_list_size(traits_list) - 1; i >= 0; i--) {
        var trait = traits_list[| i];
        if (trait.name == _trait_name) {
            ds_list_delete(traits_list, i);
            scr_trait_decrement_usage(_trait_name);
            scr_trait_update_settlement_residents(_settlement);
            show_debug_message("TRAIT: Removed '" + _trait_name + "' from settlement " + string(_settlement.id));
            return true;
        }
    }
    
    return false;
}

// =============================================================================
// ESKALACJA POZIOMÓW
// =============================================================================

/// scr_trait_escalate(settlement_inst, trait_name)
/// Próbuje eskalować cechę do wyższego poziomu
/// DUALNA EKONOMIA: EC wymagane tylko dla eskalacji do poziomu III+
function scr_trait_escalate(_settlement, _trait_name) {
    if (!scr_trait_can_act()) return false;
    if (!instance_exists(_settlement)) return false;

    var sd = _settlement.settlement_data;
    if (is_undefined(sd.traits)) return false;

    // Znajdź cechę
    var trait = undefined;
    for (var i = 0; i < ds_list_size(sd.traits); i++) {
        if (sd.traits[| i].name == _trait_name) {
            trait = sd.traits[| i];
            break;
        }
    }

    if (is_undefined(trait)) return false;

    // Sprawdź czy można eskalować
    if (trait.level >= 4) {
        show_debug_message("TRAIT: Already at max level!");
        return false;
    }

    var cfg = global.trait_config;
    var eco_cfg = global.economy_config;
    var next_level = trait.level; // indeks 0-2 dla poziomów 1-3

    // Sprawdź wymagane noce aktywności
    var required_nights = cfg.escalation_nights[next_level - 1];
    if (trait.active_nights < required_nights) {
        show_debug_message("TRAIT: Need " + string(required_nights) + " active nights, have " + string(trait.active_nights));
        return false;
    }

    // === DUALNA EKONOMIA: EC tylko dla poziomów III+ ===
    var ec_cost = 0;
    if (trait.level >= 2) {
        // Eskalacja II→III lub III→IV wymaga EC
        if (trait.level == 2) {
            ec_cost = eco_cfg.escalation_level3_ec; // 15 EC
        } else if (trait.level == 3) {
            ec_cost = eco_cfg.escalation_level4_ec; // 30 EC
        }

        if (!scr_dark_essence_can_afford(ec_cost)) {
            show_debug_message("TRAIT: Not enough EC for escalation to level " + string(trait.level + 1) + "! Need " + string(ec_cost));
            return false;
        }
    }

    // === ESKALUJ ===
    if (ec_cost > 0) {
        scr_dark_essence_spend(ec_cost);
        show_debug_message("TRAIT: Spent " + string(ec_cost) + " EC for escalation");
    }
    trait.level += 1;
    trait.active_nights = 0; // reset licznika
    
    // Przelicz efekty
    var def = scr_trait_get_definition(_trait_name);
    trait.effects = scr_trait_calculate_effects(def, trait.level);
    
    // Przelicz modyfikatory NPC (rosną z poziomem)
    var level_mult = trait.level;
    var has_npc_mods = variable_struct_exists(def, "npc_mods") && !is_undefined(def.npc_mods);
    trait.npc_mods.pracowitosc = has_npc_mods ? def.npc_mods.pracowitosc * level_mult : 0;
    trait.npc_mods.roztargnienie = has_npc_mods ? def.npc_mods.roztargnienie * level_mult : 0;
    trait.npc_mods.ciekawosc = has_npc_mods ? def.npc_mods.ciekawosc * level_mult : 0;
    trait.npc_mods.podatnosc = has_npc_mods ? def.npc_mods.podatnosc * level_mult : 0;
    trait.npc_mods.towarzyskosc = has_npc_mods ? def.npc_mods.towarzyskosc * level_mult : 0;
    trait.npc_mods.wanderlust = has_npc_mods ? def.npc_mods.wanderlust * level_mult : 0;
    
    scr_trait_update_settlement_residents(_settlement);
    
    show_debug_message("TRAIT: Escalated '" + _trait_name + "' to level " + string(trait.level) + "!");
    
    return true;
}

// =============================================================================
// AKTUALIZACJA MODYFIKATORÓW NPC
// =============================================================================

/// scr_trait_update_settlement_residents(settlement_inst)
/// Aktualizuje modyfikatory lokacyjne wszystkich mieszkańców
function scr_trait_update_settlement_residents(_settlement) {
    if (!instance_exists(_settlement)) return;
    if (!variable_instance_exists(_settlement, "settlement_data")) return;
    if (is_undefined(_settlement.settlement_data)) return;
    
    var sd = _settlement.settlement_data;
    
    // Sprawdź czy settlement ma residents (nie wszystkie lokacje mają)
    if (!variable_struct_exists(sd, "residents")) return;
    if (is_undefined(sd.residents)) return;
    if (!ds_exists(sd.residents, ds_type_list)) return;
    
    var residents = sd.residents;
    
    for (var i = 0; i < ds_list_size(residents); i++) {
        var npc = residents[| i];
        if (instance_exists(npc)) {
            scr_apply_location_traits_to_npc(npc);
        }
    }
}

/// scr_apply_location_traits_to_npc(npc_inst)
/// Aplikuje modyfikatory z cech lokacji do NPC
function scr_apply_location_traits_to_npc(_npc) {
    if (!instance_exists(_npc)) return;
    if (is_undefined(_npc.npc_data)) return;
    
    var nd = _npc.npc_data;
    var home = nd.home;
    
    // Inicjalizuj location_mods jeśli brak
    if (is_undefined(nd.location_mods)) {
        nd.location_mods = {
            pracowitosc: 0,
            roztargnienie: 0,
            ciekawosc: 0,
            podatnosc: 0,
            towarzyskosc: 0,
            wanderlust: 0
        };
    } else {
        // Reset
        nd.location_mods.pracowitosc = 0;
        nd.location_mods.roztargnienie = 0;
        nd.location_mods.ciekawosc = 0;
        nd.location_mods.podatnosc = 0;
        nd.location_mods.towarzyskosc = 0;
        nd.location_mods.wanderlust = 0;
    }
    
    // Użyj bezpiecznej funkcji do pobrania traits
    var traits_list = scr_trait_safe_get_traits(home);
    if (is_undefined(traits_list)) return;
    
    // Sumuj modyfikatory ze wszystkich cech
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        if (!variable_struct_exists(trait, "npc_mods")) continue;
        var mods = trait.npc_mods;
        
        nd.location_mods.pracowitosc += mods.pracowitosc;
        nd.location_mods.roztargnienie += mods.roztargnienie;
        nd.location_mods.ciekawosc += mods.ciekawosc;
        nd.location_mods.podatnosc += mods.podatnosc;
        nd.location_mods.towarzyskosc += mods.towarzyskosc;
        nd.location_mods.wanderlust += mods.wanderlust;
    }
}

// =============================================================================
// SYNERGIE I INTERAKCJE MIĘDZY CECHAMI
// =============================================================================

/// scr_trait_check_synergies(settlement_inst)
/// Sprawdza i aplikuje synergie między cechami
function scr_trait_check_synergies(_settlement) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return;
    
    var trait_names = [];
    
    // Zbierz nazwy cech
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        array_push(trait_names, traits_list[| i].name);
    }
    
    // Sprawdź znane synergie
    
    // NAWIEDZENIE + IZOLACJA = PARANOJA (strach ×1.5)
    if (array_contains(trait_names, "nawiedzenie") && array_contains(trait_names, "izolacja")) {
        // Znajdź cechę nawiedzenie i zmodyfikuj
        for (var i = 0; i < ds_list_size(traits_list); i++) {
            var trait = traits_list[| i];
            if (trait.name == "nawiedzenie") {
                if (!variable_struct_exists(trait, "synergy_active")) {
                    trait.synergy_active = true;
                    trait.effects.local_fear_bonus *= 1.5;
                    show_debug_message("SYNERGY: PARANOJA activated! Fear bonus ×1.5");
                }
                break;
            }
        }
    }
    
    // PLOTKARSKA + NAWIEDZENIE = LEGENDA (zasięg ×2)
    if (array_contains(trait_names, "plotkarska") && array_contains(trait_names, "nawiedzenie")) {
        for (var i = 0; i < ds_list_size(traits_list); i++) {
            var trait = traits_list[| i];
            if (trait.name == "plotkarska") {
                if (!variable_struct_exists(trait, "synergy_active")) {
                    trait.synergy_active = true;
                    trait.effects.gossip_speed_mult *= 2;
                    show_debug_message("SYNERGY: LEGENDA activated! Gossip range ×2");
                }
                break;
            }
        }
    }
}

/// scr_trait_check_conflicts(settlement_inst)
/// Sprawdza konflikty między cechami
function scr_trait_check_conflicts(_settlement) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return;
    
    var trait_names = [];
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        array_push(trait_names, traits_list[| i].name);
    }
    
    // PLOTKARSKA + IZOLACJA = konflikt (plotki nie mogą się szerzyć)
    if (array_contains(trait_names, "plotkarska") && array_contains(trait_names, "izolacja")) {
        for (var i = 0; i < ds_list_size(traits_list); i++) {
            var trait = traits_list[| i];
            if (trait.name == "plotkarska") {
                if (!variable_struct_exists(trait, "conflict_active")) {
                    trait.conflict_active = true;
                    if (variable_struct_exists(trait.effects, "gossip_speed_mult")) {
                        trait.effects.gossip_speed_mult *= 0.2;
                    }
                    show_debug_message("CONFLICT: Plotkarska weakened by Izolacja!");
                }
                break;
            }
        }
    }
}

// =============================================================================
// QUERY FUNCTIONS
// =============================================================================

/// scr_trait_settlement_has(settlement_inst, trait_name)
/// Sprawdza czy lokacja ma daną cechę
function scr_trait_settlement_has(_settlement, _trait_name) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return false;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        if (traits_list[| i].name == _trait_name) {
            return true;
        }
    }
    return false;
}

/// scr_trait_settlement_get(settlement_inst, trait_name)
/// Zwraca instancję cechy z lokacji lub undefined
function scr_trait_settlement_get(_settlement, _trait_name) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return undefined;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        if (traits_list[| i].name == _trait_name) {
            return traits_list[| i];
        }
    }
    return undefined;
}

/// scr_trait_settlement_get_all(settlement_inst)
/// Zwraca tablicę wszystkich cech lokacji
function scr_trait_settlement_get_all(_settlement) {
    var result = [];
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return result;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        array_push(result, traits_list[| i]);
    }
    return result;
}

/// scr_trait_settlement_slots_free(settlement_inst)
/// Zwraca liczbę wolnych slotów
function scr_trait_settlement_slots_free(_settlement) {
    var sd = scr_trait_safe_get_settlement_data(_settlement);
    if (is_undefined(sd)) return 0;
    
    var max_slots = variable_struct_exists(sd, "trait_slots") ? sd.trait_slots : 2;
    var traits_list = scr_trait_safe_get_traits(_settlement);
    var used = is_undefined(traits_list) ? 0 : ds_list_size(traits_list);
    
    return max(0, max_slots - used);
}
