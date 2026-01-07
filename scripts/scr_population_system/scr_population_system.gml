/// =============================================================================
/// BORUTA - SYSTEM ZASOBÓW (OFIARA i STRACH)
/// =============================================================================
/// Dwa główne zasoby: Ofiara i Strach
/// Zasoby bez ograniczeń - mogą być ujemne i dodatnie
/// Przyznawane/odejmowane raz na dobę przy odwiedzeniu miejsca
/// =============================================================================

// =============================================================================
// INICJALIZACJA SYSTEMU
// =============================================================================

/// scr_population_system_init()
/// Inicjalizacja systemu - wywołaj w o_game Create
function scr_population_system_init() {
    // === GŁÓWNE ZASOBY ===
    global.ofiara = 0;         // Ofiara - waluta do kupowania traits (>=0)
    global.strach = 0;         // Strach - współczynnik (bez ograniczeń)
    global.wwsm = 0;           // WwSM (Wiara w Stare Mity) - współczynnik (bez ograniczeń)

    // === SYSTEM ODWIEDZIN GRACZA ===
    // Gracz aktywuje tylko karczmę (raz na dobę)
    global.visited_today = {
        tavern_active: false   // czy gracz był dzisiaj w pobliżu karczmy
    };
    // NPC mają swoje własne listy visited_places_today w npc_data

    // === DZIEŃ W GRZE ===
    global.day_counter = 0;
    global.last_phase = "";

    // === FLAGI STANU GRY ===
    global.game_won = false;
    global.game_lost = false;
    global.game_lost_reason = "";

    show_debug_message("=== RESOURCE SYSTEM INITIALIZED (Ofiara=0, Strach=0) ===");
}

// =============================================================================
// MODYFIKACJA ZASOBÓW
// =============================================================================

/// scr_add_ofiara(amount, source)
/// Dodaje/odejmuje Ofiarę (bez ograniczeń)
/// @param _amount - ilość do dodania (ujemna = odjęcie)
/// @param _source - źródło (do debugowania)
/// @return _amount - dodana wartość
function scr_add_ofiara(_amount, _source) {
    global.ofiara += _amount;

    var _sign = _amount >= 0 ? "+" : "";
    show_debug_message("OFIARA " + _sign + string(_amount) + " = " + string(global.ofiara) + " (from " + _source + ")");

    return _amount;
}

/// scr_add_strach(amount, source)
/// Dodaje/odejmuje Strach (bez ograniczeń)
/// @param _amount - ilość do dodania (ujemna = odjęcie)
/// @param _source - źródło (do debugowania)
/// @return _amount - dodana wartość
function scr_add_strach(_amount, _source) {
    global.strach += _amount;

    var _sign = _amount >= 0 ? "+" : "";
    show_debug_message("STRACH " + _sign + string(_amount) + " = " + string(global.strach) + " (from " + _source + ")");

    return _amount;
}

/// scr_add_wwsm(amount, source)
/// Dodaje/odejmuje WwSM - Wiarę w Stare Mity (bez ograniczeń, może być ujemne)
/// @param _amount - ilość do dodania (ujemna = odjęcie)
/// @param _source - źródło (do debugowania)
/// @return _amount - dodana wartość
function scr_add_wwsm(_amount, _source) {
    global.wwsm += _amount;

    var _sign = _amount >= 0 ? "+" : "";
    show_debug_message("WWSM " + _sign + string(_amount) + " = " + string(global.wwsm) + " (from " + _source + ")");

    return _amount;
}

// =============================================================================
// SYSTEM EKONOMII - OFIARA (WALUTA)
// =============================================================================

/// scr_ofiara_spend(amount)
/// Wydaje Ofiarę (walutę). Zwraca true jeśli sukces.
/// Ofiara nie może spaść poniżej 0.
function scr_ofiara_spend(_amount) {
    if (global.ofiara >= _amount) {
        global.ofiara -= _amount;
        show_debug_message("OFIARA SPEND: -" + string(_amount) + " = " + string(global.ofiara));
        return true;
    }
    return false;
}

/// scr_ofiara_can_afford(amount)
/// Sprawdza czy gracza stać na wydatek w Ofiarze
function scr_ofiara_can_afford(_amount) {
    return (global.ofiara >= _amount);
}

/// scr_ofiara_get()
/// Zwraca aktualną ilość Ofiary
function scr_ofiara_get() {
    return global.ofiara;
}

// =============================================================================
// SYSTEM ODWIEDZIN - GRACZ
// =============================================================================

/// scr_visit_check_and_apply_player(_place_inst, _place_type)
/// Sprawdza czy gracz już odwiedził karczmę dziś i przyznaje zasoby
/// UWAGA: Tylko karczma reaguje na gracza! Settlement/Encounter/Source reagują na NPC.
/// @param _place_inst - instancja miejsca
/// @param _place_type - "tavern" (inne typy ignorowane)
/// @return true jeśli zasoby zostały przyznane, false jeśli już odwiedzono
function scr_visit_check_and_apply_player(_place_inst, _place_type) {
    if (!instance_exists(_place_inst)) return false;

    // Tylko karczma reaguje na gracza
    if (_place_type == "tavern") {
        if (global.visited_today.tavern_active) {
            return false;
        }
        global.visited_today.tavern_active = true;
        // Gracz w pobliżu karczmy: +1 Ofiara, +1 Strach
        scr_add_ofiara(1, "tavern_player");
        scr_add_strach(1, "tavern_player");
        show_debug_message("VISIT: Gracz przy karczmie -> +1 Ofiara, +1 Strach");
        return true;
    }

    return false;
}

// =============================================================================
// SYSTEM ODWIEDZIN - NPC (raz na dobę PER NPC PER MIEJSCE)
// =============================================================================

/// scr_visit_check_and_apply_npc(_npc_inst, _place_inst, _place_type)
/// Sprawdza czy ten NPC już dziś odwiedził to miejsce i przyznaje zasoby
/// Zasoby są naliczane RAZ NA DOBĘ PER NPC PER MIEJSCE
/// @param _npc_inst - instancja NPC
/// @param _place_inst - instancja miejsca
/// @param _place_type - "settlement", "encounter", "source"
/// @return true jeśli zasoby zostały przyznane
function scr_visit_check_and_apply_npc(_npc_inst, _place_inst, _place_type) {
    if (!instance_exists(_place_inst)) return false;
    if (!instance_exists(_npc_inst)) return false;
    if (!variable_instance_exists(_npc_inst, "npc_data")) return false;

    var nd = _npc_inst.npc_data;
    var place_id = _place_inst.id;

    // Upewnij się że NPC ma strukturę visited_places_today
    if (!variable_struct_exists(nd, "visited_places_today")) {
        nd.visited_places_today = {
            settlements: [],
            encounters: [],
            sources: []
        };
    }

    // Sprawdź czy TEN NPC już dziś odwiedził to miejsce
    switch (_place_type) {
        case "settlement":
            if (scr_array_contains(nd.visited_places_today.settlements, place_id)) {
                return false;
            }
            array_push(nd.visited_places_today.settlements, place_id);
            scr_apply_settlement_resources(_place_inst, "npc_" + string(_npc_inst.id));
            return true;

        case "encounter":
            if (scr_array_contains(nd.visited_places_today.encounters, place_id)) {
                return false;
            }
            array_push(nd.visited_places_today.encounters, place_id);
            scr_apply_encounter_resources(_place_inst, "npc_" + string(_npc_inst.id));
            return true;

        case "source":
            if (scr_array_contains(nd.visited_places_today.sources, place_id)) {
                return false;
            }
            array_push(nd.visited_places_today.sources, place_id);
            scr_apply_source_resources(_place_inst, "npc_" + string(_npc_inst.id));
            return true;
    }

    return false;
}

/// scr_visit_check_and_apply_servant - ALIAS dla kompatybilności wstecznej
function scr_visit_check_and_apply_servant(_npc_inst, _place_inst, _place_type) {
    return scr_visit_check_and_apply_npc(_npc_inst, _place_inst, _place_type);
}

// =============================================================================
// UNIWERSALNY SYSTEM APLIKOWANIA ZASOBÓW (UJEDNOLICONY)
// =============================================================================
// Każde miejsce ma bazowe efekty, które mogą być ZASTĄPIONE przez aktywny trait.
// Trait "Plotka" zastępuje bazowe efekty: +1 Strach (bez względu na typ miejsca)
// =============================================================================

/// scr_place_get_data(_place_inst)
/// Zwraca dane miejsca (settlement_data, encounter_data, resource_data, tavern_data)
function scr_place_get_data(_place_inst) {
    if (!instance_exists(_place_inst)) return undefined;

    if (variable_instance_exists(_place_inst, "settlement_data")) {
        return _place_inst.settlement_data;
    }
    if (variable_instance_exists(_place_inst, "encounter_data")) {
        return _place_inst.encounter_data;
    }
    if (variable_instance_exists(_place_inst, "resource_data")) {
        return _place_inst.resource_data;
    }
    if (variable_instance_exists(_place_inst, "tavern_data")) {
        return _place_inst.tavern_data;
    }

    return undefined;
}

/// scr_place_has_active_trait(_place_inst)
/// Sprawdza czy miejsce ma aktywny trait (aktywowany i niewyga sły)
function scr_place_has_active_trait(_place_inst) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return false;

    // Sprawdź czy jest trait i czy jest aktywny
    if (!variable_struct_exists(pd, "active_trait")) return false;
    if (pd.active_trait == noone) return false;
    if (!variable_struct_exists(pd, "trait_days_remaining")) return false;

    return pd.trait_days_remaining > 0;
}

/// scr_place_get_active_trait_def(_place_inst)
/// Zwraca definicję aktywnego traitu lub undefined
function scr_place_get_active_trait_def(_place_inst) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return undefined;

    if (!scr_place_has_active_trait(_place_inst)) return undefined;

    // Pobierz definicję traitu z katalogu
    return scr_trait_get_definition(pd.active_trait);
}

/// scr_place_activate_trait(_place_inst, _trait_name)
/// Aktywuje trait na miejscu (rozpoczyna odliczanie dni)
function scr_place_activate_trait(_place_inst, _trait_name) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return false;

    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) return false;

    pd.active_trait = _trait_name;
    pd.trait_days_remaining = variable_struct_exists(def, "activation_days") ? def.activation_days : 1;
    pd.trait_last_activated_day = variable_global_exists("day_counter") ? global.day_counter : 0;

    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";
    show_debug_message("TRAIT ACTIVATED: " + _trait_name + " on " + place_type + " for " + string(pd.trait_days_remaining) + " days");

    return true;
}

/// scr_place_apply_visit_effects(_place_inst, _visitor_source)
/// GŁÓWNA FUNKCJA - aplikuje efekty odwiedzenia miejsca
/// Jeśli miejsce ma aktywny trait - używa efektów traitu
/// Jeśli nie - używa bazowych efektów miejsca
function scr_place_apply_visit_effects(_place_inst, _visitor_source) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";
    var strach_change = 0;
    var ofiara_change = 0;
    var wwsm_change = 0;

    // === SPRAWDŹ CZY JEST AKTYWNY TRAIT ===
    if (scr_place_has_active_trait(_place_inst)) {
        // Trait ZASTĘPUJE bazowe efekty
        var trait_def = scr_place_get_active_trait_def(_place_inst);
        if (!is_undefined(trait_def)) {
            strach_change = variable_struct_exists(trait_def, "strach_bonus") ? trait_def.strach_bonus : 0;
            ofiara_change = variable_struct_exists(trait_def, "ofiara_bonus") ? trait_def.ofiara_bonus : 0;
            wwsm_change = variable_struct_exists(trait_def, "wwsm_bonus") ? trait_def.wwsm_bonus : 0;

            show_debug_message("VISIT: " + _visitor_source + " @ " + place_type + " [TRAIT: " + pd.active_trait + "]");
        }
    } else {
        // Użyj BAZOWYCH efektów miejsca
        if (variable_struct_exists(pd, "base_effects")) {
            strach_change = variable_struct_exists(pd.base_effects, "strach") ? pd.base_effects.strach : 0;
            ofiara_change = variable_struct_exists(pd.base_effects, "ofiara") ? pd.base_effects.ofiara : 0;
            wwsm_change = variable_struct_exists(pd.base_effects, "wwsm") ? pd.base_effects.wwsm : 0;
        }

        // Specjalny przypadek: encounter musi być aktywny aby dawać efekty
        if (place_type == "encounter") {
            var is_active = variable_struct_exists(pd, "active") ? pd.active : false;
            if (!is_active) {
                // Nieaktywny encounter - tylko strach, bez Ofiary i WwSM
                ofiara_change = 0;
                wwsm_change = 0;
            }
        }

        show_debug_message("VISIT: " + _visitor_source + " @ " + place_type + " [BASE EFFECTS]");
    }

    // === APLIKUJ EFEKTY ===
    if (strach_change != 0) {
        scr_add_strach(strach_change, place_type + "_" + _visitor_source);
    }
    if (ofiara_change != 0) {
        scr_add_ofiara(ofiara_change, place_type + "_" + _visitor_source);
    }
    if (wwsm_change != 0) {
        scr_add_wwsm(wwsm_change, place_type + "_" + _visitor_source);
    }

    var effect_str = "";
    if (strach_change != 0) effect_str += (strach_change > 0 ? "+" : "") + string(strach_change) + " Strach ";
    if (ofiara_change != 0) effect_str += (ofiara_change > 0 ? "+" : "") + string(ofiara_change) + " Ofiara ";
    if (wwsm_change != 0) effect_str += (wwsm_change > 0 ? "+" : "") + string(wwsm_change) + " WwSM";
    if (effect_str == "") effect_str = "brak efektów";

    show_debug_message("  -> " + effect_str);
}

// =============================================================================
// STARE FUNKCJE - TERAZ WYWOŁUJĄ UNIWERSALNĄ
// =============================================================================

/// scr_apply_settlement_resources(_settlement, _source)
/// Settlement: domyślnie brak efektów
/// Jeśli ma aktywny trait - trait zastępuje bazowe efekty
function scr_apply_settlement_resources(_settlement, _source) {
    scr_place_apply_visit_effects(_settlement, _source);
}

/// scr_apply_encounter_resources(_encounter, _source)
/// Encounter aktywny: domyślnie +1 Strach, +1 Ofiara
/// Jeśli ma aktywny trait - trait zastępuje bazowe efekty
function scr_apply_encounter_resources(_encounter, _source) {
    scr_place_apply_visit_effects(_encounter, _source);
}

/// scr_apply_source_resources(_source_inst, _visitor_source)
/// Source: domyślnie brak efektów
/// Jeśli ma aktywny trait - trait zastępuje bazowe efekty
function scr_apply_source_resources(_source_inst, _visitor_source) {
    scr_place_apply_visit_effects(_source_inst, _visitor_source);
}

/// scr_apply_tavern_resources_servant - DEPRECATED
/// Karczma reaguje na gracza, nie na NPC. Funkcja zachowana dla kompatybilności.
function scr_apply_tavern_resources_servant(_tavern, _servant) {
    // Karczma nie reaguje na NPC - tylko na gracza
    show_debug_message("WARNING: scr_apply_tavern_resources_servant is deprecated");
}

// =============================================================================
// RESET DZIENNY
// =============================================================================

/// scr_visit_daily_reset()
/// Resetuje listę odwiedzonych miejsc - wywołaj przy zmianie dnia (morning)
/// Zasoby są naliczane raz na dobę PER NPC PER MIEJSCE
function scr_visit_daily_reset() {
    // Reset dla gracza (tylko karczma)
    global.visited_today.tavern_active = false;

    // Reset dla wszystkich NPC (każdy ma własną listę)
    for (var i = 0; i < ds_list_size(global.npcs); i++) {
        var npc = global.npcs[| i];
        if (instance_exists(npc) && variable_instance_exists(npc, "npc_data")) {
            var nd = npc.npc_data;
            if (variable_struct_exists(nd, "visited_places_today")) {
                nd.visited_places_today.settlements = [];
                nd.visited_places_today.encounters = [];
                nd.visited_places_today.sources = [];
                nd.visited_places_today.taverns = [];
            }
        }
    }

    // === TRAITS DAILY TICK - zmniejsz dni pozostałe dla aktywnych traits ===
    scr_traits_daily_tick();

    global.day_counter++;
    show_debug_message("=== VISIT DAILY RESET (Day " + string(global.day_counter) + ") ===");
    show_debug_message("Current resources: Ofiara=" + string(global.ofiara) + ", Strach=" + string(global.strach));
}

// =============================================================================
// POMOCNICZE
// =============================================================================

/// scr_array_contains(array, value)
/// Sprawdza czy array zawiera wartość
function scr_array_contains(_array, _value) {
    for (var i = 0; i < array_length(_array); i++) {
        if (_array[i] == _value) return true;
    }
    return false;
}

/// scr_get_ofiara()
/// Zwraca aktualną wartość Ofiary
function scr_get_ofiara() {
    return global.ofiara;
}

/// scr_get_strach()
/// Zwraca aktualną wartość Strachu
function scr_get_strach() {
    return global.strach;
}

// =============================================================================
// INTEGRACJA Z ENCOUNTERAMI (kompatybilność wsteczna)
// =============================================================================

/// scr_encounter_affect_population(encounter_inst)
/// DEPRECATED - teraz używaj scr_visit_check_and_apply_*
/// Zachowano dla kompatybilności wstecznej
function scr_encounter_affect_population(_enc) {
    // Stara funkcja - nie rób nic, nowy system używa visit
    show_debug_message("WARNING: scr_encounter_affect_population is deprecated, use visit system");
}

// =============================================================================
// NOCNY TICK (uproszczony)
// =============================================================================

/// scr_population_night_tick()
/// DEPRECATED - zasoby nie zanikają naturalnie w nowym systemie
function scr_population_night_tick() {
    show_debug_message("=== NIGHT TICK (no decay in new system) ===");
    show_debug_message("Ofiara: " + string(global.ofiara) + " | Strach: " + string(global.strach));
}

// =============================================================================
// WARUNKI WYGRANEJ / PRZEGRANEJ (do dostosowania później)
// =============================================================================

/// scr_check_win_lose_conditions()
/// Placeholder - do zdefiniowania w przyszłości
function scr_check_win_lose_conditions() {
    // TODO: Zdefiniować nowe warunki wygranej/przegranej
    // Na razie brak automatycznych warunków końca gry
}

// =============================================================================
// STARE FUNKCJE LOGISTYCZNE - USUNIĘTE
// =============================================================================
// Funkcje scr_logistic_susceptibility, scr_logistic_madness_growth,
// scr_logistic_fear_effectiveness, scr_add_myth_faith, scr_add_fear,
// scr_add_madness zostały usunięte w nowym systemie.
// =============================================================================

// === ALIASY DLA KOMPATYBILNOŚCI WSTECZNEJ ===
// (zwracają nowe wartości)

function scr_get_susceptibility_description() {
    return "System uproszczony";
}

function scr_get_fear_zone() {
    if (global.strach < 0) return "low";
    if (global.strach < 10) return "optimal";
    if (global.strach < 20) return "high";
    return "critical";
}

// Dla starego kodu który używał myth_faith (alias do Ofiary - waluty)
#macro global.myth_faith global.ofiara
// global.wwsm jest teraz OSOBNĄ zmienną (współczynnik, nie waluta!)
#macro global.collective_fear global.strach

// =============================================================================
// SYSTEM TRAITS - AKTYWACJA I DZIENNY TICK
// =============================================================================

/// scr_place_has_trait(_place_inst, _trait_name)
/// Sprawdza czy miejsce ma nadany trait (niezależnie czy aktywny)
function scr_place_has_trait(_place_inst, _trait_name) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return false;

    if (!variable_struct_exists(pd, "traits")) return false;
    var traits = pd.traits;

    // Obsługa ds_list
    if (ds_exists(traits, ds_type_list)) {
        for (var i = 0; i < ds_list_size(traits); i++) {
            var t = traits[| i];
            if (is_struct(t) && variable_struct_exists(t, "name")) {
                if (t.name == _trait_name) return true;
            }
        }
    }

    return false;
}

/// scr_place_on_visit_activate_trait(_place_inst)
/// Przy odwiedzeniu miejsca - jeśli ma nadany trait, aktywuj go
/// Wywoływane automatycznie przy każdej wizycie
function scr_place_on_visit_activate_trait(_place_inst) {
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    // Sprawdź czy miejsce ma jakiekolwiek nadane traits
    if (!variable_struct_exists(pd, "traits")) return;
    var traits = pd.traits;

    if (!ds_exists(traits, ds_type_list)) return;
    if (ds_list_size(traits) == 0) return;

    // Weź pierwszy trait z listy i aktywuj go
    var first_trait = traits[| 0];
    if (!is_struct(first_trait)) return;
    if (!variable_struct_exists(first_trait, "name")) return;

    var trait_name = first_trait.name;

    // Aktywuj trait (odnów czas trwania)
    scr_place_activate_trait(_place_inst, trait_name);
}

/// scr_traits_daily_tick()
/// Wywoływane raz dziennie - zmniejsza dni pozostałe dla aktywnych traits
/// Wywołaj w scr_visit_daily_reset() lub osobno
function scr_traits_daily_tick() {
    show_debug_message("=== TRAITS DAILY TICK ===");

    // Settlements
    if (variable_global_exists("settlements") && ds_exists(global.settlements, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.settlements); i++) {
            var place = global.settlements[| i];
            scr_place_trait_tick(place);
        }
    }

    // Encounters
    if (variable_global_exists("encounters") && ds_exists(global.encounters, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.encounters); i++) {
            var place = global.encounters[| i];
            scr_place_trait_tick(place);
        }
    }

    // Resources (sources)
    if (variable_global_exists("resources") && ds_exists(global.resources, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.resources); i++) {
            var place = global.resources[| i];
            scr_place_trait_tick(place);
        }
    }

    // Taverns
    if (variable_global_exists("taverns") && ds_exists(global.taverns, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.taverns); i++) {
            var place = global.taverns[| i];
            scr_place_trait_tick(place);
        }
    }
}

/// scr_place_trait_tick(_place_inst)
/// Zmniejsza dni pozostałe dla aktywnego traitu miejsca
function scr_place_trait_tick(_place_inst) {
    if (!instance_exists(_place_inst)) return;

    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    if (!variable_struct_exists(pd, "trait_days_remaining")) return;
    if (pd.trait_days_remaining <= 0) return;

    pd.trait_days_remaining -= 1;

    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";
    var trait_name = variable_struct_exists(pd, "active_trait") ? pd.active_trait : "none";

    if (pd.trait_days_remaining <= 0) {
        pd.active_trait = noone;
        show_debug_message("TRAIT EXPIRED: " + trait_name + " on " + place_type);
    } else {
        show_debug_message("TRAIT TICK: " + trait_name + " on " + place_type + " - " + string(pd.trait_days_remaining) + " dni pozostało");
    }
}

/// scr_visit_check_and_apply_npc_v2(_npc_inst, _place_inst)
/// Nowa wersja - uniwersalna dla wszystkich typów miejsc
/// Automatycznie aktywuje trait przy odwiedzeniu
function scr_visit_check_and_apply_npc_v2(_npc_inst, _place_inst) {
    if (!instance_exists(_place_inst)) return false;
    if (!instance_exists(_npc_inst)) return false;
    if (!variable_instance_exists(_npc_inst, "npc_data")) return false;

    var nd = _npc_inst.npc_data;
    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return false;

    var place_id = _place_inst.id;
    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";

    // Upewnij się że NPC ma strukturę visited_places_today
    if (!variable_struct_exists(nd, "visited_places_today")) {
        nd.visited_places_today = {
            settlements: [],
            encounters: [],
            sources: [],
            taverns: []
        };
    }

    // Sprawdź czy TEN NPC już dziś odwiedził to miejsce
    var visited_list_name = place_type + "s"; // settlements, encounters, sources, taverns
    if (place_type == "source") visited_list_name = "sources";

    if (!variable_struct_exists(nd.visited_places_today, visited_list_name)) {
        nd.visited_places_today[$ visited_list_name] = [];
    }

    var visited_list = nd.visited_places_today[$ visited_list_name];
    if (scr_array_contains(visited_list, place_id)) {
        return false; // Już odwiedzone dziś
    }

    // Zaznacz jako odwiedzone
    array_push(visited_list, place_id);
    nd.visited_places_today[$ visited_list_name] = visited_list;

    // === AKTYWUJ TRAIT JEŚLI MIEJSCE MA NADANY ===
    scr_place_on_visit_activate_trait(_place_inst);

    // === APLIKUJ EFEKTY WIZYTY ===
    scr_place_apply_visit_effects(_place_inst, "npc_" + string(_npc_inst.id));

    return true;
}
