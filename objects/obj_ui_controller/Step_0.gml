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

// === PPM - OTWÓRZ PANEL TRAITS DLA DOWOLNEGO MIEJSCA ===
if (mouse_check_button_pressed(mb_right)) {
    var mx = mouse_x;
    var my = mouse_y;

    show_debug_message("UI: PPM detected at (" + string(mx) + "," + string(my) + ") blocking=" + string(global.ui_blocking_input));

    if (!global.ui_blocking_input) {
        var clicked = noone;
        var click_radius = 40;  // promień wykrywania kliknięcia
        var best_dist = click_radius;

        // Sprawdź resources
        var res = instance_nearest(mx, my, obj_resource_parent);
        if (res != noone && point_distance(mx, my, res.x, res.y) < best_dist) {
            best_dist = point_distance(mx, my, res.x, res.y);
            clicked = res;
        }

        // Sprawdź encounters
        var enc = instance_nearest(mx, my, obj_encounter_parent);
        if (enc != noone && point_distance(mx, my, enc.x, enc.y) < best_dist) {
            best_dist = point_distance(mx, my, enc.x, enc.y);
            clicked = enc;
        }

        // Sprawdź tavern
        var tav = instance_nearest(mx, my, obj_tavern);
        if (tav != noone && point_distance(mx, my, tav.x, tav.y) < best_dist) {
            best_dist = point_distance(mx, my, tav.x, tav.y);
            clicked = tav;
        }

        // Sprawdź settlements
        var set = instance_nearest(mx, my, obj_settlement_parent);
        if (set != noone && point_distance(mx, my, set.x, set.y) < best_dist) {
            best_dist = point_distance(mx, my, set.x, set.y);
            clicked = set;
        }

        show_debug_message("  clicked=" + string(clicked) + " dist=" + string(best_dist));

        if (clicked != noone) {
            show_debug_message("UI: Opening traits panel for " + object_get_name(clicked.object_index) + " id=" + string(clicked.id));
            scr_ui_open_location_panel(clicked);
        }
    }
}


