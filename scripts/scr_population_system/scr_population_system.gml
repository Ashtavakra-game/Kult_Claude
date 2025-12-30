/// =============================================================================
/// BORUTA - SYSTEM WSKAŹNIKÓW POPULACJI
/// =============================================================================
/// Trzy główne wskaźniki: Wiara w Stare Mity, Strach, Szaleństwo
/// Funkcja logistyczna określa wzajemne relacje między wskaźnikami
/// =============================================================================

// =============================================================================
// INICJALIZACJA SYSTEMU
// =============================================================================

/// scr_population_system_init()
/// Inicjalizacja systemu - wywołaj w o_game Create
function scr_population_system_init() {
    // === GŁÓWNE WSKAŹNIKI POPULACJI ===
    global.myth_faith = 0;          // Wiara w Stare Mity (0-100) - CEL GRY
    global.collective_fear = 0;     // Strach Zbiorowy (0-100)
    global.collective_madness = 0;  // Szaleństwo (0-100)

    // === LIMITY ===
    global.myth_faith_max = 100;
    global.fear_max = 100;
    global.madness_max = 100;

    // === PROGI FUNKCJI LOGISTYCZNEJ ===
    global.fear_optimal_low = 20;      // początek optymalnego zakresu
    global.fear_optimal_peak = 40;     // szczyt podatności
    global.fear_optimal_high = 60;     // koniec optymalnego zakresu
    global.fear_critical = 70;         // powyżej = szaleństwo rośnie szybko

    // === TEMPO ZMIAN (na tick nocny) ===
    global.wsm_decay_rate = 0.1;       // naturalny spadek WSM
    global.fear_decay_rate = 0.3;      // naturalny spadek strachu
    global.madness_decay_rate = 0.05;  // bardzo wolny spadek szaleństwa

    // === FLAGI STANU GRY ===
    global.game_won = false;
    global.game_lost = false;
    global.game_lost_reason = "";
    global.win_counter = 0;            // ile nocy z rzędu warunek wygranej
    global.lose_counter = 0;           // ile nocy z rzędu warunek przegranej

    show_debug_message("=== POPULATION SYSTEM INITIALIZED ===");
}

// =============================================================================
// FUNKCJE LOGISTYCZNE
// =============================================================================

/// scr_logistic_susceptibility(fear)
/// Zwraca mnożnik podatności na WSM (0.0 - 1.0)
/// Krzywa dzwonowa - optimum w zakresie 20-60 strachu
///
/// Interpretacja narracyjna:
/// 0-20:  Niska podatność - "Ludzie pewni siebie, nie szukają wyjaśnień"
/// 20-35: Rosnąca - "Coś jest nie tak... może przodkowie wiedzieli więcej?"
/// 35-45: OPTYMALNA - "Złoty środek – otwarci na mity, nie sparaliżowani"
/// 45-60: Malejąca - "Strach zaczyna paraliżować, trudniej słuchać legend"
/// 60-100: Bardzo niska - "Panika! Szaleństwo! Nikt nie słucha"

function scr_logistic_susceptibility(_fear) {
    var low = global.fear_optimal_low;
    var high = global.fear_optimal_high;
    var k = 0.12; // stromość krzywej

    // Lewa strona krzywej (rosnąca)
    var left = 1 / (1 + exp(-k * (_fear - low)));

    // Prawa strona krzywej (malejąca)
    var right = 1 / (1 + exp(k * (_fear - high)));

    // Kombinacja daje krzywą dzwonową
    return clamp(left * right * 1.3, 0, 1);
}

/// scr_logistic_madness_growth(fear)
/// Zwraca przyrost szaleństwa na tick (0.0 - max)
/// Szaleństwo rośnie wykładniczo powyżej progu krytycznego

function scr_logistic_madness_growth(_fear) {
    var critical = global.fear_critical;
    var max_growth = 0.5;
    var k = 0.1;

    // Poniżej 80% progu krytycznego - brak przyrostu
    if (_fear < critical * 0.8) return 0;

    // Funkcja logistyczna dla przyrostu szaleństwa
    return max_growth / (1 + exp(-k * (_fear - (critical + 10))));
}

/// scr_logistic_fear_effectiveness(current_fear)
/// Zwraca skuteczność dodawania strachu (malejąca przy wysokim strachu)
/// Symuluje "nasycenie" - ludzie już tak przestraszeni, że więcej się nie da

function scr_logistic_fear_effectiveness(_fear) {
    var saturation = 80; // punkt nasycenia
    var k = 0.08;

    return 1 - (1 / (1 + exp(-k * (_fear - saturation))));
}

// =============================================================================
// MODYFIKACJA WSKAŹNIKÓW
// =============================================================================

/// scr_add_myth_faith(amount, source)
/// Dodaje WSM z uwzględnieniem podatności i kary za szaleństwo
/// @param _amount - bazowa ilość do dodania
/// @param _source - źródło (do debugowania)
/// @return actual_gain - faktycznie dodana wartość

function scr_add_myth_faith(_amount, _source) {
    // Podatność zależy od poziomu strachu (funkcja logistyczna!)
    var susceptibility = scr_logistic_susceptibility(global.collective_fear);

    // Szaleństwo zmniejsza przyrost (ludzie nie słuchają)
    var madness_penalty = 1 - (global.collective_madness / 150);
    madness_penalty = clamp(madness_penalty, 0.1, 1);

    // Oblicz faktyczny przyrost
    var actual_gain = _amount * susceptibility * madness_penalty;

    global.myth_faith = clamp(global.myth_faith + actual_gain, 0, global.myth_faith_max);

    show_debug_message("WSM +" + string(actual_gain) + " (base:" + string(_amount) +
        " x suscept:" + string(susceptibility) + " x madPen:" + string(madness_penalty) +
        ") from " + _source);

    return actual_gain;
}

/// scr_add_fear(amount, source)
/// Dodaje strach z uwzględnieniem nasycenia
/// @param _amount - bazowa ilość do dodania
/// @param _source - źródło (do debugowania)
/// @return actual_gain - faktycznie dodana wartość

function scr_add_fear(_amount, _source) {
    // Skuteczność maleje przy wysokim strachu (nasycenie)
    var effectiveness = scr_logistic_fear_effectiveness(global.collective_fear);
    var actual_gain = _amount * effectiveness;

    global.collective_fear = clamp(global.collective_fear + actual_gain, 0, global.fear_max);

    show_debug_message("FEAR +" + string(actual_gain) + " (base:" + string(_amount) +
        " x effect:" + string(effectiveness) + ") from " + _source);

    return actual_gain;
}

/// scr_add_madness(amount, source)
/// Dodaje szaleństwo (bez modyfikatorów)
/// @param _amount - ilość do dodania
/// @param _source - źródło (do debugowania)
/// @return amount - dodana wartość

function scr_add_madness(_amount, _source) {
    global.collective_madness = clamp(global.collective_madness + _amount, 0, global.madness_max);

    show_debug_message("MADNESS +" + string(_amount) + " from " + _source);

    return _amount;
}

// =============================================================================
// NOCNY TICK
// =============================================================================

/// scr_population_night_tick()
/// Wywołuj na koniec każdej nocy (przy zmianie fazy na dzień)
/// Obsługuje naturalny zanik, przyrost szaleństwa i warunki końca gry

function scr_population_night_tick() {
    show_debug_message("=== POPULATION NIGHT TICK ===");

    // 1. Naturalny zanik WSM (wiara chrześcijańska dominuje)
    global.myth_faith = max(0, global.myth_faith - global.wsm_decay_rate);

    // 2. Naturalny zanik strachu
    global.collective_fear = max(0, global.collective_fear - global.fear_decay_rate);

    // 3. Przyrost szaleństwa ze strachu (funkcja logistyczna!)
    var madness_growth = scr_logistic_madness_growth(global.collective_fear);
    if (madness_growth > 0) {
        scr_add_madness(madness_growth, "high_fear");
    }

    // 4. Bardzo wolny zanik szaleństwa
    global.collective_madness = max(0, global.collective_madness - global.madness_decay_rate);

    // 5. Sprawdź warunki wygranej/przegranej
    scr_check_win_lose_conditions();

    // Debug output
    show_debug_message("WSM: " + string(global.myth_faith) +
        " | FEAR: " + string(global.collective_fear) +
        " | MADNESS: " + string(global.collective_madness));
    show_debug_message("Susceptibility: " + string(scr_logistic_susceptibility(global.collective_fear)));
}

// =============================================================================
// WARUNKI WYGRANEJ / PRZEGRANEJ
// =============================================================================

/// scr_check_win_lose_conditions()
/// Sprawdza warunki końca gry

function scr_check_win_lose_conditions() {
    // === PROGI WYGRANEJ ===
    var WIN_THRESHOLD = 80;       // WSM >= 80%
    var WIN_NIGHTS_REQUIRED = 5;  // przez 5 nocy
    var WIN_MAX_MADNESS = 30;     // przy szaleństwie < 30%

    // === PROGI PRZEGRANEJ (brak wiary) ===
    var LOSE_WSM_THRESHOLD = 10;  // WSM <= 10%
    var LOSE_NIGHTS_REQUIRED = 7; // przez 7 nocy

    // === PRÓG PRZEGRANEJ (szaleństwo) ===
    var LOSE_MADNESS_THRESHOLD = 80; // szaleństwo >= 80%

    // --- SPRAWDŹ WYGRANĄ ---
    if (global.myth_faith >= WIN_THRESHOLD && global.collective_madness < WIN_MAX_MADNESS) {
        global.win_counter++;
        show_debug_message("WIN COUNTER: " + string(global.win_counter) + "/" + string(WIN_NIGHTS_REQUIRED));

        if (global.win_counter >= WIN_NIGHTS_REQUIRED) {
            global.game_won = true;
            show_debug_message("!!! GAME WON - STARA WIARA ODRODZIONA !!!");
        }
    } else {
        global.win_counter = 0;
    }

    // --- SPRAWDŹ PRZEGRANĄ (brak wiary) ---
    if (global.myth_faith <= LOSE_WSM_THRESHOLD) {
        global.lose_counter++;
        show_debug_message("LOSE COUNTER (low WSM): " + string(global.lose_counter) + "/" + string(LOSE_NIGHTS_REQUIRED));

        if (global.lose_counter >= LOSE_NIGHTS_REQUIRED) {
            global.game_lost = true;
            global.game_lost_reason = "forgotten";
            show_debug_message("!!! GAME LOST - MITY ZAPOMNIANE !!!");
        }
    } else {
        global.lose_counter = 0;
    }

    // --- SPRAWDŹ PRZEGRANĄ (szaleństwo) ---
    if (global.collective_madness >= LOSE_MADNESS_THRESHOLD) {
        global.game_lost = true;
        global.game_lost_reason = "madness";
        show_debug_message("!!! GAME LOST - WIOSKA OSZALALA !!!");
    }
}

// =============================================================================
// INTEGRACJA Z ENCOUNTERAMI
// =============================================================================

/// scr_encounter_affect_population(encounter_inst)
/// Wywołuj gdy NPC wchodzi w zasięg encountera
/// Aplikuje efekty encountera na globalne wskaźniki populacji

function scr_encounter_affect_population(_enc) {
    if (!instance_exists(_enc)) return;
    if (!variable_instance_exists(_enc, "encounter_data")) return;
    if (is_undefined(_enc.encounter_data)) return;

    var ed = _enc.encounter_data;

    // Sprawdź czy encounter jest aktywny
    if (variable_struct_exists(ed, "active") && !ed.active) return;

    // Sprawdź czy aktywna faza dnia
    if (variable_struct_exists(ed, "active_phases") && variable_global_exists("daynight_phase")) {
        var current_phase = global.daynight_phase;
        var is_active_phase = false;
        for (var i = 0; i < array_length(ed.active_phases); i++) {
            if (ed.active_phases[i] == current_phase) {
                is_active_phase = true;
                break;
            }
        }
        if (!is_active_phase) return;
    }

    // Aplikuj efekty na wskaźniki globalne
    if (variable_struct_exists(ed, "wsm_bonus") && ed.wsm_bonus > 0) {
        scr_add_myth_faith(ed.wsm_bonus, "encounter_" + string(ed.typ));
    }

    if (variable_struct_exists(ed, "fear_bonus") && ed.fear_bonus > 0) {
        scr_add_fear(ed.fear_bonus, "encounter_" + string(ed.typ));
    }

    if (variable_struct_exists(ed, "madness_bonus") && ed.madness_bonus > 0) {
        scr_add_madness(ed.madness_bonus, "encounter_" + string(ed.typ));
    }

    // Reset licznika nieaktywności
    if (variable_struct_exists(ed, "days_inactive")) {
        ed.days_inactive = 0;
    }
}

// =============================================================================
// POMOCNICZE FUNKCJE
// =============================================================================

/// scr_get_susceptibility_description()
/// Zwraca tekstowy opis aktualnej podatności

function scr_get_susceptibility_description() {
    var fear = global.collective_fear;

    if (fear < 20) {
        return "Ludzie pewni siebie";
    } else if (fear < 35) {
        return "Rosnie niepewnosc";
    } else if (fear < 45) {
        return "OPTYMALNA podatnosc";
    } else if (fear < 60) {
        return "Strach paralizuje";
    } else {
        return "Panika i chaos";
    }
}

/// scr_get_fear_zone()
/// Zwraca strefę strachu: "low", "optimal", "high", "critical"

function scr_get_fear_zone() {
    var fear = global.collective_fear;

    if (fear < global.fear_optimal_low) {
        return "low";
    } else if (fear < global.fear_optimal_high) {
        return "optimal";
    } else if (fear < global.fear_critical) {
        return "high";
    } else {
        return "critical";
    }
}
