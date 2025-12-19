/// =============================================================================
/// BORUTA - UI SYSTEMU CECH LOKACJI
/// =============================================================================
/// Panel lokacji z wyświetlaniem i nadawaniem cech
/// =============================================================================

// =============================================================================
// KONFIGURACJA UI
// =============================================================================

#macro TRAIT_UI_PANEL_WIDTH 320
#macro TRAIT_UI_PANEL_HEIGHT 400
#macro TRAIT_UI_MARGIN 12
#macro TRAIT_UI_LINE_HEIGHT 22
#macro TRAIT_UI_HEADER_HEIGHT 36

// Kolory
#macro TRAIT_UI_BG_COLOR $2e1a1a
#macro TRAIT_UI_BORDER_COLOR $6a4a4a
#macro TRAIT_UI_TEXT_COLOR $e0e0e0
#macro TRAIT_UI_HIGHLIGHT_COLOR $00ccff
#macro TRAIT_UI_COST_COLOR $6666ff
#macro TRAIT_UI_AVAILABLE_COLOR $66ff66

// =============================================================================
// RYSOWANIE PANELU LOKACJI
// =============================================================================

/// scr_ui_draw_location_panel(settlement_inst, panel_x, panel_y)
/// Rysuje panel z informacjami o lokacji i cechach
function scr_ui_draw_location_panel(_settlement, _x, _y) {
    if (!instance_exists(_settlement)) return;
    if (is_undefined(_settlement.settlement_data)) return;
    
    var sd = _settlement.settlement_data;
    var w = TRAIT_UI_PANEL_WIDTH;
    var h = TRAIT_UI_PANEL_HEIGHT;
    var m = TRAIT_UI_MARGIN;
    var lh = TRAIT_UI_LINE_HEIGHT;
    
    // === TŁO ===
    draw_set_alpha(0.9);
    draw_rectangle_color(_x, _y, _x + w, _y + h, 
        TRAIT_UI_BG_COLOR, TRAIT_UI_BG_COLOR, TRAIT_UI_BG_COLOR, TRAIT_UI_BG_COLOR, false);
    draw_set_alpha(1);
    
    // Ramka
    draw_rectangle_color(_x, _y, _x + w, _y + h,
        TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR, true);
    
    // === NAGŁÓWEK ===
    var header_y = _y + m;
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_set_halign(fa_center);
    
    var loc_name = variable_struct_exists(sd, "name") ? sd.name : "Lokacja";
    draw_text(_x + w/2, header_y, loc_name);
    
    // Linia pod nagłówkiem
    draw_line_width_color(_x + m, header_y + lh, _x + w - m, header_y + lh, 
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);
    
    // === INFORMACJE O LOKACJI ===
    var info_y = header_y + lh + m;
    draw_set_halign(fa_left);
    draw_set_color(TRAIT_UI_TEXT_COLOR);
    
    // Typ lokacji
    var loc_type = variable_struct_exists(sd, "location_type") ? sd.location_type : "nieznany";
    draw_text(_x + m, info_y, "Typ: " + loc_type);
    info_y += lh;
    
    // Lokalna wiara
    var faith = variable_struct_exists(sd, "local_faith") ? sd.local_faith : 50;
    draw_text(_x + m, info_y, "Wiara lokalna: " + string(faith) + "%");
    info_y += lh;
    
    // Sloty cech
    var max_slots = variable_struct_exists(sd, "trait_slots") ? sd.trait_slots : 2;
    var used_slots = is_undefined(sd.traits) ? 0 : ds_list_size(sd.traits);
    var free_slots = max_slots - used_slots;
    
    draw_set_color(free_slots > 0 ? TRAIT_UI_AVAILABLE_COLOR : TRAIT_UI_COST_COLOR);
    draw_text(_x + m, info_y, "Sloty: " + string(used_slots) + "/" + string(max_slots));
    info_y += lh;
    
    // === ESENCJA CIEMNOŚCI (górny prawy róg) ===
    draw_set_halign(fa_right);
    draw_set_color($ff66ff);
    draw_text(_x + w - m, _y + m, "EC: " + string(floor(global.dark_essence)));
    draw_set_halign(fa_left);
    
    // Linia oddzielająca
    info_y += m/2;
    draw_line_width_color(_x + m, info_y, _x + w - m, info_y, 
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);
    info_y += m;
    
    // === AKTYWNE CECHY ===
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_text(_x + m, info_y, "Aktywne cechy:");
    info_y += lh;
    
    draw_set_color(TRAIT_UI_TEXT_COLOR);
    
    if (!is_undefined(sd.traits) && ds_list_size(sd.traits) > 0) {
        for (var i = 0; i < ds_list_size(sd.traits); i++) {
            var trait = sd.traits[| i];
            
            // Nazwa i poziom
            var level_str = scr_trait_level_to_string(trait.level);
            var trait_text = "* " + trait.display_name + " [" + level_str + "]";
            
            draw_text(_x + m, info_y, trait_text);
            info_y += lh;
            
            // Skrócony opis efektów
            if (variable_struct_exists(trait.effects, "local_fear_bonus")) {
                draw_set_color(TRAIT_UI_COST_COLOR);
                draw_text(_x + m + 16, info_y, "  Strach: +" + string(trait.effects.local_fear_bonus));
                info_y += lh - 4;
            }
            draw_set_color(TRAIT_UI_TEXT_COLOR);
        }
    } else {
        draw_set_color($888888);
        draw_text(_x + m, info_y, "(brak aktywnych cech)");
        info_y += lh;
    }
    
    // Linia oddzielająca
    info_y += m/2;
    draw_line_width_color(_x + m, info_y, _x + w - m, info_y, 
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);
    info_y += m;
    
    // === DOSTĘPNE CECHY DO NADANIA ===
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_text(_x + m, info_y, "Dostepne cechy:");
    info_y += lh;
    
    // Sprawdź czy można działać (noc)
    var can_act = scr_trait_can_act();
    
    if (!can_act) {
        draw_set_color($6666ff);
        draw_text(_x + m, info_y, "(akcje dostepne tylko w nocy)");
        info_y += lh;
    }
    
    // Lista dostępnych cech
    var available = scr_trait_get_available_for_location(loc_type);
    var trait_num = 1;
    
    for (var i = 0; i < array_length(available); i++) {
        var trait_name = available[i];
        var def = scr_trait_get_definition(trait_name);
        if (is_undefined(def)) continue;
        
        // Sprawdź czy już ma tę cechę
        if (scr_trait_settlement_has(_settlement, trait_name)) continue;
        
        // Sprawdź wymagania wstępne
        var prereq_met = scr_trait_check_prerequisite(trait_name, _settlement);
        
        // Oblicz koszt
        var cost = scr_trait_get_cost(trait_name, def.base_cost);
        cost = scr_trait_apply_cost_modifiers(_settlement, cost);
        
        var can_afford = scr_dark_essence_can_afford(cost);
        var has_slot = free_slots > 0;
        
        // Kolor zależny od dostępności
        if (!prereq_met) {
            draw_set_color($666666); // zablokowane
        } else if (!has_slot) {
            draw_set_color($668888); // brak slotu
        } else if (!can_afford) {
            draw_set_color(TRAIT_UI_COST_COLOR); // za drogie
        } else if (!can_act) {
            draw_set_color($888888); // dzień
        } else {
            draw_set_color(TRAIT_UI_AVAILABLE_COLOR); // dostępne
        }
        
        var trait_text = "[" + string(trait_num) + "] " + def.display_name + " [" + string(cost) + " EC]";
        draw_text(_x + m, info_y, trait_text);
        info_y += lh;
        trait_num++;
        
        // Jeśli zablokowane - pokaż powód
        if (!prereq_met && def.prerequisite != "") {
            draw_set_color($555555);
            draw_text(_x + m + 16, info_y, "  (wymaga: " + def.prerequisite + ")");
            info_y += lh - 4;
        }
    }
    
    // === INSTRUKCJE ===
    info_y = _y + h - lh - m;
    draw_set_color($888888);
    draw_set_halign(fa_center);
    draw_text(_x + w/2, info_y, "[1-5] Nadaj ceche | [E] Eskaluj | [ESC] Zamknij");
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

/// scr_trait_level_to_string(level)
/// Konwertuje poziom liczbowy na tekst
function scr_trait_level_to_string(_level) {
    switch (_level) {
        case 1: return "I-Szept";
        case 2: return "II-Niepokój";
        case 3: return "III-Groza";
        case 4: return "IV-Legenda";
        default: return "?";
    }
}

// =============================================================================
// OBSŁUGA KLIKNIĘĆ NA LOKACJE
// =============================================================================

/// scr_ui_check_location_click()
/// Sprawdza kliknięcie na lokację i otwiera panel
function scr_ui_check_location_click() {
    if (mouse_check_button_pressed(mb_left)) {
        // Nie otwieraj jeśli już mamy otwarty panel
        if (global.ui_blocking_input) return;
        
        // Sprawdź kliknięcie na settlement
        var clicked = instance_position(mouse_x, mouse_y, obj_settlement_parent);
        
        if (clicked != noone) {
            scr_ui_open_location_panel(clicked);
        }
    }
}

/// scr_ui_open_location_panel(settlement_inst)
/// Otwiera panel lokacji
function scr_ui_open_location_panel(_settlement) {
    with (obj_ui_controller) {
        ui_active_panel = "location";
        ui_selected_target = _settlement;
        global.ui_blocking_input = true;
    }
    show_debug_message("UI: Opened location panel for " + string(_settlement.id));
}

/// scr_ui_close_location_panel()
/// Zamyka panel lokacji
function scr_ui_close_location_panel() {
    with (obj_ui_controller) {
        ui_active_panel = noone;
        ui_selected_target = noone;
        global.ui_blocking_input = false;
    }
}

// =============================================================================
// OBSŁUGA INPUT W PANELU
// =============================================================================

/// scr_ui_location_panel_input(settlement_inst)
/// Obsługuje input gdy panel lokacji jest otwarty
function scr_ui_location_panel_input(_settlement) {
    // Zamknij panel
    if (keyboard_check_pressed(vk_escape)) {
        scr_ui_close_location_panel();
        return;
    }
    
    // Nadawanie cech (klawisze 1-5)
    if (!scr_trait_can_act()) return; // tylko w nocy
    
    var loc_type = "chata";
    if (!is_undefined(_settlement.settlement_data) && 
        variable_struct_exists(_settlement.settlement_data, "location_type")) {
        loc_type = _settlement.settlement_data.location_type;
    }
    
    var available = scr_trait_get_available_for_location(loc_type);
    
    // Filtruj cechy które settlement już ma
    var filtered = [];
    for (var i = 0; i < array_length(available); i++) {
        if (!scr_trait_settlement_has(_settlement, available[i])) {
            array_push(filtered, available[i]);
        }
    }
    
    // Klawisze 1-5 nadają odpowiednie cechy
    for (var key = ord("1"); key <= ord("5"); key++) {
        if (keyboard_check_pressed(key)) {
            var idx = key - ord("1");
            if (idx < array_length(filtered)) {
                var trait_name = filtered[idx];
                var success = scr_trait_apply_to_settlement(_settlement, trait_name);
                if (success) {
                    show_debug_message("UI: Applied trait '" + trait_name + "'!");
                }
            }
        }
    }
    
    // Eskalacja cechy (klawisz E)
    if (keyboard_check_pressed(ord("E"))) {
        var traits = scr_trait_settlement_get_all(_settlement);
        if (array_length(traits) > 0) {
            var first_trait = traits[0];
            scr_trait_escalate(_settlement, first_trait.name);
        }
    }
}

// =============================================================================
// WIZUALNE OZNACZENIA LOKACJI
// =============================================================================

/// scr_trait_draw_location_indicator(settlement_inst)
/// Rysuje wizualne oznaczenie cech na lokacji
function scr_trait_draw_location_indicator(_settlement) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return;
    if (ds_list_size(traits_list) == 0) return;
    
    var x1 = _settlement.x;
    var y1 = _settlement.y - 8;
    
    // Rysuj małe ikony/kropki dla każdej cechy
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        var color = scr_trait_get_indicator_color(trait.name);
        
        var dot_x = x1 - (ds_list_size(traits_list) * 4) + (i * 8);
        
        draw_set_alpha(0.7 + sin(current_time / 500 + i) * 0.3);
        draw_circle_color(dot_x, y1, 3, color, color, false);
    }
    
    draw_set_alpha(1);
}

/// scr_trait_get_indicator_color(trait_name)
/// Zwraca kolor wskaźnika dla danej cechy
function scr_trait_get_indicator_color(_trait_name) {
    switch (_trait_name) {
        case "nawiedzenie": return $cc3366;   // fioletowy
        case "izolacja":    return $996633;   // niebieski
        case "plugawe":     return $339933;   // zielony
        case "plotkarska":  return $0066cc;   // pomarańczowy
        case "zapomniane":  return $666666;   // szary
        case "poswiecone":  return $00ccff;   // złoty
        case "sprofanowane": return $000099;  // ciemnoczerwony
        default:            return $ffffff;
    }
}

// =============================================================================
// EFEKTY WIZUALNE (OVERLAY)
// =============================================================================

/// scr_trait_draw_location_overlay(settlement_inst)
/// Rysuje efekty wizualne nakładane na lokację
function scr_trait_draw_location_overlay(_settlement) {
    var traits_list = scr_trait_safe_get_traits(_settlement);
    if (is_undefined(traits_list)) return;
    
    for (var i = 0; i < ds_list_size(traits_list); i++) {
        var trait = traits_list[| i];
        
        switch (trait.name) {
            case "nawiedzenie":
                // Subtelna mgła/cienie
                draw_set_alpha(0.1 + trait.level * 0.05);
                draw_set_color($33001a);
                draw_ellipse(_settlement.x - 40, _settlement.y - 20, 
                            _settlement.x + 40, _settlement.y + 30, false);
                break;
                
            case "plugawe":
                // Zielonkawy odcień
                draw_set_alpha(0.08 + trait.level * 0.03);
                draw_set_color($003300);
                draw_ellipse(_settlement.x - 50, _settlement.y - 25, 
                            _settlement.x + 50, _settlement.y + 35, false);
                break;
                
            case "poswiecone":
                // Złotawa poświata
                draw_set_alpha(0.05);
                draw_set_color($66ccff);
                draw_ellipse(_settlement.x - 45, _settlement.y - 22, 
                            _settlement.x + 45, _settlement.y + 32, false);
                break;
        }
    }
    
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// =============================================================================
// HUD - PASEK ESENCJI CIEMNOŚCI
// =============================================================================

/// scr_ui_draw_dark_essence_bar(x, y, width, height)
/// Rysuje pasek Esencji Ciemności
function scr_ui_draw_dark_essence_bar(_x, _y, _w, _h) {
    var ec = global.dark_essence;
    var ec_max = global.dark_essence_max;
    var fill = ec / ec_max;
    
    // Tło
    draw_set_alpha(0.7);
    draw_rectangle_color(_x, _y, _x + _w, _y + _h, 
        $2e1a1a, $2e1a1a, $2e1a1a, $2e1a1a, false);
    
    // Wypełnienie
    draw_set_alpha(0.9);
    var fill_color = merge_color($660033, $ff3399, fill);
    draw_rectangle_color(_x + 2, _y + 2, _x + 2 + (_w - 4) * fill, _y + _h - 2,
        fill_color, fill_color, fill_color, fill_color, false);
    
    // Ramka
    draw_set_alpha(1);
    draw_rectangle_color(_x, _y, _x + _w, _y + _h,
        $cc3366, $cc3366, $cc3366, $cc3366, true);
    
    // Tekst
    draw_set_color($ffffff);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x + _w/2, _y + _h/2, string(floor(ec)) + "/" + string(ec_max));
    
    // Ikona
    draw_set_halign(fa_right);
    draw_set_color($ff3399);
    draw_text(_x - 4, _y + _h/2, "EC");
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

// =============================================================================
// TOOLTIP CECHY
// =============================================================================

/// scr_ui_draw_trait_tooltip(trait_name, x, y)
/// Rysuje tooltip z opisem cechy
function scr_ui_draw_trait_tooltip(_trait_name, _x, _y) {
    var def = scr_trait_get_definition(_trait_name);
    if (is_undefined(def)) return;
    
    var w = 250;
    var h = 120;
    var m = 8;
    var lh = 16;
    
    // Upewnij się że tooltip nie wychodzi poza ekran
    if (_x + w > display_get_gui_width()) {
        _x = display_get_gui_width() - w - 10;
    }
    if (_y + h > display_get_gui_height()) {
        _y = display_get_gui_height() - h - 10;
    }
    
    // Tło
    draw_set_alpha(0.95);
    draw_rectangle_color(_x, _y, _x + w, _y + h,
        $1a0d0d, $1a0d0d, $1a0d0d, $1a0d0d, false);
    draw_set_alpha(1);
    
    // Ramka
    draw_rectangle_color(_x, _y, _x + w, _y + h,
        $6a4a4a, $6a4a4a, $6a4a4a, $6a4a4a, true);
    
    // Nazwa
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_text(_x + m, _y + m, def.display_name);
    
    // Opis
    draw_set_color($aaaaaa);
    draw_text_ext(_x + m, _y + m + lh, "\"" + def.description + "\"", lh, w - m*2);
    
    // Koszt
    var cost = scr_trait_get_cost(_trait_name, def.base_cost);
    draw_set_color(TRAIT_UI_COST_COLOR);
    draw_text(_x + m, _y + h - m - lh, "Koszt: " + string(cost) + " EC");
    
    draw_set_color(c_white);
}
