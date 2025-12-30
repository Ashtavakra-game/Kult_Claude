/// =============================================================================
/// BORUTA - UI WSKAŹNIKÓW POPULACJI
/// =============================================================================
/// Rysowanie pasków: Wiara w Stare Mity, Strach, Szaleństwo
/// Wskaźnik podatności i overlay końca gry
/// =============================================================================

// === KOLORY UI ===
#macro POP_UI_WSM_COLOR $66cccc       // złoty/bursztynowy (BGR)
#macro POP_UI_FEAR_COLOR $cc6666      // fioletowy (BGR)
#macro POP_UI_MADNESS_COLOR $3333cc   // czerwony (BGR)
#macro POP_UI_BG_COLOR $1a1a2e        // ciemne tło
#macro POP_UI_BORDER_COLOR $303040    // ramka

// =============================================================================
// GŁÓWNA FUNKCJA RYSOWANIA
// =============================================================================

/// scr_ui_draw_population_bars(x, y, width, bar_height, spacing)
/// Rysuje trzy paski wskaźników populacji
/// @param _x - pozycja X
/// @param _y - pozycja Y
/// @param _w - szerokość pasków
/// @param _bar_h - wysokość pojedynczego paska
/// @param _spacing - odstęp między paskami

function scr_ui_draw_population_bars(_x, _y, _w, _bar_h, _spacing) {
    var current_y = _y;

    // === PASEK WIARY W STARE MITY ===
    scr_ui_draw_single_bar(
        _x, current_y, _w, _bar_h,
        global.myth_faith, global.myth_faith_max,
        POP_UI_WSM_COLOR,
        "Wiara w Mity"
    );
    current_y += _bar_h + _spacing;

    // === PASEK STRACHU ===
    scr_ui_draw_single_bar(
        _x, current_y, _w, _bar_h,
        global.collective_fear, global.fear_max,
        POP_UI_FEAR_COLOR,
        "Strach"
    );
    // Rysuj znaczniki optymalnego zakresu
    scr_ui_draw_fear_markers(_x, current_y, _w, _bar_h);
    current_y += _bar_h + _spacing;

    // === PASEK SZALEŃSTWA ===
    scr_ui_draw_single_bar(
        _x, current_y, _w, _bar_h,
        global.collective_madness, global.madness_max,
        POP_UI_MADNESS_COLOR,
        "Szalenstwo"
    );
    current_y += _bar_h + _spacing;

    // === WSKAŹNIK PODATNOŚCI (pod paskami) ===
    current_y += _spacing;
    scr_ui_draw_susceptibility_indicator(_x, current_y, _w);
}

// =============================================================================
// POJEDYNCZY PASEK
// =============================================================================

/// scr_ui_draw_single_bar(x, y, w, h, value, max_value, color, label)
/// Rysuje pojedynczy pasek ze stylem

function scr_ui_draw_single_bar(_x, _y, _w, _h, _val, _max, _color, _label) {
    var fill = clamp(_val / _max, 0, 1);

    // Tło paska
    draw_set_alpha(0.7);
    draw_set_color(POP_UI_BG_COLOR);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    // Wypełnienie paska
    draw_set_alpha(0.9);
    var fill_w = (_w - 4) * fill;
    if (fill_w > 0) {
        draw_set_color(_color);
        draw_rectangle(_x + 2, _y + 2, _x + 2 + fill_w, _y + _h - 2, false);
    }

    // Ramka
    draw_set_alpha(1);
    draw_set_color(POP_UI_BORDER_COLOR);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    // Etykieta (lewa strona)
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(_x + 8, _y + _h/2, _label);

    // Wartość (prawa strona)
    draw_set_halign(fa_right);
    draw_text(_x + _w - 8, _y + _h/2, string(floor(_val)) + "/" + string(_max));

    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// =============================================================================
// ZNACZNIKI STRACHU
// =============================================================================

/// scr_ui_draw_fear_markers(x, y, w, h)
/// Rysuje znaczniki optymalnego zakresu strachu na pasku

function scr_ui_draw_fear_markers(_x, _y, _w, _h) {
    var low = global.fear_optimal_low / 100;
    var high = global.fear_optimal_high / 100;
    var critical = global.fear_critical / 100;

    draw_set_alpha(0.8);

    // Znacznik dolny (zielony) - początek optimum
    var low_x = _x + _w * low;
    draw_set_color(c_lime);
    draw_line_width(low_x, _y, low_x, _y + _h, 2);

    // Znacznik górny (żółty) - koniec optimum
    var high_x = _x + _w * high;
    draw_set_color(c_yellow);
    draw_line_width(high_x, _y, high_x, _y + _h, 2);

    // Znacznik krytyczny (czerwony) - początek szaleństwa
    var crit_x = _x + _w * critical;
    draw_set_color(c_red);
    draw_line_width(crit_x, _y, crit_x, _y + _h, 2);

    draw_set_alpha(1);
    draw_set_color(c_white);
}

// =============================================================================
// WSKAŹNIK PODATNOŚCI
// =============================================================================

/// scr_ui_draw_susceptibility_indicator(x, y, w)
/// Rysuje wskaźnik aktualnej podatności na mity

function scr_ui_draw_susceptibility_indicator(_x, _y, _w) {
    var suscept = scr_logistic_susceptibility(global.collective_fear);
    var suscept_pct = floor(suscept * 100);

    // Kolor zależny od podatności (czerwony -> zielony)
    var col = merge_color(c_red, c_lime, suscept);

    // Tekst opisu
    var desc = scr_get_susceptibility_description();

    draw_set_color(col);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_x, _y, "Podatnosc: " + string(suscept_pct) + "%");

    // Mały pasek podatności
    var bar_w = 80;
    var bar_h = 6;
    var bar_x = _x + 120;

    // Tło
    draw_set_alpha(0.5);
    draw_set_color(c_dkgray);
    draw_rectangle(bar_x, _y + 4, bar_x + bar_w, _y + 4 + bar_h, false);

    // Wypełnienie
    draw_set_alpha(1);
    draw_set_color(col);
    draw_rectangle(bar_x, _y + 4, bar_x + bar_w * suscept, _y + 4 + bar_h, false);

    // Opis stanu
    draw_set_color(c_gray);
    draw_text(_x, _y + 16, desc);

    draw_set_color(c_white);
}

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

        if (global.game_lost_reason == "madness") {
            draw_text(cx, cy - 60, "WIOSKA OSZALALA");
            draw_set_color(c_white);
            draw_text(cx, cy, "Za duzo, za szybko.");
            draw_text(cx, cy + 30, "Ludzie uciekli lub zeszli z rozumu.");
            draw_text(cx, cy + 60, "Nie ma komu wierzyc w stare mity.");
        } else {
            draw_text(cx, cy - 60, "MITY ZOSTALY ZAPOMNIANE");
            draw_set_color(c_white);
            draw_text(cx, cy, "Proboszcz sprowadzil relikwie.");
            draw_text(cx, cy + 30, "Procesje ida przez wies.");
            draw_text(cx, cy + 60, "Boruta musi szukac innej wsi...");
        }
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
// KOMPAKTOWA WERSJA (mniejsze paski)
// =============================================================================

/// scr_ui_draw_population_compact(x, y)
/// Kompaktowa wersja pasków (do górnego rogu)

function scr_ui_draw_population_compact(_x, _y) {
    scr_ui_draw_population_bars(_x, _y, 220, 20, 4);
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

    draw_text(_x, txt_y, "=== POPULATION DEBUG ===");
    txt_y += line_h;

    draw_text(_x, txt_y, "WSM: " + string(global.myth_faith) + " / " + string(global.myth_faith_max));
    txt_y += line_h;

    draw_text(_x, txt_y, "Fear: " + string(global.collective_fear) + " / " + string(global.fear_max));
    txt_y += line_h;

    draw_text(_x, txt_y, "Madness: " + string(global.collective_madness) + " / " + string(global.madness_max));
    txt_y += line_h;

    txt_y += line_h;
    var suscept = scr_logistic_susceptibility(global.collective_fear);
    draw_text(_x, txt_y, "Susceptibility: " + string(suscept * 100) + "%");
    txt_y += line_h;

    var zone = scr_get_fear_zone();
    draw_text(_x, txt_y, "Fear Zone: " + zone);
    txt_y += line_h;

    txt_y += line_h;
    draw_text(_x, txt_y, "Win Counter: " + string(global.win_counter) + "/5");
    txt_y += line_h;
    draw_text(_x, txt_y, "Lose Counter: " + string(global.lose_counter) + "/7");
}
