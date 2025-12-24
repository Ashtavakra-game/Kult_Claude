/// obj_daynight - Step Event
/// Aktualizacja cyklu dnia i nocy

// ============================================================================
// AKTUALIZACJA CZASU
// ============================================================================

if (global.daynight_active) {
    // Oblicz przyrost czasu w tej klatce
    var time_increment = (1.0 / global.daynight_cycle_length) * global.daynight_speed_multiplier;
    
    // Zwiększ czas i zapętl
    global.daynight_time += time_increment;
    if (global.daynight_time >= 1.0) {
        global.daynight_time -= 1.0;
    }
}

// ============================================================================
// OKREŚL AKTUALNĄ PORĘ DNIA
// ============================================================================

var t = global.daynight_time;
var bounds = global.daynight_phase_bounds;
var old_phase = global.daynight_phase;

if (t < bounds.night_end) {
    // NOC (0.00 - 0.25)
    global.daynight_phase = "night";
    global.daynight_phase_progress = t / global.daynight_phase_ratios.night;

    // Stała ciemność
    global.daynight_alpha = global.daynight_night_darkness;
    
} else if (t < bounds.morning_end) {
    // PORANEK (0.25 - 0.50) - przejście z ciemności do jasności
    global.daynight_phase = "morning";
    var phase_start = bounds.night_end;
    var phase_length = global.daynight_phase_ratios.morning;
    global.daynight_phase_progress = (t - phase_start) / phase_length;

    // Liniowa interpolacja: ciemność → jasność
    global.daynight_alpha = lerp(
        global.daynight_night_darkness,
        global.daynight_darkness.day,
        global.daynight_phase_progress
    );
    
} else if (t < bounds.day_end) {
    // DZIEŃ (0.50 - 0.75)
    global.daynight_phase = "day";
    var phase_start = bounds.morning_end;
    var phase_length = global.daynight_phase_ratios.day;
    global.daynight_phase_progress = (t - phase_start) / phase_length;
    
    // Stała jasność
    global.daynight_alpha = global.daynight_darkness.day;
    
} else {
    // WIECZÓR (0.75 - 1.00) - przejście z jasności do ciemności
    global.daynight_phase = "evening";
    var phase_start = bounds.day_end;
    var phase_length = global.daynight_phase_ratios.evening;
    global.daynight_phase_progress = (t - phase_start) / phase_length;

    // Liniowa interpolacja: jasność → ciemność
    global.daynight_alpha = lerp(
        global.daynight_darkness.day,
        global.daynight_night_darkness,
        global.daynight_phase_progress
    );
}

// ============================================================================
// ZDARZENIE ZMIANY PORY (opcjonalne - do użycia przez inne systemy)
// ============================================================================


if (old_phase != global.daynight_phase) {
    show_debug_message("=== PHASE CHANGE: " + old_phase + " -> " + global.daynight_phase + " ===");
    
    // === NOWE: Hook dla systemu cech ===
    scr_trait_on_phase_change(global.daynight_phase, old_phase);
}

// ============================================================================
// USUŃ MARTWE ŚWIATŁA (właściciele którzy już nie istnieją)
// ============================================================================

for (var i = ds_list_size(global.lights) - 1; i >= 0; i--) {
    var light = global.lights[| i];
    
    // Jeśli światło ma właściciela który już nie istnieje - usuń
    if (variable_struct_exists(light, "owner")) {
        if (!instance_exists(light.owner)) {
            ds_list_delete(global.lights, i);
        }
    }
}


// ============================================================================
// DEBUG OUTPUT (odkomentuj do testów)
// ============================================================================
/*
if (keyboard_check_pressed(vk_f1)) {
    show_debug_message("Time: " + string(global.daynight_time) + 
                       " | Phase: " + global.daynight_phase + 
                       " | Progress: " + string(global.daynight_phase_progress) +
                       " | Alpha: " + string(global.daynight_alpha));
}

// Klawisze do zmiany pory (debug)
if (keyboard_check_pressed(ord("1"))) scr_daynight_set_phase("night");
if (keyboard_check_pressed(ord("2"))) scr_daynight_set_phase("morning");
if (keyboard_check_pressed(ord("3"))) scr_daynight_set_phase("day");
if (keyboard_check_pressed(ord("4"))) scr_daynight_set_phase("evening");

// Klawisze do zmiany prędkości (debug)
if (keyboard_check_pressed(vk_add)) global.daynight_speed_multiplier *= 2;
if (keyboard_check_pressed(vk_subtract)) global.daynight_speed_multiplier = max(0.1, global.daynight_speed_multiplier / 2);
*/