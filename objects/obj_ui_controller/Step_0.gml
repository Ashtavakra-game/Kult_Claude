/// obj_ui_controller - Step Event

// Zamknij panel na ESC
if (keyboard_check_pressed(vk_escape) && ui_active_panel != noone) {
    ui_close_panel();
}

// === OBSŁUGA PANELU KARCZMY ===
if (ui_active_panel == "tavern" && instance_exists(ui_selected_target)) {
    scr_ui_tavern_panel_input(ui_selected_target);
}

// === OBSŁUGA PANELU LOKACJI ===
if (ui_active_panel == "location" && instance_exists(ui_selected_target)) {
    scr_ui_location_panel_input(ui_selected_target);
}

// Detekcja kliknięcia (tylko gdy UI nieaktywne)
if (mouse_check_button_pressed(mb_left) && !ui_is_active()) {
    
    var mx = mouse_x;
    var my = mouse_y;
    
    // === PRIORYTET 1: Sprawdź KARCZMĘ ===
    // Używamy obj_tavern bo obj_karczma jest jego dzieckiem
    var tavern = instance_position(mx, my, obj_tavern);
    if (tavern != noone) {
        show_debug_message("UI: Clicked on tavern " + object_get_name(tavern.object_index));
        scr_ui_open_tavern_panel(tavern);
        exit;
    }
    
    // === PRIORYTET 2: Sprawdź SETTLEMENTS (dla systemu cech) ===
    var settlement = instance_position(mx, my, obj_settlement_parent);
    if (settlement != noone) {
        show_debug_message("UI: Clicked on settlement " + object_get_name(settlement.object_index));
        scr_ui_open_location_panel(settlement);
        exit;
    }
    
    // === PRIORYTET 3: Sprawdź ENCOUNTERY ===
    var enc = instance_position(mx, my, obj_encounter_parent);
    if (enc != noone) {
        // Sprawdź czy ma encounter_data PRZED otwarciem panelu
        if (variable_instance_exists(enc, "encounter_data") && !is_undefined(enc.encounter_data)) {
            show_debug_message("UI: Opening encounter panel for " + object_get_name(enc.object_index));
            ui_open_encounter_panel(enc);
        } else {
            show_debug_message("UI WARNING: Object has no encounter_data: " + object_get_name(enc.object_index));
        }
    }
}