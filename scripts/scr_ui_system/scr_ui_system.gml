/// scr_ui_system.gml

/// Otwórz panel dla encountera
function ui_open_encounter_panel(_encounter) {
    if (!instance_exists(_encounter)) return;
    
    var ctrl = instance_find(obj_ui_controller, 0);
    if (!instance_exists(ctrl)) return;
    
    ctrl.ui_selected_target = _encounter;
    ctrl.ui_active_panel = "encounter";
    global.ui_blocking_input = true;
}

/// Zamknij aktywny panel
function ui_close_panel() {
    var ctrl = instance_find(obj_ui_controller, 0);
    if (!instance_exists(ctrl)) return;
    
    ctrl.ui_active_panel = noone;
    ctrl.ui_selected_target = noone;
    global.ui_blocking_input = false;
}

/// Sprawdź czy UI jest aktywne
function ui_is_active() {
    return global.ui_blocking_input;
}