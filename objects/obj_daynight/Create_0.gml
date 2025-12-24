/// obj_daynight - Create Event
/// System cyklu dnia i nocy z 4 porami

// ============================================================================
// SURFACE DO RENDEROWANIA
// ============================================================================
light_surface = -1;

// ============================================================================
// KONFIGURACJA CYKLU (dostosuj według potrzeb)
// ============================================================================

// Całkowita długość pełnego cyklu (24h w grze) w krokach
// Przykład: 60 FPS * 60 sekund * 10 minut = 36000 kroków na pełny cykl
global.daynight_cycle_length = room_speed * 60 * 3; // 10 minut realnego czasu

// Proporcje pór dnia (muszą sumować się do 1.0)
global.daynight_phase_ratios = {
    night:   0.25,  // 1/4 cyklu - noc (stała ciemność)
    morning: 0.25,  // 1/4 cyklu - poranek (przejście ciemność → jasność)
    day:     0.25,  // 1/4 cyklu - dzień (stała jasność)
    evening: 0.25   // 1/4 cyklu - wieczór (przejście jasność → ciemność)
};

// Wartości jasności (0 = pełna jasność, 1 = pełna ciemność)
global.daynight_darkness = {
    night: 0.65,    // jak ciemno jest w nocy
    day:   0.0      // jak jasno jest w dzień (0 = brak przyciemnienia)
};

// ============================================================================
// PARAMETRY KOLOROWANIA NOCY (dostosuj według potrzeb)
// ============================================================================

// Intensywność ciemności w nocy (0.0 = brak ciemności, 1.0 = całkowita ciemność)
// Ta wartość kontroluje jak ciemna jest nakładka nocna
global.daynight_night_darkness = 0.85;

// Intensywność niebieskiego odcienia (0.0 = brak odcienia, 1.0 = pełny niebieski)
// Ta wartość kontroluje jak bardzo "niebieska" jest noc
global.daynight_night_blue_intensity = 0.1;

// Bazowy kolor nocnego tintowania (domyślnie atramentowy niebieski)
// Możesz zmienić na inny kolor hex, np. #2a1a4a dla fioletowej nocy
global.daynight_night_tint_color = #1a1a4a;

// Kolor nakładki ciemności (używany w surface)
// Domyślnie bardzo ciemny niebieski
global.daynight_darkness_color = #010416;

// ============================================================================
// STAN CYKLU (globalny - dostępny dla wszystkich obiektów)
// ============================================================================

// Aktualny czas w cyklu (0.0 do 1.0, gdzie 0 = początek nocy)
global.daynight_time = 0.0;

// Aktualna pora dnia (enum-like string)
// Możliwe wartości: "night", "morning", "day", "evening"
global.daynight_phase = "night";

// Postęp w aktualnej porze (0.0 do 1.0)
global.daynight_phase_progress = 0.0;

// Aktualna wartość przyciemnienia (0.0 do 1.0)
global.daynight_alpha = global.daynight_darkness.night;

// Czy cykl jest aktywny (można zatrzymać dla debugowania)
global.daynight_active = true;

// Prędkość cyklu (1.0 = normalna, 2.0 = podwójna, etc.)
global.daynight_speed_multiplier = 1.0;

// ============================================================================
// OBLICZONE GRANICE FAZ (w jednostkach 0-1)
// ============================================================================

// Oblicz granice każdej fazy
var _ratios = global.daynight_phase_ratios;
global.daynight_phase_bounds = {
    night_end:   _ratios.night,
    morning_end: _ratios.night + _ratios.morning,
    day_end:     _ratios.night + _ratios.morning + _ratios.day,
    evening_end: 1.0
};

// ============================================================================
// INICJALIZACJA LISTY ŚWIATEŁ
// ============================================================================

if (!variable_global_exists("lights")) {
    global.lights = ds_list_create();
}

// ============================================================================
// FUNKCJA POMOCNICZA - USTAW CZAS (do debugowania/skryptów)
// ============================================================================

/// scr_daynight_set_time(time_normalized)
/// Ustawia czas cyklu (0.0 = początek nocy, 0.5 = początek dnia, etc.)
globalvar scr_daynight_set_time;
scr_daynight_set_time = function(_time) {
    global.daynight_time = clamp(_time, 0, 0.9999);
};

/// scr_daynight_set_phase(phase_name)
/// Przeskakuje do początku danej pory
globalvar scr_daynight_set_phase;
scr_daynight_set_phase = function(_phase) {
    var bounds = global.daynight_phase_bounds;
    switch (_phase) {
        case "night":   global.daynight_time = 0; break;
        case "morning": global.daynight_time = bounds.night_end; break;
        case "day":     global.daynight_time = bounds.morning_end; break;
        case "evening": global.daynight_time = bounds.day_end; break;
    }
};

/// scr_daynight_get_info()
/// Zwraca struct z pełnymi informacjami o aktualnym stanie
globalvar scr_daynight_get_info;
scr_daynight_get_info = function() {
    return {
        time: global.daynight_time,
        phase: global.daynight_phase,
        phase_progress: global.daynight_phase_progress,
        alpha: global.daynight_alpha,
        ambient_color: global.daynight_ambient_color,
        is_dark: (global.daynight_alpha > 0.5),
        is_night: (global.daynight_phase == "night"),
        is_day: (global.daynight_phase == "day")
    };
};

// ============================================================================
// DEBUG - Ustaw początkowy czas (odkomentuj do testów)
// ============================================================================
// global.daynight_time = 0.25; // Start od poranka
// global.daynight_speed_multiplier = 10.0; // 10x szybszy cykl

show_debug_message("=== DAYNIGHT SYSTEM INITIALIZED ===");
show_debug_message("Cycle length: " + string(global.daynight_cycle_length / room_speed) + " seconds");
show_debug_message("Phase ratios: Night=" + string(global.daynight_phase_ratios.night * 100) + "%, " +
                   "Morning=" + string(global.daynight_phase_ratios.morning * 100) + "%, " +
                   "Day=" + string(global.daynight_phase_ratios.day * 100) + "%, " +
                   "Evening=" + string(global.daynight_phase_ratios.evening * 100) + "%");