/// =============================================================================
/// SCR_NPC_DEBUG_DRAW - WIZUALNY DEBUGGER SYSTEMU NPC
/// WERSJA 3.0 - Z CYKLEM DNIA I KARCZMĄ
/// =============================================================================
/// Wywołaj scr_npc_debug_draw() w Draw GUI event kontrolera gry
/// =============================================================================

function scr_npc_debug_draw()
{
    if (is_undefined(global.npc_debug)) return;
    
    var cam = view_camera[0];
    var cam_x = camera_get_view_x(cam);
    var cam_y = camera_get_view_y(cam);
    
    // === ENCOUNTER RANGES ===
    if (global.npc_debug.show_encounter_ranges) {
        _draw_encounter_ranges(cam_x, cam_y);
    }
    
    // === NPC TARGETS ===
    if (global.npc_debug.show_npc_targets) {
        _draw_npc_targets(cam_x, cam_y);
    }
    
    // === NPC INFO PANEL ===
    _draw_npc_info_panel();
}

/// Rysuj okręgi zasięgów encounterów
function _draw_encounter_ranges(_cam_x, _cam_y)
{
    if (is_undefined(global.encounters)) return;
    
    var n = ds_list_size(global.encounters);
    for (var i = 0; i < n; i++) {
        var enc = global.encounters[| i];
        if (!instance_exists(enc)) continue;
        if (is_undefined(enc.encounter_data)) continue;
        
        var ed = enc.encounter_data;
        var range = 120; // domyślny
        if (!is_undefined(ed.zasieg)) range = ed.zasieg;
        
        // Konwertuj pozycję świata na ekran
        var sx = enc.x - _cam_x;
        var sy = enc.y - _cam_y;
        
        // Rysuj okrąg zasięgu
        var col = global.npc_debug.encounter_range_color;
        var alpha = global.npc_debug.encounter_range_alpha;
        
        draw_set_alpha(alpha);
        draw_set_color(col);
        draw_circle(sx, sy, range, true);
        
        // Wypełnienie
        draw_set_alpha(alpha * 0.3);
        draw_circle(sx, sy, range, false);
        
        // Etykieta
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_set_font(-1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        
        var label = "";
        if (!is_undefined(ed.typ)) label = ed.typ;
        label += " [r:" + string(range) + "]";
        if (!is_undefined(ed.sila)) label += " s:" + string(ed.sila);
        
        draw_text(sx, sy - range - 16, label);
        
        // Mały krzyżyk w centrum
        draw_set_color(col);
        draw_line(sx - 4, sy, sx + 4, sy);
        draw_line(sx, sy - 4, sx, sy + 4);
    }
    
    // Reset
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

/// Rysuj linie od NPC do ich celów
function _draw_npc_targets(_cam_x, _cam_y)
{
    if (is_undefined(global.npcs)) return;
    
    var n = ds_list_size(global.npcs);
    for (var i = 0; i < n; i++) {
        var npc = global.npcs[| i];
        if (!instance_exists(npc)) continue;
        if (is_undefined(npc.npc_data)) continue;
        
        var nd = npc.npc_data;
        var tgt = nd.target;
        if (tgt == noone) continue;
        
        var sx = npc.x - _cam_x;
        var sy = npc.y - _cam_y;
        var tx, ty;
        
        if (is_struct(tgt)) {
            tx = tgt.x - _cam_x;
            ty = tgt.y - _cam_y;
        } else if (instance_exists(tgt)) {
            tx = tgt.x - _cam_x;
            ty = tgt.y - _cam_y;
        } else {
            continue;
        }
        
        // Kolor zależny od typu celu
        var col = c_white;
        switch (nd.target_type) {
            case "resource": col = c_green; break;
            case "encounter": col = c_red; break;
            case "settlement": col = c_blue; break;
            case "tavern": col = c_orange; break;
            case "explore_point": col = c_yellow; break;
            case "travel_point": col = c_aqua; break;
            case "point": col = c_gray; break;
        }
        
        draw_set_color(col);
        draw_set_alpha(0.6);
        draw_line(sx, sy, tx, ty);
        
        // Punkt docelowy
        draw_circle(tx, ty, 4, false);
    }
    
    draw_set_alpha(1);
}

/// Panel informacyjny
function _draw_npc_info_panel()
{
    var panel_x = 10;
    var panel_y = 10;
    var line_h = 14;
    var line = 0;
    
    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(panel_x - 5, panel_y - 5, panel_x + 300, panel_y + 280, false);
    draw_set_alpha(1);
    
    draw_set_color(c_white);
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    // Tytuł
    draw_text(panel_x, panel_y + line * line_h, "=== NPC DEBUG PANEL v3.0 ===");
    line += 1.5;
    
    // Globalne statystyki
    var npc_count = 0;
    var sluga_count = 0;
    var tavern_count = 0;
    var traveling_count = 0;
    var working_count = 0;
    
    if (!is_undefined(global.npcs)) {
        npc_count = ds_list_size(global.npcs);
        for (var i = 0; i < npc_count; i++) {
            var npc = global.npcs[| i];
            if (instance_exists(npc) && !is_undefined(npc.npc_data)) {
                if (npc.npc_data.traits.sluga) sluga_count++;
                if (npc.npc_data.state == "at_tavern") tavern_count++;
                if (npc.npc_data.daily_plan == "travel") traveling_count++;
                if (npc.npc_data.state == "working") working_count++;
            }
        }
    }
    
    draw_text(panel_x, panel_y + line * line_h, "NPCs: " + string(npc_count) + " | Kultyści: " + string(sluga_count));
    line++;
    draw_text(panel_x, panel_y + line * line_h, "W karczmie: " + string(tavern_count) + " | Pracuje: " + string(working_count));
    line++;
    draw_text(panel_x, panel_y + line * line_h, "Plan podróży: " + string(traveling_count));
    line++;
    
    // Dzień/noc i pora
    var pora = "DZIEŃ";
    var phase_progress = 0;
    if (variable_global_exists("daynight_phase")) {
        pora = string_upper(global.daynight_phase);
        if (variable_global_exists("daynight_phase_progress")) {
            phase_progress = global.daynight_phase_progress;
        }
    } else if (!is_undefined(global.is_night) && global.is_night) {
        pora = "NOC";
    }
    
    draw_set_color(c_yellow);
    draw_text(panel_x, panel_y + line * line_h, "Pora: " + pora + " (" + string(floor(phase_progress * 100)) + "%)");
    line++;
    draw_set_color(c_white);
    
    // Karczmy
    var tavern_total = 0;
    if (!is_undefined(global.taverns)) {
        tavern_total = ds_list_size(global.taverns);
    }
    draw_set_color(c_orange);
    draw_text(panel_x, panel_y + line * line_h, "Karczmy na mapie: " + string(tavern_total));
    line += 1.5;
    draw_set_color(c_white);
    
    // Aktywne modyfikatory
    draw_set_color(c_yellow);
    draw_text(panel_x, panel_y + line * line_h, "--- GLOBAL MODS ---");
    line++;
    draw_set_color(c_white);
    
    if (!is_undefined(global.npc_mod)) {
        var mods = ["pracowitosc", "wanderlust", "roztargnienie", "ciekawosc", "podatnosc", "devotion", "fanatyzm", "towarzyskosc"];
        for (var i = 0; i < array_length(mods); i++) {
            var m = mods[i];
            var val = variable_struct_get(global.npc_mod, m);
            if (val != 0) {
                var sign_str = val > 0 ? "+" : "";
                draw_text(panel_x, panel_y + line * line_h, "  " + m + ": " + sign_str + string(val));
                line++;
            }
        }
        
        // Szansa wyjścia w nocy
        if (global.npc_mod.szansa_wyjscia_noc > 0) {
            draw_text(panel_x, panel_y + line * line_h, "  noc_wyjscie: " + string(global.npc_mod.szansa_wyjscia_noc) + "%");
            line++;
        }
    }
    
    line += 0.5;
    
    // Stany NPC
    draw_set_color(c_lime);
    draw_text(panel_x, panel_y + line * line_h, "--- NPC STATES ---");
    line++;
    draw_set_color(c_white);
    
    var states = {};
    if (!is_undefined(global.npcs)) {
        var n = ds_list_size(global.npcs);
        for (var i = 0; i < n; i++) {
            var npc = global.npcs[| i];
            if (!instance_exists(npc)) continue;
            if (is_undefined(npc.npc_data)) continue;
            
            var st = npc.npc_data.state;
            if (!variable_struct_exists(states, st)) {
                variable_struct_set(states, st, 0);
            }
            variable_struct_set(states, st, variable_struct_get(states, st) + 1);
        }
    }
    
    var state_names = variable_struct_get_names(states);
    for (var i = 0; i < array_length(state_names); i++) {
        var sn = state_names[i];
        var count = variable_struct_get(states, sn);
        
        // Koloruj specjalne stany
        if (sn == "at_tavern") draw_set_color(c_orange);
        else if (sn == "traveling") draw_set_color(c_aqua);
        else if (sn == "working") draw_set_color(c_green);
        else draw_set_color(c_white);
        
        draw_text(panel_x, panel_y + line * line_h, "  " + sn + ": " + string(count));
        line++;
    }
    
    draw_set_color(c_white);
    line += 0.5;
    
    // Plany dnia
    draw_set_color(c_aqua);
    draw_text(panel_x, panel_y + line * line_h, "--- DAILY PLANS ---");
    line++;
    draw_set_color(c_white);
    
    var plans = { work: 0, travel: 0, none: 0 };
    if (!is_undefined(global.npcs)) {
        var n = ds_list_size(global.npcs);
        for (var i = 0; i < n; i++) {
            var npc = global.npcs[| i];
            if (!instance_exists(npc)) continue;
            if (is_undefined(npc.npc_data)) continue;
            
            var plan = npc.npc_data.daily_plan;
            if (variable_struct_exists(plans, plan)) {
                variable_struct_set(plans, plan, variable_struct_get(plans, plan) + 1);
            }
        }
    }
    
    draw_text(panel_x, panel_y + line * line_h, "  work: " + string(plans.work) + " | travel: " + string(plans.travel) + " | none: " + string(plans.none));
    line += 1.5;
    
    // Klawisze pomocy
    draw_set_color(c_gray);
    draw_text(panel_x, panel_y + line * line_h, "F1-F4: Presety | F5: Reset");
    line++;
    draw_text(panel_x, panel_y + line * line_h, "F6: Encounter ranges | F7: NPC targets");
    line++;
    draw_text(panel_x, panel_y + line * line_h, "F8: Print NPC stats | F9: Day/Night");
}

/// =============================================================================
/// DRAW EVENT - ENCOUNTER RANGES (World space)
/// =============================================================================

function scr_npc_debug_draw_world()
{
    if (is_undefined(global.npc_debug)) return;
    if (!global.npc_debug.show_encounter_ranges) return;
    if (is_undefined(global.encounters)) return;
    
    var n = ds_list_size(global.encounters);
    for (var i = 0; i < n; i++) {
        var enc = global.encounters[| i];
        if (!instance_exists(enc)) continue;
        if (is_undefined(enc.encounter_data)) continue;
        
        var ed = enc.encounter_data;
        var range = 120;
        if (!is_undefined(ed.zasieg)) range = ed.zasieg;
        
        var col = global.npc_debug.encounter_range_color;
        var alpha = global.npc_debug.encounter_range_alpha;
        
        // Okrąg obwodu
        draw_set_alpha(alpha);
        draw_set_color(col);
        draw_circle(enc.x, enc.y, range, true);
        
        // Wypełnienie
        draw_set_alpha(alpha * 0.2);
        draw_circle(enc.x, enc.y, range, false);
    }
    
    draw_set_alpha(1);
}
