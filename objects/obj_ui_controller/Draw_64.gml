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

// === PASKI EKONOMII (Ofiara, WwSM, Strach, EC) ===
scr_ui_draw_economy_bars(10, 10, 180, 68);

// === NUMER DNIA (prawy górny róg) ===
draw_set_color(c_white);
draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_text(display_get_gui_width() - 10, 10, "Dzien: " + string(global.day_counter));
draw_set_halign(fa_left);

// === OVERLAY KOŃCA GRY ===
scr_ui_draw_game_state_overlay();

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
    
    // Wymiary panelu (powiększone dla nowych informacji + przycisk Odnów)
    var panel_w = 300;
    var panel_h = 380;
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
    var line_h = 20;

    // Typ
    if (variable_struct_exists(ed, "typ")) {
        draw_text(txt_x, txt_y, "Typ: " + string(ed.typ));
        txt_y += line_h;
    }

    // === STATUS AKTYWNOŚCI ===
    if (variable_struct_exists(ed, "active")) {
        if (ed.active) {
            draw_set_color(c_lime);
            var status_txt = "Status: AKTYWNY";
            if (variable_struct_exists(ed, "days_remaining")) {
                status_txt += " (" + string(ed.days_remaining) + " dni)";
            }
            draw_text(txt_x, txt_y, status_txt);
        } else {
            draw_set_color(c_gray);
            draw_text(txt_x, txt_y, "Status: NIEAKTYWNY");
        }
        txt_y += line_h;
        draw_set_color(c_white);
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

    // === BONUSY ===
    // Ofiara (waluta)
    var ofiara_val = 0;
    if (variable_struct_exists(ed, "ofiara_bonus")) {
        ofiara_val = ed.ofiara_bonus;
    } else if (variable_struct_exists(ed, "wsm_bonus")) {
        ofiara_val = ed.wsm_bonus; // legacy fallback
    }
    if (ofiara_val > 0) {
        draw_set_color(c_yellow);
        draw_text(txt_x, txt_y, "Ofiara: +" + string(ofiara_val));
        txt_y += line_h;
    }

    // WwSM (współczynnik)
    if (variable_struct_exists(ed, "wsm_bonus") && ed.wsm_bonus != 0) {
        draw_set_color(c_aqua);
        var wsm_sign = ed.wsm_bonus > 0 ? "+" : "";
        draw_text(txt_x, txt_y, "WwSM: " + wsm_sign + string(ed.wsm_bonus));
        txt_y += line_h;
    }

    // Strach (współczynnik)
    if (variable_struct_exists(ed, "global_fear_bonus") && ed.global_fear_bonus != 0) {
        draw_set_color(c_orange);
        var fear_sign = ed.global_fear_bonus > 0 ? "+" : "";
        draw_text(txt_x, txt_y, "Strach: " + fear_sign + string(ed.global_fear_bonus));
        txt_y += line_h;
    }

    // Akumulacja strachu (lokalny)
    if (variable_struct_exists(ed, "akumulacja_strachu") && ed.akumulacja_strachu > 0) {
        draw_set_color(c_red);
        draw_text(txt_x, txt_y, "Strach lokalny: " + string(ed.akumulacja_strachu));
        txt_y += line_h;
    }

    // === TRAITS ===
    if (variable_struct_exists(ed, "traits") && array_length(ed.traits) > 0) {
        draw_set_color(c_purple);
        draw_text(txt_x, txt_y, "Cechy:");
        txt_y += line_h;
        for (var i = 0; i < array_length(ed.traits); i++) {
            var t = ed.traits[i];
            var trait_txt = "  " + t.cecha + " +" + string(t.wartosc);
            if (variable_struct_exists(t, "czas_trwania") && t.czas_trwania > 0) {
                trait_txt += " (" + string(t.czas_trwania) + "d)";
            }
            draw_text(txt_x, txt_y, trait_txt);
            txt_y += line_h;
        }
    }

    draw_set_color(c_white);

    // === SPRAWDŹ CZY GRACZ W ZASIĘGU ===
    var player_in_range = false;
    if (instance_exists(Player)) {
        var dist_to_player = point_distance(Player.x, Player.y, _enc.x, _enc.y);
        var enc_range = variable_struct_exists(ed, "zasieg") ? ed.zasieg : 120;
        player_in_range = (dist_to_player <= enc_range);
    }

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // === PRZYCISK ODNÓW (tylko gdy gracz w zasięgu) ===
    if (player_in_range) {
        var renew_btn_w = 100;
        var renew_btn_h = 30;
        var renew_btn_x = panel_x + (panel_w - renew_btn_w) / 2;
        var renew_btn_y = panel_y + panel_h - 85;

        var renew_hover = point_in_rectangle(mx, my, renew_btn_x, renew_btn_y, renew_btn_x + renew_btn_w, renew_btn_y + renew_btn_h);

        // Kolor przycisku - zielony dla aktywnego
        draw_set_color(renew_hover ? c_green : c_dkgray);
        draw_rectangle(renew_btn_x, renew_btn_y, renew_btn_x + renew_btn_w, renew_btn_y + renew_btn_h, false);
        draw_set_color(c_lime);
        draw_rectangle(renew_btn_x, renew_btn_y, renew_btn_x + renew_btn_w, renew_btn_y + renew_btn_h, true);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(renew_btn_x + renew_btn_w/2, renew_btn_y + renew_btn_h/2, "Odnow");

        if (renew_hover && mouse_check_button_pressed(mb_left)) {
            scr_encounter_activate(_enc);
            show_debug_message("UI: Gracz odnowil encounter " + string(ed.typ));
        }
    }

    // === PRZYCISK ZAMKNIĘCIA ===
    var btn_w = 80;
    var btn_h = 30;
    var btn_x = panel_x + (panel_w - btn_w) / 2;
    var btn_y = panel_y + panel_h - 45;

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