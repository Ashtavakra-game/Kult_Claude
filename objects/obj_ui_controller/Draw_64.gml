/// obj_ui_controller - Draw GUI Event

// === PANEL KARCZMY ===
if (ui_active_panel == "tavern" && instance_exists(ui_selected_target)) {
    var panel_x = (display_get_gui_width() - TAVERN_UI_PANEL_WIDTH) / 2;
    var panel_y = (display_get_gui_height() - TAVERN_UI_PANEL_HEIGHT) / 2;
    scr_ui_draw_tavern_panel(ui_selected_target, panel_x, panel_y);
    scr_ui_draw_negotiation_result(panel_x, panel_y);
}

// === PANEL LOKACJI (SYSTEM CECH) ===
if (ui_active_panel == "location" && instance_exists(ui_selected_target)) {
    var panel_x = (display_get_gui_width() - TRAIT_UI_PANEL_WIDTH) / 2;
    var panel_y = (display_get_gui_height() - TRAIT_UI_PANEL_HEIGHT) / 2;
    scr_ui_draw_location_panel(ui_selected_target, panel_x, panel_y);
}

// === PANEL ENCOUNTERA ===
if (ui_active_panel == "encounter" && instance_exists(ui_selected_target)) {
    _draw_encounter_panel(ui_selected_target);
}

// === PASKI EKONOMII (WSM + EC) ===
scr_ui_draw_economy_bars(10, 10, 180, 52);

/// Funkcja rysująca panel encountera (POPRAWIONA)
function _draw_encounter_panel(_enc) {
    // === BEZPIECZNE SPRAWDZENIE ===
    if (!instance_exists(_enc)) {
        ui_close_panel();
        return;
    }
    
    // Sprawdź czy obiekt ma encounter_data
    if (!variable_instance_exists(_enc, "encounter_data")) {
        show_debug_message("UI WARNING: Object " + object_get_name(_enc.object_index) + " has no encounter_data!");
        ui_close_panel();
        return;
    }
    
    var ed = _enc.encounter_data;
    if (is_undefined(ed)) {
        ui_close_panel();
        return;
    }
    
    // Wymiary panelu
    var panel_w = 300;
    var panel_h = 220;
    var panel_x = (display_get_gui_width() - panel_w) / 2;
    var panel_y = (display_get_gui_height() - panel_h) / 2;
    
    // === TŁO PANELU ===
    draw_set_alpha(0.9);
    draw_set_color(c_black);
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
    draw_set_alpha(1);
    
    // === RAMKA ===
    draw_set_color(c_white);
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);
    
    // === NAGŁÓWEK ===
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    
    var title = "ENCOUNTER";
    if (variable_struct_exists(ed, "typ") && ed.typ != "") {
        title = string(ed.typ);
    }
    draw_text(panel_x + panel_w/2, panel_y + 15, title);
    
    // === TREŚĆ ===
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    
    var txt_x = panel_x + 20;
    var txt_y = panel_y + 50;
    var line_h = 22;
    
    // Typ
    if (variable_struct_exists(ed, "typ")) {
        draw_text(txt_x, txt_y, "Typ: " + string(ed.typ));
        txt_y += line_h;
    }
    
    // Siła
    if (variable_struct_exists(ed, "sila")) {
        draw_text(txt_x, txt_y, "Sila: " + string(ed.sila));
        txt_y += line_h;
    }
    
    // Zasięg
    if (variable_struct_exists(ed, "zasieg")) {
        draw_text(txt_x, txt_y, "Zasieg: " + string(ed.zasieg));
        txt_y += line_h;
    }
    
    // Efekt
    if (variable_struct_exists(ed, "efekt")) {
        draw_text(txt_x, txt_y, "Efekt: " + string(ed.efekt));
        txt_y += line_h;
    }
    
    // Akumulacja strachu
    if (variable_struct_exists(ed, "akumulacja_strachu")) {
        draw_set_color(c_red);
        draw_text(txt_x, txt_y, "Strach: " + string(ed.akumulacja_strachu));
        txt_y += line_h;
    }
    
    // === PRZYCISK ZAMKNIĘCIA ===
    var btn_w = 80;
    var btn_h = 30;
    var btn_x = panel_x + (panel_w - btn_w) / 2;
    var btn_y = panel_y + panel_h - 45;
    
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var hover = point_in_rectangle(mx, my, btn_x, btn_y, btn_x + btn_w, btn_y + btn_h);
    
    draw_set_color(hover ? c_gray : c_dkgray);
    draw_rectangle(btn_x, btn_y, btn_x + btn_w, btn_y + btn_h, false);
    draw_set_color(c_white);
    draw_rectangle(btn_x, btn_y, btn_x + btn_w, btn_y + btn_h, true);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(btn_x + btn_w/2, btn_y + btn_h/2, "Zamknij");
    
    if (hover && mouse_check_button_pressed(mb_left)) {
        ui_close_panel();
    }
    
    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}