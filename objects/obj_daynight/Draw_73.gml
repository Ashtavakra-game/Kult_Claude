/// obj_daynight - Draw GUI End Event
/// Renderowanie efektów oświetlenia

// ============================================================================
// SURFACE PRZYGOTOWANIE
// ============================================================================

if (!surface_exists(light_surface)) {
    light_surface = surface_create(room_width, room_height);
}

// ============================================================================
// KOLOR TINTOWANIA (atramentowy niebieski w nocy)
// ============================================================================

// Kolor tintowania w zależności od pory
var tint_color = c_white;  // dzień - brak tintowania
var tint_alpha = 0;

switch (global.daynight_phase) {
    case "night":
        tint_color = global.daynight_night_tint_color;  // kolor z konfiguracji
        tint_alpha = global.daynight_night_blue_intensity;  // intensywność z konfiguracji
        break;
    case "morning":
        // Przejście z atramentowego do normalnego
        tint_color = merge_colour(global.daynight_night_tint_color, #ffd699, global.daynight_phase_progress);
        tint_alpha = lerp(global.daynight_night_blue_intensity, 0, global.daynight_phase_progress);
        break;
    case "day":
        tint_color = c_white;
        tint_alpha = 0;
        break;
    case "evening":
        // Przejście z normalnego do atramentowego przez pomarańczowy
        if (global.daynight_phase_progress < 0.5) {
            tint_color = merge_colour(c_white, #ff9966, global.daynight_phase_progress * 2);
            tint_alpha = lerp(0, global.daynight_night_blue_intensity * 0.625, global.daynight_phase_progress * 2);
        } else {
            tint_color = merge_colour(#ff9966, global.daynight_night_tint_color, (global.daynight_phase_progress - 0.5) * 2);
            tint_alpha = lerp(global.daynight_night_blue_intensity * 0.625, global.daynight_night_blue_intensity, (global.daynight_phase_progress - 0.5) * 2);
        }
        break;
}

// ============================================================================
// WARSTWA 1: TINTOWANIE KOLORÓW (multiply)
// ============================================================================

if (tint_alpha > 0) {
    // bm_multiply emulowane przez blendmode_ext
    gpu_set_blendmode_ext(bm_dest_colour, bm_zero);
    draw_set_alpha(1);
    
    // Interpoluj kolor z białym w zależności od tint_alpha
    // (biały = brak zmiany przy multiply)
    var final_tint = merge_colour(c_white, tint_color, tint_alpha);
    
    draw_rectangle_color(0, 0, room_width, room_height, final_tint, final_tint, final_tint, final_tint, false);
    gpu_set_blendmode(bm_normal);
}

// ============================================================================
// WARSTWA 2: MASKA CIEMNOŚCI (surface ze światłami)
// ============================================================================

surface_set_target(light_surface);

// Ciemność (stały kolor, zmienna przezroczystość)
draw_clear_alpha(global.daynight_darkness_color, global.daynight_alpha);

// ============================================================================
// PAS 1 — SUBTRACT (biały sprite) - wycinanie świateł
// ============================================================================

gpu_set_blendmode(bm_subtract);

for (var i = 0; i < ds_list_size(global.lights); i++) {
    var e = global.lights[| i];
    scr_light_draw_from_entry(e);
}

gpu_set_blendmode(bm_normal);

// ============================================================================
// PAS 2 — ADD (kolor) - dodawanie koloru świateł
// ============================================================================

gpu_set_blendmode(bm_add);

for (var i = 0; i < ds_list_size(global.lights); i++) {
    var e = global.lights[| i];
    scr_light_add_color(e);
}

gpu_set_blendmode(bm_normal);

// ============================================================================
// FINALNY RENDER
// ============================================================================

surface_reset_target();
draw_surface(light_surface, 0, 0);

// ============================================================================
// DEBUG OVERLAY - ZEGAR I INFO
// ============================================================================

var cam = view_camera[0];
var cx = camera_get_view_x(cam);
var cy = camera_get_view_y(cam);

// --- ZEGAR ---
// Oblicz godzinę i minuty (0.0 = 00:00, 0.5 = 12:00, 1.0 = 24:00)
var total_minutes = global.daynight_time * 24 * 60;
var hours = floor(total_minutes / 60);
var minutes = floor(total_minutes) mod 60;

var h_str = (hours < 10) ? "0" + string(hours) : string(hours);
var m_str = (minutes < 10) ? "0" + string(minutes) : string(minutes);
var time_str = h_str + ":" + m_str;

// Polska nazwa pory dnia
var phase_name;
switch (global.daynight_phase) {
    case "night":   phase_name = "Noc"; break;
    case "morning": phase_name = "Poranek"; break;
    case "day":     phase_name = "Dzien"; break;
    case "evening": phase_name = "Wieczor"; break;
    default:        phase_name = "???"; break;
}

// Rysuj tło zegara
var clock_x = cx + 10;
var clock_y = cy + 10;
var clock_w = 120;
var clock_h = 50;

draw_set_alpha(0.7);
draw_rectangle_color(clock_x, clock_y, clock_x + clock_w, clock_y + clock_h, 
    c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

// Ramka
draw_rectangle_color(clock_x, clock_y, clock_x + clock_w, clock_y + clock_h,
    c_white, c_white, c_white, c_white, true);

// Tekst zegara
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

// Godzina (duża)
draw_text(clock_x + clock_w/2, clock_y + 18, time_str);

// Pora dnia (mała)
draw_set_color(c_yellow);
draw_text(clock_x + clock_w/2, clock_y + 38, phase_name);

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// --- PASEK CYKLU ---
var bar_x = cx + 10;
var bar_y = cy + 70;
var bar_w = 120;
var bar_h = 12;

// Tło paska
draw_set_alpha(0.5);
draw_rectangle_color(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, c_black, c_black, c_black, c_black, false);

// Segmenty pór
var bounds = global.daynight_phase_bounds;
draw_set_alpha(0.8);

// Noc (ciemnoniebieski)
draw_rectangle_color(bar_x, bar_y, bar_x + bar_w * bounds.night_end, bar_y + bar_h, 
    #1a1a3a, #1a1a3a, #1a1a3a, #1a1a3a, false);
// Poranek (pomarańczowy)
draw_rectangle_color(bar_x + bar_w * bounds.night_end, bar_y, bar_x + bar_w * bounds.morning_end, bar_y + bar_h,
    #ffb366, #ffb366, #ffb366, #ffb366, false);
// Dzień (żółty)
draw_rectangle_color(bar_x + bar_w * bounds.morning_end, bar_y, bar_x + bar_w * bounds.day_end, bar_y + bar_h,
    #ffff66, #ffff66, #ffff66, #ffff66, false);
// Wieczór (czerwony)
draw_rectangle_color(bar_x + bar_w * bounds.day_end, bar_y, bar_x + bar_w, bar_y + bar_h,
    #ff6633, #ff6633, #ff6633, #ff6633, false);

// Wskaźnik aktualnego czasu
draw_set_alpha(1);
var indicator_x = bar_x + bar_w * global.daynight_time;
draw_line_width_color(indicator_x, bar_y - 2, indicator_x, bar_y + bar_h + 2, 2, c_white, c_white);

// Ramka paska
draw_rectangle_color(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, c_white, c_white, c_white, c_white, true);

draw_set_alpha(1);
draw_set_color(c_white);

// --- DODATKOWE INFO (opcjonalnie - odkomentuj) ---
/*
draw_text(cx + 10, cy + 90, "Speed: " + string(global.daynight_speed_multiplier) + "x");
draw_text(cx + 10, cy + 105, "Alpha: " + string(floor(global.daynight_alpha * 100)) + "%");
*/