/// =============================================================================
/// BORUTA - UI ZASOBÓW (OFIARA i STRACH)
/// =============================================================================
/// Funkcje pomocnicze UI dla systemu zasobów
/// Główne paski są rysowane przez scr_ui_draw_economy_bars w scr_traits_UI
/// =============================================================================

// =============================================================================
// OVERLAY KOŃCA GRY
// =============================================================================

/// scr_ui_draw_game_state_overlay()
/// Rysuje overlay wygranej/przegranej
function scr_ui_draw_game_state_overlay() {
    if (!global.game_won && !global.game_lost) return;

    var cx = display_get_gui_width() / 2;
    var cy = display_get_gui_height() / 2;

    // Przyciemnione tło
    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    if (global.game_won) {
        // === WYGRANA ===
        draw_set_color($00ff88); // zielony
        draw_text(cx, cy - 60, "STARA WIARA ODRODZILA SIE");

        draw_set_color(c_white);
        draw_text(cx, cy, "Babki znow opowiadaja o dziadku, co z boru wracal.");
        draw_text(cx, cy + 30, "Dzieci zostawiaja miseczki dla skrzatow.");
        draw_text(cx, cy + 60, "Boruta triumfuje.");

    } else {
        // === PRZEGRANA ===
        draw_set_color($4444ff); // czerwony

        draw_text(cx, cy - 60, "MITY ZOSTALY ZAPOMNIANE");
        draw_set_color(c_white);
        draw_text(cx, cy, "Proboszcz sprowadzil relikwie.");
        draw_text(cx, cy + 30, "Procesje ida przez wies.");
        draw_text(cx, cy + 60, "Boruta musi szukac innej wsi...");
    }

    // Instrukcja
    draw_set_color(c_gray);
    draw_text(cx, cy + 120, "Nacisnij ESC aby kontynuowac");

    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

// =============================================================================
// DEBUG INFO
// =============================================================================

/// scr_ui_draw_population_debug(x, y)
/// Rysuje szczegółowe informacje debug
function scr_ui_draw_population_debug(_x, _y) {
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var txt_y = _y;
    var line_h = 18;

    draw_text(_x, txt_y, "=== RESOURCES DEBUG ===");
    txt_y += line_h;

    draw_text(_x, txt_y, "Ofiara: " + string(global.ofiara));
    txt_y += line_h;

    draw_text(_x, txt_y, "Strach: " + string(global.strach));
    txt_y += line_h;

    txt_y += line_h;
    draw_text(_x, txt_y, "Dzien: " + string(global.day_counter));
    txt_y += line_h;

    // Status karczmy (jedyne miejsce reagujące na gracza)
    txt_y += line_h;
    draw_text(_x, txt_y, "Karczma dzis: " + (global.visited_today.tavern_active ? "ODWIEDZONA" : "nie"));
}

