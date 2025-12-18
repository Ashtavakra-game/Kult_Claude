    // Pozycja myszy w świecie gry
    var mx = mouse_x;
    var my = mouse_y;
    // Sprawdź encountery
    var enc = instance_position(mx, my, obj_encounter_parent);

	show_debug_message("Dane: " + string(enc));
    ui_open_encounter_panel(enc);
 