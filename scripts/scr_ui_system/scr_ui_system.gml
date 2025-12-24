
/// Inicjalizacja systemu UI - wywołaj w o_game Create PRZED innymi systemami
function scr_ui_system_init() {
    // Upewnij się że zmienna globalna istnieje
    if (!variable_global_exists("ui_blocking_input")) {
        global.ui_blocking_input = false;
    }
    show_debug_message("UI SYSTEM: Initialized, blocking=" + string(global.ui_blocking_input));
}

/// Otwórz panel dla encountera
function ui_open_encounter_panel(_encounter) {
    if (!instance_exists(_encounter)) return;
    
    var ctrl = instance_find(obj_ui_controller, 0);
    if (!instance_exists(ctrl)) {
        show_debug_message("UI ERROR: obj_ui_controller not found!");
        return;
    }
    
    ctrl.ui_selected_target = _encounter;
    ctrl.ui_active_panel = "encounter";
    global.ui_blocking_input = true;
}

/// Zamknij aktywny panel
function ui_close_panel() {
    var ctrl = instance_find(obj_ui_controller, 0);
    if (!instance_exists(ctrl)) {
        // Nawet bez kontrolera, odblokuj input
        if (variable_global_exists("ui_blocking_input")) {
            global.ui_blocking_input = false;
        }
        return;
    }
    
    ctrl.ui_active_panel = noone;
    ctrl.ui_selected_target = noone;
    global.ui_blocking_input = false;
}

/// Sprawdź czy UI jest aktywne - BEZPIECZNA WERSJA
function ui_is_active() {
    // Sprawdź czy zmienna globalna istnieje
    if (!variable_global_exists("ui_blocking_input")) {
        // Jeśli nie istnieje, utwórz ją i zwróć false
        global.ui_blocking_input = false;
        return false;
    }
    return global.ui_blocking_input;
}