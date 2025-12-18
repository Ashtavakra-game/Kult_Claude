/// obj_ui_controller - Step Event

// Zamknij panel na ESC
if (keyboard_check_pressed(vk_escape) && ui_active_panel != noone) {
    ui_close_panel();
}

// Detekcja kliknięcia (tylko gdy UI nieaktywne)
if (mouse_check_button_pressed(mb_left) && !ui_is_active()) {
    
    // Pozycja myszy w świecie gry
    var mx = mouse_x;
    var my = mouse_y;
    // Sprawdź encountery
    var enc = instance_position(mx, my, obj_encounter_parent);
    if (enc != noone) {
			show_debug_message("Dane: " + string(enc));
        ui_open_encounter_panel(enc);
    }
}