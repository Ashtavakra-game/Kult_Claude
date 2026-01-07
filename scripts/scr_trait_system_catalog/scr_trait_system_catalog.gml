/// =============================================================================
/// BORUTA - KATALOG CECH LOKACJI (TRAITS)
/// =============================================================================
/// Traits to cechy NADAWANE miejscom, które ZASTĘPUJĄ ich bazowe efekty.
/// Każde miejsce ma bazowe efekty (np. settlement: -1 strach).
/// Aktywny trait nadpisuje te bazowe efekty swoimi własnymi.
///
/// System jest uniwersalny - traits można nadać do:
/// - Settlement (osady)
/// - Encounter (miejsca mocy)
/// - Source (zasoby)
/// - Tavern (karczma)
/// =============================================================================

// =============================================================================
// INICJALIZACJA KATALOGU
// =============================================================================

/// scr_trait_catalog_init()
/// Tworzy katalog wszystkich dostępnych cech
function scr_trait_catalog_init() {

    // === PLOTKA ===
    // Główny i jedyny trait w grze
    // Raz na dobę przy odwiedzeniu: +1 Strach
    // Anuluje bazowe cechy miejsca
    // Aktywacja na 1 dzień (trzeba ciągle odnawiać)
    ds_map_add(global.trait_catalog, "plotka", {
        name: "plotka",
        display_name: "Plotka",
        description: "Szeptane opowieści budzą niepokój w sercach...",
        type: "dynamic",
        base_cost: 2,                   // koszt nadania w Ofierze
        valid_locations: ["all"],       // można nadać wszędzie
        prerequisite: "",

        // === CZAS TRWANIA AKTYWACJI ===
        activation_days: 1,             // trait aktywny przez 1 dzień po odwiedzeniu

        // === EFEKTY (zastępują bazowe cechy miejsca) ===
        // Odwiedzenie aktywnego traitu:
        strach_bonus: 1,                // +1 Strach przy odwiedzeniu
        ofiara_bonus: 0,                // brak bonusu do Ofiary

        // Trait NIE daje bazowych efektów miejsca (to jest kluczowe!)
        // Np. settlement z Plotką nie daje już -1 Strach, tylko +1 Strach
        overrides_base_effects: true,

        // Modyfikatory NPC (gdy przebywają w miejscu z tym traitem)
        npc_mods: {
            pracowitosc: 0,
            roztargnienie: 5,
            ciekawosc: 10,
            podatnosc: 5,
            towarzyskosc: 0,
            wanderlust: 0
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
