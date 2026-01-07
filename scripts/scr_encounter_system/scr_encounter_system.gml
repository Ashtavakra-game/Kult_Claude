/// =============================================================================
/// SCR_ENCOUNTER_SYSTEM - System zarządzania encounterami
/// =============================================================================
/// Obsługuje aktywność, timery, bonusy i traits encounterów
/// =============================================================================

// =============================================================================
// SPRAWDZANIE AKTYWNOŚCI
// =============================================================================

/// scr_encounter_is_active(_enc)
/// Sprawdza czy encounter jest aktywny
/// @param _enc - instancja encountera
/// @return bool - czy jest aktywny
function scr_encounter_is_active(_enc) {
    if (!instance_exists(_enc)) return false;
    if (!variable_instance_exists(_enc, "encounter_data")) return false;
    if (is_undefined(_enc.encounter_data)) return false;

    return _enc.encounter_data.active;
}

// =============================================================================
// AKTYWACJA ENCOUNTERA
// =============================================================================

/// scr_encounter_activate(_enc)
/// Aktywuje encounter (po wizycie gracza/sługi)
/// @param _enc - instancja encountera
function scr_encounter_activate(_enc) {
    if (!instance_exists(_enc)) return;
    if (!variable_instance_exists(_enc, "encounter_data")) return;

    var ed = _enc.encounter_data;

    ed.active = true;
    ed.days_remaining = ed.activation_days;

    // Zapisz dzień aktywacji (jeśli istnieje global.day_counter)
    if (variable_global_exists("day_counter")) {
        ed.last_activated_day = global.day_counter;
    }

    show_debug_message("ENCOUNTER: Aktywowany " + string(ed.typ) + " na " + string(ed.activation_days) + " dni");
}

/// scr_encounter_deactivate(_enc)
/// Dezaktywuje encounter
/// @param _enc - instancja encountera
function scr_encounter_deactivate(_enc) {
    if (!instance_exists(_enc)) return;
    if (!variable_instance_exists(_enc, "encounter_data")) return;

    var ed = _enc.encounter_data;
    ed.active = false;
    ed.days_remaining = 0;

    show_debug_message("ENCOUNTER: Dezaktywowany " + string(ed.typ));
}

// =============================================================================
// TICK DZIENNY
// =============================================================================

/// scr_encounter_daily_tick()
/// Wywoływane raz dziennie - zmniejsza days_remaining i dezaktywuje wygasłe
function scr_encounter_daily_tick() {
    if (is_undefined(global.encounters)) return;

    show_debug_message("=== ENCOUNTER DAILY TICK ===");

    for (var i = 0; i < ds_list_size(global.encounters); i++) {
        var enc = global.encounters[| i];
        if (!instance_exists(enc)) continue;
        if (!variable_instance_exists(enc, "encounter_data")) continue;

        var ed = enc.encounter_data;

        // Tylko aktywne encountery tracą dni
        if (ed.active) {
            ed.days_remaining -= 1;

            show_debug_message("  " + string(ed.typ) + ": pozostało " + string(ed.days_remaining) + " dni");

            // Dezaktywuj jeśli wyczerpał czas
            if (ed.days_remaining <= 0) {
                scr_encounter_deactivate(enc);
            }
        }
    }
}

// =============================================================================
// OBSŁUGA WIZYTY
// =============================================================================

/// scr_encounter_on_visit(_enc, _visitor, _is_sluga)
/// Obsługuje wizytę encountera przez gracza lub NPC
/// @param _enc - instancja encountera
/// @param _visitor - instancja odwiedzającego (Player lub NPC)
/// @param _is_sluga - czy odwiedzający jest sługą (odnawia encounter)
/// @return bool - czy wizyta była skuteczna (encounter był aktywny)
function scr_encounter_on_visit(_enc, _visitor, _is_sluga) {
    if (!instance_exists(_enc)) return false;
    if (!variable_instance_exists(_enc, "encounter_data")) return false;

    var ed = _enc.encounter_data;

    // Odnowienie przez sługę lub gracza
    if (_is_sluga || object_get_parent(_visitor.object_index) == Player || _visitor.object_index == Player) {
        scr_encounter_activate(_enc);
    }

    // Efekty tylko gdy aktywny
    if (!ed.active) {
        show_debug_message("ENCOUNTER: " + string(ed.typ) + " nieaktywny - brak efektów");
        return false;
    }

    // === BONUS WwSM (Wiara w Stare Mity - współczynnik) ===
    if (variable_struct_exists(ed, "wsm_bonus") && ed.wsm_bonus != 0) {
        scr_add_wwsm(ed.wsm_bonus, "encounter_" + string(ed.typ));
    }

    // === BONUS OFIARA (waluta) ===
    var ofiara_val = 0;
    if (variable_struct_exists(ed, "ofiara_bonus")) {
        ofiara_val = ed.ofiara_bonus;
    } else if (variable_struct_exists(ed, "wsm_bonus")) {
        // Legacy fallback: jeśli nie ma ofiara_bonus, użyj wsm_bonus
        ofiara_val = ed.wsm_bonus;
    }
    if (ofiara_val > 0) {
        scr_add_ofiara(ofiara_val, "encounter_" + string(ed.typ));
    }

    // === GLOBALNY STRACH ===
    if (ed.global_fear_bonus != 0) {
        scr_add_strach(ed.global_fear_bonus, "encounter_" + string(ed.typ));
    }

    // === TRAITS DLA NPC ===
    if (array_length(ed.traits) > 0 && instance_exists(_visitor)) {
        scr_encounter_apply_traits(_enc, _visitor);
    }

    return true;
}

// =============================================================================
// APLIKACJA TRAITS
// =============================================================================

/// scr_encounter_apply_traits(_enc, _npc)
/// Aplikuje traits z encountera na NPC
/// @param _enc - instancja encountera
/// @param _npc - instancja NPC
function scr_encounter_apply_traits(_enc, _npc) {
    if (!instance_exists(_enc) || !instance_exists(_npc)) return;
    if (!variable_instance_exists(_enc, "encounter_data")) return;
    if (!variable_instance_exists(_npc, "npc_data")) return;

    var ed = _enc.encounter_data;
    var nd = _npc.npc_data;

    // Sprawdź czy NPC ma strukturę modifiers
    if (!variable_struct_exists(nd, "modifiers")) {
        nd.modifiers = {};
    }

    // Sprawdź czy NPC ma strukturę encounter_traits (tymczasowe modyfikatory)
    if (!variable_struct_exists(nd, "encounter_traits")) {
        nd.encounter_traits = [];
    }

    for (var i = 0; i < array_length(ed.traits); i++) {
        var trait = ed.traits[i];

        // Struktura trait: { cecha: "strach", wartosc: 5, czas_trwania: 3 }
        var cecha = trait.cecha;
        var wartosc = trait.wartosc;
        var czas_trwania = variable_struct_exists(trait, "czas_trwania") ? trait.czas_trwania : 0;

        // Aplikuj modyfikator
        if (variable_struct_exists(nd.modifiers, cecha)) {
            nd.modifiers[$ cecha] += wartosc;
        } else {
            nd.modifiers[$ cecha] = wartosc;
        }

        // Jeśli tymczasowy - zapisz do usunięcia później
        if (czas_trwania > 0) {
            array_push(nd.encounter_traits, {
                cecha: cecha,
                wartosc: wartosc,
                dni_pozostalo: czas_trwania
            });
        }

        show_debug_message("ENCOUNTER TRAIT: NPC " + string(_npc.id) + " otrzymał " + cecha + " +" + string(wartosc) +
            (czas_trwania > 0 ? " na " + string(czas_trwania) + " dni" : " (permanentnie)"));
    }
}

/// scr_encounter_traits_daily_tick(_npc)
/// Tick dzienny dla tymczasowych traits NPC z encounterów
/// @param _npc - instancja NPC
function scr_encounter_traits_daily_tick(_npc) {
    if (!instance_exists(_npc)) return;
    if (!variable_instance_exists(_npc, "npc_data")) return;

    var nd = _npc.npc_data;
    if (!variable_struct_exists(nd, "encounter_traits")) return;

    // Od końca, bo będziemy usuwać
    for (var i = array_length(nd.encounter_traits) - 1; i >= 0; i--) {
        var et = nd.encounter_traits[i];
        et.dni_pozostalo -= 1;

        if (et.dni_pozostalo <= 0) {
            // Usuń modyfikator
            if (variable_struct_exists(nd.modifiers, et.cecha)) {
                nd.modifiers[$ et.cecha] -= et.wartosc;
            }
            array_delete(nd.encounter_traits, i, 1);
            show_debug_message("ENCOUNTER TRAIT EXPIRED: NPC " + string(_npc.id) + " stracił " + et.cecha + " -" + string(et.wartosc));
        }
    }
}

// =============================================================================
// TICK DZIENNY DLA WSZYSTKICH NPC (traits)
// =============================================================================

/// scr_encounter_npc_traits_daily_tick()
/// Wywoływane raz dziennie - aktualizuje tymczasowe traits dla wszystkich NPC
function scr_encounter_npc_traits_daily_tick() {
    if (is_undefined(global.npcs)) return;

    for (var i = 0; i < ds_list_size(global.npcs); i++) {
        var npc = global.npcs[| i];
        if (instance_exists(npc)) {
            scr_encounter_traits_daily_tick(npc);
        }
    }
}

// =============================================================================
// POMOCNICZE FUNKCJE
// =============================================================================

/// scr_encounter_get_status_string(_enc)
/// Zwraca string ze statusem encountera (do UI)
/// @param _enc - instancja encountera
/// @return string - status
function scr_encounter_get_status_string(_enc) {
    if (!instance_exists(_enc)) return "Nieznany";
    if (!variable_instance_exists(_enc, "encounter_data")) return "Brak danych";

    var ed = _enc.encounter_data;

    if (ed.active) {
        return "Aktywny (" + string(ed.days_remaining) + " dni)";
    } else {
        return "Nieaktywny";
    }
}

/// scr_encounter_add_trait(_enc, _cecha, _wartosc, _czas_trwania)
/// Dodaje trait do encountera (do użycia przy konfiguracji)
/// @param _enc - instancja encountera
/// @param _cecha - nazwa cechy (np. "strach", "podatnosc")
/// @param _wartosc - wartość modyfikatora
/// @param _czas_trwania - ile dni trwa (0 = permanentnie)
function scr_encounter_add_trait(_enc, _cecha, _wartosc, _czas_trwania) {
    if (!instance_exists(_enc)) return;
    if (!variable_instance_exists(_enc, "encounter_data")) return;

    var ed = _enc.encounter_data;

    array_push(ed.traits, {
        cecha: _cecha,
        wartosc: _wartosc,
        czas_trwania: _czas_trwania
    });

    show_debug_message("ENCOUNTER CONFIG: Dodano trait " + _cecha + " (" + string(_wartosc) + ") do " + string(ed.typ));
}
