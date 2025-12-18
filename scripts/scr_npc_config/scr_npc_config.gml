/// =============================================================================
/// SCR_NPC_CONFIG - KONFIGURACJA I TESTOWANIE ZACHOWAŃ NPC
/// WERSJA 3.0 - Z CYKLEM DNIA I KARCZMĄ
/// =============================================================================
/// Miejsce do ręcznego ustawiania modyfikatorów i parametrów testowych.
/// Importuj ten skrypt i wywołaj scr_npc_config_init() w Create event kontrolera gry.
/// =============================================================================

/// ----------------------------------------------------------------------------
/// GLOBALNE MODYFIKATORY (wpływają na WSZYSTKICH NPC)
/// Użyj do szybkiego testowania zmian zachowań
/// ----------------------------------------------------------------------------
function scr_npc_config_init()
{
    // =========================================================================
    // MODYFIKATORY GLOBALNE - ZMIEŃ TE WARTOŚCI DO TESTÓW
    // =========================================================================
    
    global.npc_mod = {
        // PRACA
        pracowitosc: 0,        // -100 do +100, dodawane do bazowej cechy
        
        // EKSPLORACJA
        wanderlust: 0,         // -100 do +100, wpływa na max dystans od osady
        roztargnienie: 0,      // -100 do +100, szansa na zbaczanie z trasy
        
        // ENCOUNTERY
        ciekawosc: 0,          // -100 do +100, szansa na przekierowanie
        podatnosc: 0,          // -100 do +100, łatwość nawrócenia
        
        // KULT
        devotion: 0,           // -100 do +100, preferencja encounterów dla kultystów
        fanatyzm: 0,           // -100 do +100, odporność na utratę statusu sługi
        
        // TOWARZYSKOŚĆ (NOWE)
        towarzyskosc: 0,       // -100 do +100, szansa na karczmę
        
        // CZAS (mnożniki, 1.0 = normalny)
        czas_pracy_mult: 1.0,
        czas_interakcji_mult: 1.0,
        czas_odpoczynku_mult: 1.0,
        czas_eksploracji_mult: 1.0,
        
        // NOC
        szansa_wyjscia_noc: 90, // 0-100, bazowo NPC nie wychodzą w nocy
    };
    
    // =========================================================================
    // PARAMETRY BAZOWE SYSTEMU - DO BALANSOWANIA
    // =========================================================================
    
    global.npc_base = {
        // PRACA - wzór: szansa = praca_min + pracowitosc * praca_scale
        praca_min: 30,              // minimalna szansa na pracę (przy pracowitosc=0)
        praca_scale: 0.5,           // skalowanie (przy pracowitosc=100: 30+50=80%)
        
        // EKSPLORACJA - wzór: szansa = ekspl_min + (100-pracowitosc) * ekspl_scale
        ekspl_min: 10,              // minimalna szansa na eksplorację
        ekspl_scale: 0.3,           // skalowanie
        
        // WANDERLUST - wzór: max_dystans = dystans_min + wanderlust * dystans_scale
        dystans_min: 100,           // minimalny zasięg (px)
        dystans_scale: 4,           // skalowanie (przy wanderlust=100: 100+400=500px)
        dystans_penalty_scale: 0.02,// jak szybko spada szansa z dystansem
        
        // CIEKAWOŚĆ - wzór: szansa = ciekawosc * ciekawosc_scale + sila * sila_bonus
        ciekawosc_scale: 0.8,
        sila_bonus: 10,
        
        // ROZTARGNIENIE - wzór: szansa zboczenia = roztargnienie * roztarg_scale
        roztarg_scale: 0.5,
        roztarg_check_interval: 30, // co ile kroków sprawdzać zboczenie
        roztarg_max_offset: 48,     // max odchylenie od trasy (px)
        
        // KULT - utrata statusu gdy czas_bez_encountera > fanatyzm * utrata_scale
        utrata_scale: 10,           // sekundy na punkt fanatyzmu
        
        // CZASY BAZOWE (w sekundach, mnożone przez room_speed)
        czas_odpoczynku_min: 5,
        czas_odpoczynku_max: 15,
        czas_eksploracji_min: 3,
        czas_eksploracji_max: 8,
        
        // IDLE - szanse gdy NPC nie ma celu (sumują się do reszty po pracy)
        idle_wander_weight: 20,     // wander w pobliżu
        idle_explore_weight: 15,    // eksploracja daleko
        idle_wait_weight: 15,       // czekanie
        
        // =====================================================================
        // NOWE - PODRÓŻ (TRAVEL)
        // =====================================================================
        
        // Bazowa szansa na podróż rano (10%)
        travel_base_chance: 10,
        // Bonus do szansy na podróż za każdy punkt wanderlust (0.3 = 30% max bonus)
        travel_wanderlust_scale: 0.3,
        
        // =====================================================================
        // NOWE - KARCZMA (TAVERN)
        // =====================================================================
        
        // Bazowa szansa na odwiedzenie karczmy wieczorem
        tavern_base_chance: 20,
        // Bonus za towarzyskość (0.4 = +40% przy towarzyskość=100)
        tavern_towarzyskosc_scale: 0.4,
        
        // Czas w karczmie (w sekundach)
        czas_karczmy_min: 10,       // normalny pobyt
        czas_karczmy_max: 30,
        
        // Czas w karczmie jeśli zostaje do rana (bardzo długo!)
        czas_karczmy_late_min: 60,  // do 1-2 minut realnego czasu
        czas_karczmy_late_max: 120,
        
        // Szansa na zostanie do rana
        stay_late_base_chance: 10,  // bazowo 10%
        stay_late_towarzyskosc_scale: 0.2, // +20% przy towarzyskość=100
    };
    
    // =========================================================================
    // DEBUG FLAGS
    // =========================================================================
    
    global.npc_debug = {
        show_encounter_ranges: true,    // rysuj okręgi zasięgów encounterów
        show_npc_targets: false,        // rysuj linie do celów NPC
        show_decision_logs: true,       // loguj decyzje NPC
        show_path_deviation: false,     // rysuj zboczenia ze ścieżki
        show_tavern_info: true,         // NOWE - info o karczmie w logu
        
        // kolor okręgów encounterów
        encounter_range_color: c_red,
        encounter_range_alpha: 0.3,
    };
    
    show_debug_message("=== NPC CONFIG INITIALIZED (v3.0 z karczmą) ===");
}

/// ----------------------------------------------------------------------------
/// FUNKCJE POMOCNICZE DO TESTOWANIA W RUNTIME
/// ----------------------------------------------------------------------------

/// Ustaw globalny modyfikator dla wszystkich NPC
/// Przykład: scr_npc_set_global_mod("pracowitosc", 50);
function scr_npc_set_global_mod(_trait, _value)
{
    if (variable_struct_exists(global.npc_mod, _trait)) {
        variable_struct_set(global.npc_mod, _trait, _value);
        show_debug_message("NPC_MOD: " + _trait + " = " + string(_value));
    } else {
        show_debug_message("NPC_MOD ERROR: Nieznana cecha: " + _trait);
    }
}

/// Ustaw modyfikator dla konkretnego NPC
/// Przykład: scr_npc_set_individual_mod(npc_instance, "ciekawosc", 30);
function scr_npc_set_individual_mod(_inst, _trait, _value)
{
    if (!instance_exists(_inst)) return;
    if (is_undefined(_inst.npc_data)) return;
    
    if (variable_struct_exists(_inst.npc_data.modifiers, _trait)) {
        variable_struct_set(_inst.npc_data.modifiers, _trait, _value);
        show_debug_message("NPC " + string(_inst.id) + " MOD: " + _trait + " = " + string(_value));
    }
}

/// Zresetuj wszystkie globalne modyfikatory do 0
function scr_npc_reset_global_mods()
{
    global.npc_mod.pracowitosc = 0;
    global.npc_mod.wanderlust = 0;
    global.npc_mod.roztargnienie = 0;
    global.npc_mod.ciekawosc = 0;
    global.npc_mod.podatnosc = 0;
    global.npc_mod.devotion = 0;
    global.npc_mod.fanatyzm = 0;
    global.npc_mod.towarzyskosc = 0;
    global.npc_mod.czas_pracy_mult = 1.0;
    global.npc_mod.czas_interakcji_mult = 1.0;
    global.npc_mod.czas_odpoczynku_mult = 1.0;
    global.npc_mod.czas_eksploracji_mult = 1.0;
    global.npc_mod.szansa_wyjscia_noc = 0;
    
    show_debug_message("=== GLOBAL MODS RESET ===");
}

/// Wypisz stan NPC do debuggera
function scr_npc_debug_print(_inst)
{
    if (!instance_exists(_inst)) return;
    if (is_undefined(_inst.npc_data)) return;
    
    var nd = _inst.npc_data;
    var t = nd.traits;
    
    show_debug_message("====== NPC " + string(_inst.id) + " DEBUG ======");
    show_debug_message("State: " + nd.state);
    show_debug_message("Daily Plan: " + nd.daily_plan);
    show_debug_message("Sluga: " + string(t.sluga));
    show_debug_message("--- TRAITS (effective) ---");
    show_debug_message("  pracowitosc: " + string(scr_npc_get_effective(_inst, "pracowitosc")));
    show_debug_message("  wanderlust: " + string(scr_npc_get_effective(_inst, "wanderlust")));
    show_debug_message("  roztargnienie: " + string(scr_npc_get_effective(_inst, "roztargnienie")));
    show_debug_message("  ciekawosc: " + string(scr_npc_get_effective(_inst, "ciekawosc")));
    show_debug_message("  podatnosc: " + string(scr_npc_get_effective(_inst, "podatnosc")));
    show_debug_message("  devotion: " + string(scr_npc_get_effective(_inst, "devotion")));
    show_debug_message("  fanatyzm: " + string(scr_npc_get_effective(_inst, "fanatyzm")));
    show_debug_message("  towarzyskosc: " + string(scr_npc_get_effective(_inst, "towarzyskosc")));
    show_debug_message("--- DAILY FLAGS ---");
    show_debug_message("  plan_decided: " + string(nd.plan_decided));
    show_debug_message("  work_done_today: " + string(nd.work_done_today));
    show_debug_message("  travel_done_today: " + string(nd.travel_done_today));
    show_debug_message("  visited_tavern_today: " + string(nd.visited_tavern_today));
    show_debug_message("  staying_late: " + string(nd.staying_late));
    show_debug_message("--- TIMERS ---");
    show_debug_message("  czas_bez_encountera: " + string(t.czas_bez_encountera / room_speed) + "s");
    show_debug_message("==========================================");
}

/// ----------------------------------------------------------------------------
/// PRESETS - SZYBKIE PROFILE TESTOWE
/// ----------------------------------------------------------------------------

/// Ustaw preset "pracowity" - NPC skupiony na pracy
function scr_npc_preset_pracowity()
{
    scr_npc_set_global_mod("pracowitosc", 40);
    scr_npc_set_global_mod("wanderlust", -30);
    scr_npc_set_global_mod("ciekawosc", -20);
    scr_npc_set_global_mod("towarzyskosc", -10);
    show_debug_message("PRESET: Pracowity");
}

/// Ustaw preset "eksplorator" - NPC wędrujący daleko
function scr_npc_preset_eksplorator()
{
    scr_npc_set_global_mod("pracowitosc", -30);
    scr_npc_set_global_mod("wanderlust", 50);
    scr_npc_set_global_mod("roztargnienie", 30);
    scr_npc_set_global_mod("towarzyskosc", 20);
    show_debug_message("PRESET: Eksplorator");
}

/// Ustaw preset "mistyk" - NPC przyciągany do encounterów
function scr_npc_preset_mistyk()
{
    scr_npc_set_global_mod("ciekawosc", 50);
    scr_npc_set_global_mod("podatnosc", 30);
    scr_npc_set_global_mod("pracowitosc", -20);
    show_debug_message("PRESET: Mistyk");
}

/// Ustaw preset "fanatyk" - kultysta oddany encounterom
function scr_npc_preset_fanatyk()
{
    scr_npc_set_global_mod("devotion", 60);
    scr_npc_set_global_mod("fanatyzm", 40);
    scr_npc_set_global_mod("ciekawosc", 30);
    show_debug_message("PRESET: Fanatyk");
}

/// NOWY preset "imprezowicz" - NPC lubiący karczmę
function scr_npc_preset_imprezowicz()
{
    scr_npc_set_global_mod("towarzyskosc", 50);
    scr_npc_set_global_mod("pracowitosc", -20);
    scr_npc_set_global_mod("wanderlust", 20);
    show_debug_message("PRESET: Imprezowicz");
}

/// NOWY preset "domator" - NPC rzadko odwiedzający karczmę
function scr_npc_preset_domator()
{
    scr_npc_set_global_mod("towarzyskosc", -40);
    scr_npc_set_global_mod("pracowitosc", 30);
    scr_npc_set_global_mod("wanderlust", -30);
    show_debug_message("PRESET: Domator");
}
