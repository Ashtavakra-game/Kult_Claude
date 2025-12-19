/// =============================================================================
/// BORUTA - SYSTEM CYROGRAFÓW (SŁUG) W KARCZMIE
/// =============================================================================
/// Mechanika pozyskiwania sług poprzez negocjacje w karczmie
/// =============================================================================

// =============================================================================
// KONFIGURACJA SYSTEMU CYROGRAFÓW
// =============================================================================

#macro CYROGRAF_BASE_COST 5           // Bazowy koszt EC za próbę negocjacji
#macro CYROGRAF_SUCCESS_BONUS_EC 10   // Bonus EC za udane pozyskanie sługi
#macro CYROGRAF_EC_PER_NIGHT 2        // EC generowane przez sługę na noc

#macro CYROGRAF_BASE_CHANCE 20        // Bazowa szansa sukcesu (%)
#macro CYROGRAF_PODATNOSC_SCALE 0.5   // Mnożnik podatności (50 podatności = +25%)
#macro CYROGRAF_STRES_SCALE 0.3       // Mnożnik stresu (wysoki stres ułatwia)
#macro CYROGRAF_DEVOTION_PENALTY 0.4  // Kara za wysoką devotion (trudniej przekonać wierzącego)
#macro CYROGRAF_DRUNK_BONUS 15        // Bonus jeśli NPC jest "pijany" (długo w karczmie)

// Kolory UI
#macro CYROGRAF_UI_BG $1a1a2e
#macro CYROGRAF_UI_BORDER $4a3a6a
#macro CYROGRAF_UI_TEXT $e0e0e0
#macro CYROGRAF_UI_HIGHLIGHT $ff6699
#macro CYROGRAF_UI_SUCCESS $66ff66
#macro CYROGRAF_UI_FAIL $ff6666
#macro CYROGRAF_UI_SLUGA $cc33ff

// =============================================================================
// INICJALIZACJA (dodaj do scr_trait_system_init lub o_game Create)
// =============================================================================

/// scr_cyrograf_system_init()
/// Inicjalizuje system cyrografów
function scr_cyrograf_system_init() {
    // Lista aktywnych sług (dla szybkiego dostępu)
    if (!variable_global_exists("slugi") || is_undefined(global.slugi)) {
        global.slugi = ds_list_create();
    }
    
    // Statystyki
    global.cyrograf_stats = {
        total_attempts: 0,
        successful: 0,
        failed: 0,
        total_ec_spent: 0,
        total_ec_earned: 0
    };
    
    show_debug_message("CYROGRAF: System initialized");
}

/// scr_cyrograf_system_cleanup()
/// Czyści zasoby systemu
function scr_cyrograf_system_cleanup() {
    if (variable_global_exists("slugi") && ds_exists(global.slugi, ds_type_list)) {
        ds_list_destroy(global.slugi);
    }
}

// =============================================================================
// POBIERANIE GOŚCI KARCZMY
// =============================================================================

/// scr_tavern_get_visitors_detailed(_tavern)
/// Zwraca tablicę gości z dodatkowymi danymi do UI
function scr_tavern_get_visitors_detailed(_tavern) {
    var visitors = [];
    if (!variable_global_exists("npcs") || is_undefined(global.npcs)) return visitors;
    
    var n = ds_list_size(global.npcs);
    
    for (var i = 0; i < n; i++) {
        var npc = global.npcs[| i];
        if (!instance_exists(npc)) continue;
        if (!variable_instance_exists(npc, "npc_data") || is_undefined(npc.npc_data)) continue;
        
        var nd = npc.npc_data;
        
        if (nd.state == "at_tavern") {
            var dist = point_distance(npc.x, npc.y, _tavern.x, _tavern.y);
            if (dist < 100) {
                // Oblicz dane do wyświetlenia
                var podatnosc = scr_npc_trait(npc, "podatnosc");
                var devotion = scr_npc_trait(npc, "devotion");
                var stres = nd.traits.stres;
                var is_sluga = nd.traits.sluga;
                var staying_late = nd.staying_late;
                
                // Oblicz szansę na sukces
                var chance = scr_cyrograf_calc_success_chance(npc);
                
                // Określ "nastrój" NPC
                var mood = "neutralny";
                if (staying_late) mood = "podchmielony";
                if (stres > 50) mood = "zestresowany";
                if (devotion > 60) mood = "pobozny";
                if (is_sluga) mood = "sluga";
                
                var visitor_data = {
                    npc_inst: npc,
                    npc_id: npc.id,
                    kind: nd.kind,
                    podatnosc: podatnosc,
                    devotion: devotion,
                    stres: stres,
                    is_sluga: is_sluga,
                    staying_late: staying_late,
                    success_chance: chance,
                    mood: mood
                };
                
                array_push(visitors, visitor_data);
            }
        }
    }
    
    return visitors;
}

// =============================================================================
// OBLICZANIE SZANSY NA SUKCES
// =============================================================================

/// scr_cyrograf_calc_success_chance(npc_inst)
/// Oblicza szansę na udane pozyskanie sługi (0-100)
function scr_cyrograf_calc_success_chance(_npc) {
    if (!instance_exists(_npc)) return 0;
    if (!variable_instance_exists(_npc, "npc_data") || is_undefined(_npc.npc_data)) return 0;
    
    var nd = _npc.npc_data;
    
    // Już jest sługą - nie można ponownie
    if (nd.traits.sluga) return 0;
    
    // Bazowa szansa
    var chance = CYROGRAF_BASE_CHANCE;
    
    // Podatność zwiększa szansę
    var podatnosc = scr_npc_trait(_npc, "podatnosc");
    chance += podatnosc * CYROGRAF_PODATNOSC_SCALE;
    
    // Stres zwiększa szansę (zdesperowani łatwiej się zgadzają)
    var stres = nd.traits.stres;
    chance += stres * CYROGRAF_STRES_SCALE;
    
    // Devotion (wiara) zmniejsza szansę
    var devotion = scr_npc_trait(_npc, "devotion");
    chance -= devotion * CYROGRAF_DEVOTION_PENALTY;
    
    // Bonus za "podchmielenie" (długi pobyt w karczmie)
    if (nd.staying_late) {
        chance += CYROGRAF_DRUNK_BONUS;
    }
    
    // Bonus za niskie zdrowie psychiczne
    var zdrowie_psych = nd.traits.zdrowie_psych;
    if (zdrowie_psych < 50) {
        chance += (50 - zdrowie_psych) * 0.3;
    }
    
    // Clamp do rozsądnych wartości
    return clamp(chance, 5, 95);
}

// =============================================================================
// PRÓBA NEGOCJACJI (POZYSKANIE SŁUGI)
// =============================================================================

/// scr_cyrograf_attempt_negotiation(npc_inst)
/// Próbuje przekonać NPC do podpisania cyrografu
/// Zwraca struct z wynikiem: { success, message, ec_change }
function scr_cyrograf_attempt_negotiation(_npc) {
    var result = {
        success: false,
        message: "",
        ec_change: 0,
        chance_was: 0
    };
    
    // === WALIDACJA ===
    
    // Sprawdź czy to noc
    if (!scr_trait_is_night()) {
        result.message = "Negocjacje mozliwe tylko w nocy!";
        return result;
    }
    
    // Sprawdź czy NPC istnieje i ma dane
    if (!instance_exists(_npc)) {
        result.message = "NPC nie istnieje!";
        return result;
    }
    
    if (!variable_instance_exists(_npc, "npc_data") || is_undefined(_npc.npc_data)) {
        result.message = "Brak danych NPC!";
        return result;
    }
    
    var nd = _npc.npc_data;
    
    // Sprawdź czy NPC jest w karczmie
    if (nd.state != "at_tavern") {
        result.message = "NPC musi byc w karczmie!";
        return result;
    }
    
    // Sprawdź czy już nie jest sługą
    if (nd.traits.sluga) {
        result.message = "Ten NPC juz jest Twym sluga!";
        return result;
    }
    
    // Sprawdź czy stać gracza
    if (!scr_dark_essence_can_afford(CYROGRAF_BASE_COST)) {
        result.message = "Za malo Esencji Ciemnosci! (potrzeba " + string(CYROGRAF_BASE_COST) + " EC)";
        return result;
    }
    
    // === WYKONAJ PRÓBĘ ===
    
    // Pobierz koszt (wydaj EC)
    scr_dark_essence_spend(CYROGRAF_BASE_COST);
    result.ec_change = -CYROGRAF_BASE_COST;
    
    // Oblicz szansę
    var chance = scr_cyrograf_calc_success_chance(_npc);
    result.chance_was = chance;
    
    // Rzut kością
    var roll = irandom(100);
    
    // Aktualizuj statystyki
    global.cyrograf_stats.total_attempts++;
    global.cyrograf_stats.total_ec_spent += CYROGRAF_BASE_COST;
    
    // === SUKCES ===
    if (roll < chance) {
        // Oznacz jako sługę
        nd.traits.sluga = true;
        nd.traits.czas_bez_encountera = 0;
        
        // Zwiększ devotion (teraz służy Borucie)
        nd.modifiers.devotion += 20;
        
        // Dodaj do listy sług
        if (!ds_list_find_index(global.slugi, _npc) >= 0) {
            ds_list_add(global.slugi, _npc);
        }
        
        // Bonus EC za sukces
        scr_dark_essence_add(CYROGRAF_SUCCESS_BONUS_EC);
        result.ec_change += CYROGRAF_SUCCESS_BONUS_EC;
        
        // Aktualizuj statystyki
        global.cyrograf_stats.successful++;
        
        result.success = true;
        result.message = "CYROGRAF PODPISANY! NPC " + string(_npc.id) + " jest teraz Twym sluga!";
        
        show_debug_message("CYROGRAF: SUCCESS! NPC " + string(_npc.id) + 
            " became sluga (roll=" + string(roll) + " < chance=" + string(chance) + ")");
        
        // Wywołaj event grzechu (dla systemu EC)
        scr_trait_on_sin_committed(_npc, "cyrograf");
        
    // === PORAŻKA ===
    } else {
        // NPC odmówił - zwiększ jego odporność (trudniej następnym razem)
        nd.modifiers.podatnosc -= 10;
        nd.modifiers.devotion += 5;
        
        // Może zwiększyć stres NPC
        nd.traits.stres += 10;
        
        // Aktualizuj statystyki
        global.cyrograf_stats.failed++;
        
        result.success = false;
        result.message = "NPC odmowil! (rzut " + string(roll) + " >= szansa " + string(floor(chance)) + "%)";
        
        show_debug_message("CYROGRAF: FAILED! NPC " + string(_npc.id) + 
            " refused (roll=" + string(roll) + " >= chance=" + string(chance) + ")");
    }
    
    return result;
}

// =============================================================================
// ZARZĄDZANIE SŁUGAMI
// =============================================================================

/// scr_cyrograf_get_sluga_count()
/// Zwraca liczbę aktywnych sług
function scr_cyrograf_get_sluga_count() {
    if (!variable_global_exists("slugi") || is_undefined(global.slugi)) return 0;
    
    // Wyczyść nieistniejące instancje
    for (var i = ds_list_size(global.slugi) - 1; i >= 0; i--) {
        var npc = global.slugi[| i];
        if (!instance_exists(npc) || is_undefined(npc.npc_data) || !npc.npc_data.traits.sluga) {
            ds_list_delete(global.slugi, i);
        }
    }
    
    return ds_list_size(global.slugi);
}

/// scr_cyrograf_release_sluga(npc_inst)
/// Zwalnia sługę (usuwa status)
function scr_cyrograf_release_sluga(_npc) {
    if (!instance_exists(_npc)) return false;
    if (!variable_instance_exists(_npc, "npc_data") || is_undefined(_npc.npc_data)) return false;
    
    var nd = _npc.npc_data;
    
    if (!nd.traits.sluga) return false;
    
    nd.traits.sluga = false;
    nd.traits.czas_bez_encountera = 0;
    nd.modifiers.devotion -= 20;
    
    // Usuń z listy
    var idx = ds_list_find_index(global.slugi, _npc);
    if (idx >= 0) {
        ds_list_delete(global.slugi, idx);
    }
    
    show_debug_message("CYROGRAF: Released sluga NPC " + string(_npc.id));
    return true;
}

/// scr_cyrograf_generate_nightly_ec()
/// Generuje EC od wszystkich sług (wywołaj w nocnym tick)
function scr_cyrograf_generate_nightly_ec() {
    var count = scr_cyrograf_get_sluga_count();
    if (count <= 0) return 0;
    
    var ec = count * CYROGRAF_EC_PER_NIGHT;
    scr_dark_essence_add(ec);
    
    global.cyrograf_stats.total_ec_earned += ec;
    
    show_debug_message("CYROGRAF: Generated " + string(ec) + " EC from " + string(count) + " slugi");
    return ec;
}

// =============================================================================
// UI - PANEL KARCZMY
// =============================================================================

#macro TAVERN_UI_PANEL_WIDTH 400
#macro TAVERN_UI_PANEL_HEIGHT 450
#macro TAVERN_UI_MARGIN 12
#macro TAVERN_UI_LINE_HEIGHT 24
#macro TAVERN_UI_NPC_HEIGHT 70

/// scr_ui_draw_tavern_panel(tavern_inst, x, y)
/// Rysuje panel karczmy z listą gości i opcją negocjacji
function scr_ui_draw_tavern_panel(_tavern, _x, _y) {
    if (!instance_exists(_tavern)) return;
    
    var w = TAVERN_UI_PANEL_WIDTH;
    var h = TAVERN_UI_PANEL_HEIGHT;
    var m = TAVERN_UI_MARGIN;
    var lh = TAVERN_UI_LINE_HEIGHT;
    
    // === TŁO ===
    draw_set_alpha(0.95);
    draw_rectangle_color(_x, _y, _x + w, _y + h,
        CYROGRAF_UI_BG, CYROGRAF_UI_BG, CYROGRAF_UI_BG, CYROGRAF_UI_BG, false);
    draw_set_alpha(1);
    
    // Ramka
    draw_rectangle_color(_x, _y, _x + w, _y + h,
        CYROGRAF_UI_BORDER, CYROGRAF_UI_BORDER, CYROGRAF_UI_BORDER, CYROGRAF_UI_BORDER, true);
    
    // === NAGŁÓWEK ===
    draw_set_color(CYROGRAF_UI_HIGHLIGHT);
    draw_set_halign(fa_center);
    draw_text(_x + w/2, _y + m, "KARCZMA");
    
    // Esencja Ciemności (prawy górny róg)
    draw_set_halign(fa_right);
    draw_set_color($ff66ff);
    draw_text(_x + w - m, _y + m, "EC: " + string(floor(global.dark_essence)));
    
    // Liczba sług
    draw_set_color(CYROGRAF_UI_SLUGA);
    draw_text(_x + w - m, _y + m + lh, "Slugi: " + string(scr_cyrograf_get_sluga_count()));
    
    draw_set_halign(fa_left);
    
    // Linia pod nagłówkiem
    var header_y = _y + m + lh + 10;
    draw_line_color(_x + m, header_y, _x + w - m, header_y, CYROGRAF_UI_BORDER, CYROGRAF_UI_BORDER);
    
    // === LISTA GOŚCI ===
    var list_y = header_y + m;
    
    draw_set_color(CYROGRAF_UI_TEXT);
    draw_text(_x + m, list_y, "Goscie w karczmie:");
    list_y += lh;
    
    // Sprawdź czy jest noc
    var is_night = scr_trait_is_night();
    
    if (!is_night) {
        draw_set_color(CYROGRAF_UI_FAIL);
        draw_text(_x + m, list_y, "(Negocjacje mozliwe tylko w nocy)");
        list_y += lh;
    }
    
    // Pobierz gości
    var visitors = scr_tavern_get_visitors_detailed(_tavern);
    var visitor_count = array_length(visitors);
    
    if (visitor_count == 0) {
        draw_set_color($888888);
        draw_text(_x + m, list_y, "(Brak gosci)");
    } else {
        // Zapisz dane do interakcji
        with (obj_ui_controller) {
            ui_tavern_visitors = visitors;
        }
        
        for (var i = 0; i < visitor_count; i++) {
            var v = visitors[i];
            var npc_y = list_y + i * TAVERN_UI_NPC_HEIGHT;
            
            // Tło NPC (podświetlenie przy hover)
            var mx = device_mouse_x_to_gui(0);
            var my = device_mouse_y_to_gui(0);
            var hover = point_in_rectangle(mx, my, _x + m, npc_y, _x + w - m, npc_y + TAVERN_UI_NPC_HEIGHT - 4);
            
            if (hover && !v.is_sluga && is_night) {
                draw_set_alpha(0.3);
                draw_rectangle_color(_x + m, npc_y, _x + w - m, npc_y + TAVERN_UI_NPC_HEIGHT - 4,
                    CYROGRAF_UI_HIGHLIGHT, CYROGRAF_UI_HIGHLIGHT, CYROGRAF_UI_HIGHLIGHT, CYROGRAF_UI_HIGHLIGHT, false);
                draw_set_alpha(1);
            }
            
            // Ramka NPC
            var border_color = v.is_sluga ? CYROGRAF_UI_SLUGA : CYROGRAF_UI_BORDER;
            draw_rectangle_color(_x + m, npc_y, _x + w - m, npc_y + TAVERN_UI_NPC_HEIGHT - 4,
                border_color, border_color, border_color, border_color, true);
            
            // Nazwa / ID
            draw_set_color(v.is_sluga ? CYROGRAF_UI_SLUGA : CYROGRAF_UI_TEXT);
            var name_str = "NPC #" + string(v.npc_id);
            if (v.kind != "") name_str = string(v.kind) + " #" + string(v.npc_id);
            draw_text(_x + m + 8, npc_y + 4, name_str);
            
            // Status sługi
            if (v.is_sluga) {
                draw_set_color(CYROGRAF_UI_SLUGA);
                draw_text(_x + w - m - 60, npc_y + 4, "[SLUGA]");
            }
            
            // Statystyki
            draw_set_color($aaaaaa);
            var stat_y = npc_y + lh;
            draw_text(_x + m + 8, stat_y, "Podatnosc: " + string(floor(v.podatnosc)) + 
                "  Devotion: " + string(floor(v.devotion)) +
                "  Stres: " + string(floor(v.stres)));
            
            // Nastrój i szansa
            stat_y += lh - 4;
            draw_set_color($888888);
            draw_text(_x + m + 8, stat_y, "Nastroj: " + v.mood);
            
            // Szansa na sukces (tylko jeśli nie jest sługą)
            if (!v.is_sluga) {
                var chance_color = CYROGRAF_UI_FAIL;
                if (v.success_chance >= 50) chance_color = CYROGRAF_UI_SUCCESS;
                else if (v.success_chance >= 30) chance_color = $ffff66;
                
                draw_set_color(chance_color);
                draw_set_halign(fa_right);
                draw_text(_x + w - m - 8, stat_y, "Szansa: " + string(floor(v.success_chance)) + "%");
                draw_set_halign(fa_left);
            }
        }
    }
    
    // === INSTRUKCJE ===
    var instr_y = _y + h - lh - m;
    draw_set_color($888888);
    draw_set_halign(fa_center);
    
    if (is_night && visitor_count > 0) {
        draw_text(_x + w/2, instr_y, "[Kliknij NPC] Negocjuj cyrograf (" + string(CYROGRAF_BASE_COST) + " EC) | [ESC] Zamknij");
    } else {
        draw_text(_x + w/2, instr_y, "[ESC] Zamknij");
    }
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

// =============================================================================
// UI - OBSŁUGA INPUT W PANELU KARCZMY
// =============================================================================

/// scr_ui_tavern_panel_input(tavern_inst)
/// Obsługuje kliknięcia w panelu karczmy
function scr_ui_tavern_panel_input(_tavern) {
    // Zamknij na ESC
    if (keyboard_check_pressed(vk_escape)) {
        scr_ui_close_tavern_panel();
        return;
    }
    
    // Sprawdź czy jest noc
    if (!scr_trait_is_night()) return;
    
    // Sprawdź kliknięcie
    if (!mouse_check_button_pressed(mb_left)) return;
    
    // Pobierz pozycję panelu
    var panel_x = (display_get_gui_width() - TAVERN_UI_PANEL_WIDTH) / 2;
    var panel_y = (display_get_gui_height() - TAVERN_UI_PANEL_HEIGHT) / 2;
    var m = TAVERN_UI_MARGIN;
    var lh = TAVERN_UI_LINE_HEIGHT;
    
    // Pozycja myszy
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    // Pobierz listę gości
    var visitors = [];
    with (obj_ui_controller) {
        if (variable_instance_exists(id, "ui_tavern_visitors")) {
            visitors = ui_tavern_visitors;
        }
    }
    
    // Sprawdź kliknięcie na NPC
    var header_y = panel_y + m + lh + 10 + m + lh;
    
    for (var i = 0; i < array_length(visitors); i++) {
        var v = visitors[i];
        var npc_y = header_y + i * TAVERN_UI_NPC_HEIGHT;
        
        if (point_in_rectangle(mx, my, panel_x + m, npc_y, panel_x + TAVERN_UI_PANEL_WIDTH - m, npc_y + TAVERN_UI_NPC_HEIGHT - 4)) {
            
            // Kliknięto na tego NPC
            if (!v.is_sluga) {
                // Próba negocjacji
                var result = scr_cyrograf_attempt_negotiation(v.npc_inst);
                
                // Pokaż wynik (można rozbudować o popup)
                show_debug_message("NEGOTIATION: " + result.message);
                
                // Zapisz wynik do wyświetlenia
                with (obj_ui_controller) {
                    ui_tavern_last_result = result;
                    ui_tavern_result_timer = room_speed * 3; // 3 sekundy
                }
            }
            
            break;
        }
    }
}

/// scr_ui_open_tavern_panel(tavern_inst)
/// Otwiera panel karczmy
function scr_ui_open_tavern_panel(_tavern) {
    with (obj_ui_controller) {
        ui_active_panel = "tavern";
        ui_selected_target = _tavern;
        ui_tavern_visitors = [];
        ui_tavern_last_result = undefined;
        ui_tavern_result_timer = 0;
        global.ui_blocking_input = true;
    }
    show_debug_message("UI: Opened tavern panel");
}

/// scr_ui_close_tavern_panel()
/// Zamyka panel karczmy
function scr_ui_close_tavern_panel() {
    with (obj_ui_controller) {
        ui_active_panel = noone;
        ui_selected_target = noone;
        ui_tavern_visitors = [];
        global.ui_blocking_input = false;
    }
}

// =============================================================================
// UI - WYŚWIETLANIE WYNIKU NEGOCJACJI
// =============================================================================

/// scr_ui_draw_negotiation_result(x, y)
/// Rysuje popup z wynikiem ostatniej negocjacji
function scr_ui_draw_negotiation_result(_x, _y) {
    var result = undefined;
    var timer = 0;
    
    with (obj_ui_controller) {
        if (variable_instance_exists(id, "ui_tavern_last_result")) {
            result = ui_tavern_last_result;
        }
        if (variable_instance_exists(id, "ui_tavern_result_timer")) {
            timer = ui_tavern_result_timer;
            ui_tavern_result_timer--;
        }
    }
    
    if (is_undefined(result) || timer <= 0) return;
    
    var w = 300;
    var h = 60;
    var popup_x = _x + (TAVERN_UI_PANEL_WIDTH - w) / 2;
    var popup_y = _y + TAVERN_UI_PANEL_HEIGHT - h - 50;
    
    // Tło
    var bg_color = result.success ? $003300 : $330000;
    draw_set_alpha(0.95);
    draw_rectangle_color(popup_x, popup_y, popup_x + w, popup_y + h,
        bg_color, bg_color, bg_color, bg_color, false);
    draw_set_alpha(1);
    
    // Ramka
    var border_color = result.success ? CYROGRAF_UI_SUCCESS : CYROGRAF_UI_FAIL;
    draw_rectangle_color(popup_x, popup_y, popup_x + w, popup_y + h,
        border_color, border_color, border_color, border_color, true);
    
    // Tekst
    draw_set_color(border_color);
    draw_set_halign(fa_center);
    draw_text(popup_x + w/2, popup_y + 10, result.success ? "SUKCES!" : "PORAZKA!");
    
    draw_set_color(CYROGRAF_UI_TEXT);
    draw_text(popup_x + w/2, popup_y + 35, result.message);
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

// =============================================================================
// INTEGRACJA Z OBJ_UI_CONTROLLER
// =============================================================================

/*
/// === DODAJ DO obj_ui_controller Create Event: ===

ui_tavern_visitors = [];
ui_tavern_last_result = undefined;
ui_tavern_result_timer = 0;


/// === DODAJ DO obj_ui_controller Step Event: ===

// Panel karczmy
if (ui_active_panel == "tavern" && instance_exists(ui_selected_target)) {
    scr_ui_tavern_panel_input(ui_selected_target);
}

// Detekcja kliknięcia na karczmę
if (mouse_check_button_pressed(mb_left) && !ui_is_active()) {
    var mx = mouse_x;
    var my = mouse_y;
    
    // Sprawdź karczmę (PRZED encounterami i settlementami)
    var tavern = instance_position(mx, my, obj_karczma);
    if (tavern != noone) {
        scr_ui_open_tavern_panel(tavern);
        exit;
    }
}


/// === DODAJ DO obj_ui_controller Draw GUI Event: ===

// Panel karczmy
if (ui_active_panel == "tavern" && instance_exists(ui_selected_target)) {
    var panel_x = (display_get_gui_width() - TAVERN_UI_PANEL_WIDTH) / 2;
    var panel_y = (display_get_gui_height() - TAVERN_UI_PANEL_HEIGHT) / 2;
    scr_ui_draw_tavern_panel(ui_selected_target, panel_x, panel_y);
    scr_ui_draw_negotiation_result(panel_x, panel_y);
}
*/

// =============================================================================
// INTEGRACJA Z NOCNYM TICK (scr_trait_tick)
// =============================================================================

/*
/// === DODAJ DO scr_trait_night_tick(): ===

// Generuj EC od sług
scr_cyrograf_generate_nightly_ec();
*/

// =============================================================================
// INTEGRACJA Z INICJALIZACJĄ (o_game Create)
// =============================================================================

/*
/// === DODAJ DO o_game Create Event: ===

scr_cyrograf_system_init();
*/

// =============================================================================
// DEBUG
// =============================================================================

/// scr_cyrograf_debug()
/// Wyświetla debug info o systemie cyrografów
function scr_cyrograf_debug() {
    show_debug_message("=== CYROGRAF SYSTEM DEBUG ===");
    show_debug_message("Slugi count: " + string(scr_cyrograf_get_sluga_count()));
    show_debug_message("Stats:");
    show_debug_message("  Total attempts: " + string(global.cyrograf_stats.total_attempts));
    show_debug_message("  Successful: " + string(global.cyrograf_stats.successful));
    show_debug_message("  Failed: " + string(global.cyrograf_stats.failed));
    show_debug_message("  EC spent: " + string(global.cyrograf_stats.total_ec_spent));
    show_debug_message("  EC earned: " + string(global.cyrograf_stats.total_ec_earned));
    
    // Lista sług
    if (variable_global_exists("slugi") && ds_exists(global.slugi, ds_type_list)) {
        var n = ds_list_size(global.slugi);
        show_debug_message("Active slugi (" + string(n) + "):");
        for (var i = 0; i < n; i++) {
            var npc = global.slugi[| i];
            if (instance_exists(npc)) {
                show_debug_message("  - NPC " + string(npc.id) + " state=" + npc.npc_data.state);
            }
        }
    }
}
