/// scr_daynight_api
/// Funkcje API do interakcji z systemem dnia i nocy
/// Użycie: inne obiekty mogą wywoływać te funkcje aby reagować na cykl

// ============================================================================
// FUNKCJE ZAPYTAŃ (QUERY FUNCTIONS)
// ============================================================================

/// scr_daynight_is_night()
/// Zwraca true jeśli jest noc (pełna ciemność)
function scr_daynight_is_night() {
    return (global.daynight_phase == "night");
}

/// scr_daynight_is_day()
/// Zwraca true jeśli jest dzień (pełna jasność)
function scr_daynight_is_day() {
    return (global.daynight_phase == "day");
}

/// scr_daynight_is_dark()
/// Zwraca true jeśli jest ciemno (noc lub późny wieczór/wczesny poranek)
function scr_daynight_is_dark() {
    return (global.daynight_alpha > 0.5);
}

/// scr_daynight_is_light()
/// Zwraca true jeśli jest jasno
function scr_daynight_is_light() {
    return (global.daynight_alpha < 0.3);
}

/// scr_daynight_get_phase()
/// Zwraca aktualną porę dnia jako string: "night", "morning", "day", "evening"
function scr_daynight_get_phase() {
    return global.daynight_phase;
}

/// scr_daynight_get_time()
/// Zwraca znormalizowany czas cyklu (0.0 - 1.0)
function scr_daynight_get_time() {
    return global.daynight_time;
}

/// scr_daynight_get_alpha()
/// Zwraca aktualną wartość przyciemnienia (0.0 = jasno, 1.0 = ciemno)
function scr_daynight_get_alpha() {
    return global.daynight_alpha;
}

/// scr_daynight_get_brightness()
/// Zwraca jasność (odwrotność alpha, 0.0 = ciemno, 1.0 = jasno)
function scr_daynight_get_brightness() {
    return 1.0 - global.daynight_alpha;
}

/// scr_daynight_get_phase_progress()
/// Zwraca postęp w aktualnej porze (0.0 - 1.0)
function scr_daynight_get_phase_progress() {
    return global.daynight_phase_progress;
}

// ============================================================================
// FUNKCJE KONTROLI (CONTROL FUNCTIONS)
// ============================================================================

/// scr_daynight_pause()
/// Zatrzymuje cykl
function scr_daynight_pause() {
    global.daynight_active = false;
}

/// scr_daynight_resume()
/// Wznawia cykl
function scr_daynight_resume() {
    global.daynight_active = true;
}

/// scr_daynight_toggle()
/// Przełącza pauzę/wznowienie
function scr_daynight_toggle() {
    global.daynight_active = !global.daynight_active;
}

/// scr_daynight_set_speed(multiplier)
/// Ustawia mnożnik prędkości cyklu (1.0 = normalnie, 2.0 = 2x szybciej)
function scr_daynight_set_speed(_multiplier) {
    global.daynight_speed_multiplier = max(1.0, _multiplier);
}

/// scr_daynight_skip_to_phase(phase_name)
/// Przeskakuje do początku danej pory ("night", "morning", "day", "evening")
function scr_daynight_skip_to_phase(_phase) {
    var bounds = global.daynight_phase_bounds;
    switch (_phase) {
        case "night":   global.daynight_time = 0.001; break;
        case "morning": global.daynight_time = bounds.night_end + 0.001; break;
        case "day":     global.daynight_time = bounds.morning_end + 0.001; break;
        case "evening": global.daynight_time = bounds.day_end + 0.001; break;
    }
}

/// scr_daynight_set_time(normalized_time)
/// Ustawia czas cyklu (0.0 - 1.0)
function scr_daynight_set_time(_time) {
    global.daynight_time = clamp(_time, 0, 0.9999);
}

// ============================================================================
// FUNKCJE POMOCNICZE DLA NPC
// ============================================================================

/// scr_daynight_npc_should_sleep()
/// Zwraca true jeśli NPC powinien spać (noc lub późny wieczór)
function scr_daynight_npc_should_sleep() {
    if (global.daynight_phase == "night") return true;
    if (global.daynight_phase == "evening" && global.daynight_phase_progress > 0.7) return true;
    return false;
}

/// scr_daynight_npc_should_wake()
/// Zwraca true jeśli NPC powinien się obudzić (poranek po połowie)
function scr_daynight_npc_should_wake() {
    if (global.daynight_phase == "morning" && global.daynight_phase_progress > 0.3) return true;
    if (global.daynight_phase == "day") return true;
    return false;
}

/// scr_daynight_npc_activity_modifier()
/// Zwraca mnożnik aktywności NPC (0.0 - 1.0)
/// Może być użyty do modyfikowania zachowań, prędkości, etc.
function scr_daynight_npc_activity_modifier() {
    switch (global.daynight_phase) {
        case "night":   return 0.1;  // Bardzo niska aktywność
        case "morning": return lerp(0.3, 1.0, global.daynight_phase_progress);
        case "day":     return 1.0;  // Pełna aktywność
        case "evening": return lerp(1.0, 0.3, global.daynight_phase_progress);
    }
    return 1.0;
}

// ============================================================================
// FUNKCJE POMOCNICZE DLA UI
// ============================================================================

/// scr_daynight_ui_text_color()
/// Zwraca kolor tekstu odpowiedni dla pory dnia
function scr_daynight_ui_text_color() {
    if (global.daynight_alpha > 0.5) {
        return c_white; // Jasny tekst na ciemnym tle
    }
    return c_black; // Ciemny tekst na jasnym tle
}

// ============================================================================
// FUNKCJE KONWERSJI CZASU
// ============================================================================

/// scr_daynight_time_to_hours(normalized_time)
/// Konwertuje znormalizowany czas (0-1) na godziny (0-24)
function scr_daynight_time_to_hours(_time) {
    // Zakładamy że 0.0 = północ (00:00)
    return _time * 24;
}

/// scr_daynight_get_hour()
/// Zwraca aktualną "godzinę" gry (0-23)
function scr_daynight_get_hour() {
    return floor(scr_daynight_time_to_hours(global.daynight_time));
}

/// scr_daynight_get_time_string()
/// Zwraca czas jako string "HH:MM"
function scr_daynight_get_time_string() {
    var total_minutes = global.daynight_time * 24 * 60;
    var hours = floor(total_minutes / 60);
    var minutes = floor(total_minutes) mod 60;
    
    var h_str = (hours < 10) ? "0" + string(hours) : string(hours);
    var m_str = (minutes < 10) ? "0" + string(minutes) : string(minutes);
    
    return h_str + ":" + m_str;
}

/// scr_daynight_get_phase_name_pl()
/// Zwraca polską nazwę aktualnej pory dnia
function scr_daynight_get_phase_name_pl() {
    switch (global.daynight_phase) {
        case "night":   return "Noc";
        case "morning": return "Poranek";
        case "day":     return "Dzień";
        case "evening": return "Wieczór";
    }
    return "???";
}

/// scr_light_control
/// Funkcje do sterowania parametrami świateł w runtime
/// Głównie: aktualizacja jasności (intensity)

// ============================================================================
// USTAWIENIE JASNOŚCI ŚWIATŁA
// ============================================================================

/// scr_light_set_intensity(light, intensity)
/// Ustawia jasność światła (0.0 - 1.0)
/// @param light - struktura światła (np. my_light)
/// @param intensity - wartość jasności (0.0 = wyłączone, 1.0 = pełna jasność)
function scr_light_set_intensity(_light, _intensity) {
    if (is_undefined(_light)) return;
    
    _light.intensity = clamp(_intensity, 0.0, 1.0);
}

/// scr_light_get_intensity(light)
/// Pobiera aktualną jasność światła
/// @param light - struktura światła
/// @return wartość jasności (0.0 - 1.0), domyślnie 1.0 jeśli nie ustawiono
function scr_light_get_intensity(_light) {
    if (is_undefined(_light)) return 0;
    
    if (!variable_struct_exists(_light, "intensity")) {
        return 1.0; // domyślna pełna jasność
    }
    
    return _light.intensity;
}

// ============================================================================
// MODYFIKACJA JASNOŚCI
// ============================================================================

/// scr_light_fade_to(light, target_intensity, speed)
/// Płynnie zmienia jasność światła do docelowej wartości
/// Wywołuj w Step event dla płynnej animacji
/// @param light - struktura światła
/// @param target_intensity - docelowa jasność (0.0 - 1.0)
/// @param speed - szybkość zmiany (np. 0.02 = 2% na step)
/// @return true gdy osiągnięto cel, false gdy w trakcie animacji
function scr_light_fade_to(_light, _target, _speed) {
    if (is_undefined(_light)) return true;
    
    // Upewnij się że intensity istnieje
    if (!variable_struct_exists(_light, "intensity")) {
        _light.intensity = 1.0;
    }
    
    var current = _light.intensity;
    _target = clamp(_target, 0.0, 1.0);
    
    // Sprawdź czy już osiągnęliśmy cel
    if (abs(current - _target) < 0.001) {
        _light.intensity = _target;
        return true;
    }
    
    // Płynna interpolacja
    if (current < _target) {
        _light.intensity = min(current + _speed, _target);
    } else {
        _light.intensity = max(current - _speed, _target);
    }
    
    return false;
}

/// scr_light_turn_on(light)
/// Włącza światło (ustawia pełną jasność)
function scr_light_turn_on(_light) {
    scr_light_set_intensity(_light, 1.0);
}

/// scr_light_turn_off(light)
/// Wyłącza światło (ustawia jasność na 0)
function scr_light_turn_off(_light) {
    scr_light_set_intensity(_light, 0.0);
}

/// scr_light_toggle(light)
/// Przełącza światło (włącz/wyłącz)
function scr_light_toggle(_light) {
    if (is_undefined(_light)) return;
    
    var current = scr_light_get_intensity(_light);
    
    if (current > 0.5) {
        scr_light_turn_off(_light);
    } else {
        scr_light_turn_on(_light);
    }
}

// ============================================================================
// EFEKTY SPECJALNE
// ============================================================================

/// scr_light_flicker(light, base_intensity, flicker_amount)
/// Tworzy efekt migotania światła (wywołuj w Step)
/// @param light - struktura światła
/// @param base_intensity - bazowa jasność (np. 0.8)
/// @param flicker_amount - amplituda migotania (np. 0.2)
function scr_light_flicker(_light, _base, _flicker) {
    if (is_undefined(_light)) return;
    
    var noise = random_range(-_flicker, _flicker);
    _light.intensity = clamp(_base + noise, 0.0, 1.0);
}

/// scr_light_pulse(light, min_intensity, max_intensity, speed)
/// Tworzy efekt pulsowania światła (wywołuj w Step)
/// @param light - struktura światła
/// @param min_intensity - minimalna jasność
/// @param max_intensity - maksymalna jasność
/// @param speed - szybkość pulsowania (radiany na step, np. 0.05)
function scr_light_pulse(_light, _min, _max, _speed) {
    if (is_undefined(_light)) return;
    
    // Użyj timera wewnętrznego
    if (!variable_struct_exists(_light, "_pulse_timer")) {
        _light._pulse_timer = 0;
    }
    
    _light._pulse_timer += _speed;
    
    // Sinusoidalne pulsowanie
    var t = (sin(_light._pulse_timer) + 1) * 0.5; // 0.0 - 1.0
    _light.intensity = lerp(_min, _max, t);
}

// ============================================================================
// STEROWANIE WSZYSTKIMI ŚWIATŁAMI
// ============================================================================

/// scr_lights_set_all_intensity(intensity)
/// Ustawia jasność wszystkich świateł
function scr_lights_set_all_intensity(_intensity) {
    if (!variable_global_exists("lights")) return;
    
    var count = ds_list_size(global.lights);
    for (var i = 0; i < count; i++) {
        var light = global.lights[| i];
        scr_light_set_intensity(light, _intensity);
    }
}

/// scr_lights_turn_all_on()
/// Włącza wszystkie światła
function scr_lights_turn_all_on() {
    scr_lights_set_all_intensity(1.0);
}

/// scr_lights_turn_all_off()
/// Wyłącza wszystkie światła
function scr_lights_turn_all_off() {
    scr_lights_set_all_intensity(0.0);
}
