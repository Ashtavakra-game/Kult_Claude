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

// Kliknięcia na obiekty są teraz obsługiwane przez eventy Mouse_0
// w obj_settlement_parent, obj_tavern i obj_encounter_parent


