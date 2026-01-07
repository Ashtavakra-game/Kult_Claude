/// =============================================================================
/// BORUTA - UI SYSTEMU CECH LOKACJI (TRAITS)
/// =============================================================================
/// Panel uniwersalny dla wszystkich typów miejsc
/// Trait "Plotka" - zastępuje bazowe efekty miejsca, aktywacja na 1 dzień
/// =============================================================================

// =============================================================================
// KONFIGURACJA UI
// =============================================================================

#macro TRAIT_UI_PANEL_WIDTH 320
#macro TRAIT_UI_PANEL_HEIGHT 350
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
#macro TRAIT_UI_ACTIVE_COLOR $66ffcc

// =============================================================================
// RYSOWANIE PANELU MIEJSCA (UNIWERSALNY)
// =============================================================================

/// scr_ui_draw_location_panel(_place_inst, _x, _y)
/// Rysuje panel z informacjami o miejscu i cechach
/// Działa dla wszystkich typów: settlement, encounter, source, tavern
function scr_ui_draw_location_panel(_place_inst, _x, _y) {
    if (!instance_exists(_place_inst)) return;

    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    // Otwórz panel w UI controller
    if (instance_exists(obj_ui_controller)) {
        with (obj_ui_controller) {
            ui_active_panel = "location";
            ui_selected_target = _place_inst;
            global.ui_blocking_input = true;
        }
    }

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

    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "miejsce";
    var place_name = variable_struct_exists(pd, "name") ? pd.name :
                     (variable_struct_exists(pd, "nazwa") ? pd.nazwa :
                     (variable_struct_exists(pd, "typ") ? pd.typ : string_upper(place_type)));
    draw_text(_x + w/2, header_y, place_name);

    // Linia pod nagłówkiem
    draw_line_width_color(_x + m, header_y + lh, _x + w - m, header_y + lh,
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);

    // === INFORMACJE O MIEJSCU ===
    var info_y = header_y + lh + m;
    draw_set_halign(fa_left);
    draw_set_color(TRAIT_UI_TEXT_COLOR);

    // Typ miejsca
    var loc_type = variable_struct_exists(pd, "location_type") ? pd.location_type : place_type;
    draw_text(_x + m, info_y, "Typ: " + loc_type);
    info_y += lh;

    // Zasięg
    var zasieg = variable_struct_exists(pd, "zasieg") ? pd.zasieg : 0;
    draw_text(_x + m, info_y, "Zasieg: " + string(zasieg));
    info_y += lh;

    // Bazowe efekty
    if (variable_struct_exists(pd, "base_effects")) {
        var be = pd.base_effects;
        var strach = variable_struct_exists(be, "strach") ? be.strach : 0;
        var ofiara = variable_struct_exists(be, "ofiara") ? be.ofiara : 0;

        var effect_str = "Bazowe: ";
        if (strach != 0) effect_str += (strach > 0 ? "+" : "") + string(strach) + " Strach ";
        if (ofiara != 0) effect_str += (ofiara > 0 ? "+" : "") + string(ofiara) + " Ofiara";
        if (strach == 0 && ofiara == 0) effect_str += "brak";

        draw_set_color(strach > 0 ? TRAIT_UI_COST_COLOR : (strach < 0 ? TRAIT_UI_AVAILABLE_COLOR : TRAIT_UI_TEXT_COLOR));
        draw_text(_x + m, info_y, effect_str);
        info_y += lh;
    }

    // === Ofiara (górny prawy róg) ===
    draw_set_halign(fa_right);
    draw_set_color($cccc66);
    var ofiara_val = variable_global_exists("ofiara") ? global.ofiara : 0;
    draw_text(_x + w - m, _y + m, "Ofiara: " + string(floor(ofiara_val)));
    draw_set_halign(fa_left);

    // Linia oddzielająca
    info_y += m/2;
    draw_line_width_color(_x + m, info_y, _x + w - m, info_y,
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);
    info_y += m;

    // === STATUS AKTYWNEGO TRAITU ===
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_text(_x + m, info_y, "Status traitu:");
    info_y += lh;

    var has_active = scr_place_has_active_trait(_place_inst);
    var trait_days = variable_struct_exists(pd, "trait_days_remaining") ? pd.trait_days_remaining : 0;
    var active_trait = variable_struct_exists(pd, "active_trait") ? pd.active_trait : noone;

    if (has_active && active_trait != noone) {
        draw_set_color(TRAIT_UI_ACTIVE_COLOR);
        draw_text(_x + m, info_y, "* AKTYWNY: " + string(active_trait));
        info_y += lh;
        draw_set_color(TRAIT_UI_TEXT_COLOR);
        draw_text(_x + m + 16, info_y, "Pozostalo: " + string(trait_days) + " dni");
        info_y += lh;

        // Pokaż efekt aktywnego traitu
        var trait_def = scr_trait_get_definition(active_trait);
        if (!is_undefined(trait_def)) {
            var t_strach = variable_struct_exists(trait_def, "strach_bonus") ? trait_def.strach_bonus : 0;
            draw_set_color(TRAIT_UI_COST_COLOR);
            draw_text(_x + m + 16, info_y, "Efekt: +" + string(t_strach) + " Strach (zamiast bazowych)");
            info_y += lh;
        }
    } else {
        draw_set_color($888888);
        draw_text(_x + m, info_y, "(brak aktywnego traitu)");
        info_y += lh;
    }

    // Linia oddzielająca
    info_y += m/2;
    draw_line_width_color(_x + m, info_y, _x + w - m, info_y,
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);
    info_y += m;

    // === NADANE TRAITS ===
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_text(_x + m, info_y, "Nadane cechy:");
    info_y += lh;

    var traits = variable_struct_exists(pd, "traits") ? pd.traits : undefined;
    var has_traits = !is_undefined(traits) && ds_exists(traits, ds_type_list) && ds_list_size(traits) > 0;

    if (has_traits) {
        for (var i = 0; i < ds_list_size(traits); i++) {
            var trait = traits[| i];
            if (!is_struct(trait)) continue;

            var t_name = variable_struct_exists(trait, "display_name") ? trait.display_name : trait.name;
            draw_set_color(TRAIT_UI_TEXT_COLOR);
            draw_text(_x + m, info_y, "* " + t_name);
            info_y += lh;
        }
    } else {
        draw_set_color($888888);
        draw_text(_x + m, info_y, "(brak nadanych cech)");
        info_y += lh;
    }

    // Linia oddzielająca
    info_y += m/2;
    draw_line_width_color(_x + m, info_y, _x + w - m, info_y,
        1, TRAIT_UI_BORDER_COLOR, TRAIT_UI_BORDER_COLOR);
    info_y += m;

    // === DOSTĘPNE CECHY DO NADANIA ===
    draw_set_color(TRAIT_UI_HIGHLIGHT_COLOR);
    draw_text(_x + m, info_y, "Dostepne do nadania:");
    info_y += lh;

    var can_act = scr_trait_can_act();
    if (!can_act) {
        draw_set_color($6666ff);
        draw_text(_x + m, info_y, "(tylko w nocy)");
        info_y += lh;
    }

    // Pobierz pozycję myszki
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // Reset hitboxów
    if (instance_exists(obj_ui_controller)) {
        with (obj_ui_controller) {
            ui_trait_hitboxes = [];
            ui_trait_hovered_index = -1;
            ui_trait_hovered_name = "";
        }
    }

    // Lista dostępnych cech (teraz tylko "plotka")
    var available = scr_trait_get_available_for_location(loc_type);
    var trait_num = 0;
    var max_slots = variable_struct_exists(pd, "trait_slots") ? pd.trait_slots : 2;
    var used_slots = has_traits ? ds_list_size(traits) : 0;
    var free_slots = max_slots - used_slots;

    for (var i = 0; i < array_length(available); i++) {
        var trait_name = available[i];
        var def = scr_trait_get_definition(trait_name);
        if (is_undefined(def)) continue;

        // Sprawdź czy już ma tę cechę
        if (scr_place_has_trait(_place_inst, trait_name)) continue;

        // Oblicz koszt
        var cost = scr_trait_get_cost(trait_name, def.base_cost);
        cost = scr_trait_apply_cost_modifiers(_place_inst, cost);

        var can_afford = scr_myth_faith_can_afford(cost);
        var has_slot = free_slots > 0;
        var can_buy = has_slot && can_afford && can_act;

        // Hitbox
        var hb_x1 = _x + m - 4;
        var hb_y1 = info_y - 2;
        var hb_x2 = _x + w - m;
        var hb_y2 = info_y + lh - 2;

        var is_hovered = point_in_rectangle(mx, my, hb_x1, hb_y1, hb_x2, hb_y2);

        if (instance_exists(obj_ui_controller)) {
            with (obj_ui_controller) {
                array_push(ui_trait_hitboxes, {
                    x1: hb_x1, y1: hb_y1, x2: hb_x2, y2: hb_y2,
                    trait_name: trait_name,
                    can_buy: can_buy,
                    index: trait_num
                });
                if (is_hovered) {
                    ui_trait_hovered_index = trait_num;
                    ui_trait_hovered_name = trait_name;
                }
            }
        }

        // Hover effect
        if (is_hovered) {
            draw_set_alpha(0.3);
            draw_set_color(can_buy ? TRAIT_UI_AVAILABLE_COLOR : $666666);
            draw_rectangle(hb_x1, hb_y1, hb_x2, hb_y2, false);
            draw_set_alpha(1);
            draw_set_color(can_buy ? TRAIT_UI_HIGHLIGHT_COLOR : $888888);
            draw_rectangle(hb_x1, hb_y1, hb_x2, hb_y2, true);
        }

        // Kolor tekstu
        if (!has_slot) {
            draw_set_color($668888);
        } else if (!can_afford) {
            draw_set_color(TRAIT_UI_COST_COLOR);
        } else if (!can_act) {
            draw_set_color($888888);
        } else {
            draw_set_color(is_hovered ? $ffffff : TRAIT_UI_AVAILABLE_COLOR);
        }

        var trait_text = "[" + string(trait_num + 1) + "] " + def.display_name + " [" + string(cost) + " Ofiara]";
        draw_text(_x + m, info_y, trait_text);
        info_y += lh;
        trait_num++;
    }

    // Tooltip
    if (instance_exists(obj_ui_controller)) {
        with (obj_ui_controller) {
            if (ui_trait_hovered_name != "") {
                scr_ui_draw_trait_tooltip(ui_trait_hovered_name, mx + 15, my + 10);
            }
        }
    }

    // === INSTRUKCJE ===
    info_y = _y + h - lh - m;
    draw_set_color($888888);
    draw_set_halign(fa_center);

    // Specjalna instrukcja dla karczmy (można wrócić do panelu cyrografu)
    if (place_type == "tavern") {
        draw_text(_x + w/2, info_y, "[LPM/1] Nadaj | [K] Karczma | [ESC] Zamknij");
    } else {
        draw_text(_x + w/2, info_y, "[LPM/1] Nadaj | [ESC] Zamknij");
    }

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
/// Sprawdza kliknięcie na lokację i otwiera panel traits
/// LPM - settlement (tylko settlement - inne mają własne panele)
/// PPM - panel traits dla wszystkich typów miejsc (encounter, source, tavern)
function scr_ui_check_location_click() {
    // Nie otwieraj jeśli już mamy otwarty panel
    if (global.ui_blocking_input) return;

    // === LPM - Panel traits tylko dla settlement ===
    // (encounter, tavern, source mają własne panele na LPM)
    if (mouse_check_button_pressed(mb_left)) {
        var clicked = instance_position(mouse_x, mouse_y, obj_settlement_parent);
        if (clicked != noone) {
            scr_ui_open_location_panel(clicked);
            return;
        }
    }

    // === PPM - Panel traits dla WSZYSTKICH typów miejsc ===
    if (mouse_check_button_pressed(mb_right)) {
        // Sprawdź settlement
        var clicked = instance_position(mouse_x, mouse_y, obj_settlement_parent);
        if (clicked != noone) {
            scr_ui_open_location_panel(clicked);
            return;
        }

        // Sprawdź encounter
        clicked = instance_position(mouse_x, mouse_y, obj_encounter_parent);
        if (clicked != noone) {
            scr_ui_open_location_panel(clicked);
            return;
        }

        // Sprawdź source (resource)
        clicked = instance_position(mouse_x, mouse_y, obj_resource_parent);
        if (clicked != noone) {
            scr_ui_open_location_panel(clicked);
            return;
        }

        // Sprawdź tavern
        clicked = instance_position(mouse_x, mouse_y, obj_tavern);
        if (clicked != noone) {
            scr_ui_open_location_panel(clicked);
            return;
        }
    }
}

/// scr_ui_open_location_panel(_place_inst)
/// Otwiera panel traits dla dowolnego miejsca
function scr_ui_open_location_panel(_place_inst) {
    if (!instance_exists(_place_inst)) return;

    with (obj_ui_controller) {
        ui_active_panel = "location";
        ui_selected_target = _place_inst;
        global.ui_blocking_input = true;
    }

    var pd = scr_place_get_data(_place_inst);
    var place_type = !is_undefined(pd) && variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";
    show_debug_message("UI: Opened location panel for " + place_type + " " + string(_place_inst.id));
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

/// scr_ui_location_panel_input(_place_inst)
/// Obsługuje input gdy panel lokacji jest otwarty
/// Działa dla wszystkich typów miejsc (settlement, encounter, source, tavern)
function scr_ui_location_panel_input(_place_inst) {
    // Zamknij panel
    if (keyboard_check_pressed(vk_escape)) {
        scr_ui_close_location_panel();
        return;
    }

    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    var place_type = variable_struct_exists(pd, "place_type") ? pd.place_type : "unknown";

    // === POWRÓT DO PANELU KARCZMY (klawisz K) ===
    if (place_type == "tavern" && keyboard_check_pressed(ord("K"))) {
        scr_ui_close_location_panel();
        scr_ui_open_tavern_panel(_place_inst);
        return;
    }

    // === OBSŁUGA KLIKNIĘCIA MYSZKĄ ===
    if (mouse_check_button_pressed(mb_left)) {
        with (obj_ui_controller) {
            // Sprawdź czy kliknięto na cechę z listy
            if (ui_trait_hovered_index >= 0 && ui_trait_hovered_name != "") {
                // Znajdź hitbox dla tego indeksu
                for (var i = 0; i < array_length(ui_trait_hitboxes); i++) {
                    var hb = ui_trait_hitboxes[i];
                    if (hb.index == ui_trait_hovered_index) {
                        if (hb.can_buy) {
                            // Użyj uniwersalnej funkcji nadawania traits
                            var success = scr_trait_apply_to_place(_place_inst, hb.trait_name);
                            if (success) {
                                show_debug_message("UI: Applied trait '" + hb.trait_name + "' via mouse click!");
                            }
                        } else {
                            show_debug_message("UI: Cannot buy trait '" + hb.trait_name + "' - requirements not met");
                        }
                        break;
                    }
                }
            }
        }
    }

    // === OBSŁUGA KLAWISZY 1-5 ===
    var loc_type = variable_struct_exists(pd, "location_type") ? pd.location_type : "unknown";
    var available = scr_trait_get_available_for_location(loc_type);

    // Filtruj cechy które miejsce już ma
    var filtered = [];
    for (var i = 0; i < array_length(available); i++) {
        if (!scr_place_has_trait(_place_inst, available[i])) {
            array_push(filtered, available[i]);
        }
    }

    // Klawisze 1-5 nadają odpowiednie cechy
    for (var key = ord("1"); key <= ord("5"); key++) {
        if (keyboard_check_pressed(key)) {
            var idx = key - ord("1");
            if (idx < array_length(filtered)) {
                var trait_name = filtered[idx];
                // Użyj uniwersalnej funkcji nadawania traits
                var success = scr_trait_apply_to_place(_place_inst, trait_name);
                if (success) {
                    show_debug_message("UI: Applied trait '" + trait_name + "' via key " + chr(key) + "!");
                }
            }
        }
    }

    // Eskalacja cechy - usunięta w nowym systemie
    // (nowy system ma tylko trait "Plotka" bez poziomów)
}

// =============================================================================
// WIZUALNE OZNACZENIA LOKACJI
// =============================================================================

/// scr_trait_draw_location_indicator(_place_inst)
/// Rysuje wizualne oznaczenie cech na miejscu (uniwersalne)
function scr_trait_draw_location_indicator(_place_inst) {
    if (!instance_exists(_place_inst)) return;

    var pd = scr_place_get_data(_place_inst);
    if (is_undefined(pd)) return;

    // Sprawdź czy miejsce ma nadane traits
    if (!variable_struct_exists(pd, "traits")) return;
    var traits = pd.traits;
    if (!ds_exists(traits, ds_type_list)) return;
    if (ds_list_size(traits) == 0) return;

    var x1 = _place_inst.x;
    var y1 = _place_inst.y - 8;

    // Sprawdź czy trait jest aktywny
    var is_active = scr_place_has_active_trait(_place_inst);

    // Rysuj wskaźnik dla każdego traitu
    for (var i = 0; i < ds_list_size(traits); i++) {
        var trait = traits[| i];
        if (!is_struct(trait)) continue;

        var trait_name = variable_struct_exists(trait, "name") ? trait.name : "unknown";
        var color = scr_trait_get_indicator_color(trait_name);

        var dot_x = x1 - (ds_list_size(traits) * 4) + (i * 8);

        // Pulsacja zależna od aktywności
        var alpha = is_active ? (0.7 + sin(current_time / 300) * 0.3) : 0.4;
        var radius = is_active ? 4 : 3;

        draw_set_alpha(alpha);
        draw_circle_color(dot_x, y1, radius, color, color, false);
    }

    draw_set_alpha(1);
}

/// scr_trait_get_indicator_color(trait_name)
/// Zwraca kolor wskaźnika dla danej cechy
function scr_trait_get_indicator_color(_trait_name) {
    switch (_trait_name) {
        case "plotka":      return $66ccff;   // jasnoniebieski (główny trait)
        // Legacy colors (dla kompatybilności)
        case "nawiedzenie": return $cc3366;
        case "izolacja":    return $996633;
        case "plugawe":     return $339933;
        case "plotkarska":  return $0066cc;
        case "zapomniane":  return $666666;
        case "poswiecone":  return $00ccff;
        case "sprofanowane": return $000099;
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

/// scr_ui_draw_economy_bars(x, y, width, height)
/// Rysuje paski: Ofiara (waluta), WwSM (współczynnik), Strach (współczynnik), EC (waluta)
function scr_ui_draw_economy_bars(_x, _y, _w, _h) {
    var spacing = 3;
    var bar_h = (_h - spacing * 3) / 4;  // 4 paski zamiast 3

    // === PASEK OFIARY (WALUTA - tylko >=0) ===
    var ofiara = variable_global_exists("ofiara") ? global.ofiara : 0;
    scr_ui_draw_currency_bar(_x, _y, _w, bar_h, ofiara, $cccc66, "Ofiara");

    // === PASEK WwSM (WSPÓŁCZYNNIK - może być +/-) ===
    var wwsm_y = _y + bar_h + spacing;
    var wwsm = variable_global_exists("wwsm") ? global.wwsm : 0;
    scr_ui_draw_economy_resource_bar(_x, wwsm_y, _w, bar_h, wwsm, $66cccc, "WwSM");

    // === PASEK STRACHU (WSPÓŁCZYNNIK - może być +/-) ===
    var strach_y = wwsm_y + bar_h + spacing;
    var strach = variable_global_exists("strach") ? global.strach : 0;
    scr_ui_draw_economy_resource_bar(_x, strach_y, _w, bar_h, strach, $6666cc, "Strach");

    // === PASEK ESENCJI CIEMNOŚCI (EC - waluta z limitem) ===
    var ec_y = strach_y + bar_h + spacing;
    var ec = variable_global_exists("dark_essence") ? global.dark_essence : 0;
    var ec_max = variable_global_exists("dark_essence_max") ? global.dark_essence_max : 100;
    var ec_fill = clamp(ec / ec_max, 0, 1);

    // Tło
    draw_set_alpha(0.7);
    draw_rectangle_color(_x, ec_y, _x + _w, ec_y + bar_h,
        $2e1a1a, $2e1a1a, $2e1a1a, $2e1a1a, false);

    // Wypełnienie (czerwony/różowy)
    draw_set_alpha(0.9);
    var ec_color = merge_color($660033, $ff3399, ec_fill);
    draw_rectangle_color(_x + 2, ec_y + 2, _x + 2 + (_w - 4) * ec_fill, ec_y + bar_h - 2,
        ec_color, ec_color, ec_color, ec_color, false);

    // Ramka
    draw_set_alpha(1);
    draw_rectangle_color(_x, ec_y, _x + _w, ec_y + bar_h,
        $cc3366, $cc3366, $cc3366, $cc3366, true);

    // Tekst
    draw_set_color($ffffff);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x + _w/2, ec_y + bar_h/2, string(floor(ec)) + "/" + string(ec_max) + " EC");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

/// scr_ui_draw_currency_bar(x, y, w, h, value, color, label)
/// Rysuje pasek waluty (tylko wartości >=0, wypełnienie od lewej)
function scr_ui_draw_currency_bar(_x, _y, _w, _h, _val, _color, _label) {
    // Tło
    draw_set_alpha(0.7);
    draw_rectangle_color(_x, _y, _x + _w, _y + _h,
        $1a1a2e, $1a1a2e, $1a1a2e, $1a1a2e, false);

    // Wypełnienie (od lewej, proporcjonalne do wartości)
    draw_set_alpha(0.9);
    if (_val > 0) {
        var max_visual = 50;  // wizualna skala dla waluty
        var fill_ratio = clamp(_val / max_visual, 0, 1);
        var fill_w = (_w - 4) * fill_ratio;

        draw_set_color(_color);
        draw_rectangle(_x + 2, _y + 2, _x + 2 + fill_w, _y + _h - 2, false);
    }

    // Ramka
    draw_set_alpha(1);
    draw_set_color($303040);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    // Etykieta
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(_x + 4, _y + _h/2, _label);

    // Wartość
    draw_set_halign(fa_right);
    draw_set_color($ffff66);
    draw_text(_x + _w - 4, _y + _h/2, string(floor(_val)));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
}

/// scr_ui_draw_economy_resource_bar(x, y, w, h, value, color, label)
/// Rysuje pojedynczy pasek zasobu bez limitu (ze środkiem jako zero)
function scr_ui_draw_economy_resource_bar(_x, _y, _w, _h, _val, _color, _label) {
    // Tło
    draw_set_alpha(0.7);
    draw_rectangle_color(_x, _y, _x + _w, _y + _h,
        $1a1a2e, $1a1a2e, $1a1a2e, $1a1a2e, false);

    // Środek (zero)
    var center_x = _x + _w / 2;

    // Wypełnienie
    draw_set_alpha(0.9);
    if (_val != 0) {
        var max_visual = 20;
        var fill_ratio = clamp(abs(_val) / max_visual, 0, 1);
        var fill_w = (_w / 2 - 4) * fill_ratio;

        if (_val > 0) {
            draw_set_color(_color);
            draw_rectangle(center_x, _y + 2, center_x + fill_w, _y + _h - 2, false);
        } else {
            draw_set_color(merge_color(_color, c_black, 0.4));
            draw_rectangle(center_x - fill_w, _y + 2, center_x, _y + _h - 2, false);
        }
    }

    // Linia środkowa
    draw_set_alpha(0.5);
    draw_set_color(c_white);
    draw_line(center_x, _y + 2, center_x, _y + _h - 2);

    // Ramka
    draw_set_alpha(1);
    draw_set_color($303040);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    // Etykieta
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(_x + 4, _y + _h/2, _label);

    // Wartość
    draw_set_halign(fa_right);
    if (_val > 0) {
        draw_set_color($66ff66);
        draw_text(_x + _w - 4, _y + _h/2, "+" + string(floor(_val)));
    } else if (_val < 0) {
        draw_set_color($6666ff);
        draw_text(_x + _w - 4, _y + _h/2, string(floor(_val)));
    } else {
        draw_set_color(c_gray);
        draw_text(_x + _w - 4, _y + _h/2, "0");
    }

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
    draw_text(_x + m, _y + h - m - lh, "Koszt: " + string(cost) + " Ofiara");

    draw_set_color(c_white);
}
