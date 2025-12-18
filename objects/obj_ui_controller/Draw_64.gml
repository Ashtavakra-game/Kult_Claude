/// obj_ui_controller - Draw GUI Event

if (ui_active_panel == "encounter" && instance_exists(ui_selected_target)) {
    _draw_encounter_panel(ui_selected_target);
}

/// Funkcja rysująca panel encountera
function _draw_encounter_panel(_enc) {
    var ed = _enc.encounter_data;
    if (is_undefined(ed)) return;
    
    // Wymiary panelu
    var panel_w = 300;
    var panel_h = 200;
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
    
    // === NAGŁÓWEK (sprite + tekst) ===
    // Jeśli masz sprite ikony encountera:
    // draw_sprite(spr_encounter_icon, 0, panel_x + 20, panel_y + 20);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(panel_x + panel_w/2, panel_y + 15, "ENCOUNTER");
    
    // === TREŚĆ ===
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    
    var txt_x = panel_x + 20;
    var txt_y = panel_y + 50;
    var line_h = 20;
    
    if (variable_struct_exists(ed, "typ")) {
        draw_text(txt_x, txt_y, "Typ: " + string(ed.typ));
        txt_y += line_h;
    }
    
    if (variable_struct_exists(ed, "sila")) {
        draw_text(txt_x, txt_y, "Siła: " + string(ed.sila));
        txt_y += line_h;
    }
    
    if (variable_struct_exists(ed, "efekt")) {
        draw_text(txt_x, txt_y, "Efekt: " + string(ed.efekt));
        txt_y += line_h;
    }
    
    // === PRZYCISK ZAMKNIĘCIA ===
    var btn_w = 80;
    var btn_h = 30;
    var btn_x = panel_x + (panel_w - btn_w) / 2;
    var btn_y = panel_y + panel_h - 45;
    
    // Sprawdź hover
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
    
    // Kliknięcie przycisku
    if (hover && mouse_check_button_pressed(mb_left)) {
        ui_close_panel();
    }
    
    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

/*
## Struktura plików
```
📁 Scripts/UI/
├── scr_ui_system.gml      // główne funkcje UI
├── scr_ui_panels.gml      // definicje paneli
└── scr_ui_buttons.gml     // system przycisków

📁 Objects/UI/
├── obj_ui_controller      // główny kontroler
└── obj_ui_button          // opcjonalnie - obiekt przycisku

*/