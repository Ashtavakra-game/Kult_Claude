/// =============================================================================
/// SCR_NPC_SYSTEM - WERSJA 3.0 Z CYKLEM DNIA I KARCZMĄ
/// Bazuje na działającej nawigacji V4 + model cech + cykl dnia
/// =============================================================================

#macro INTERACTION_OFFSET_X 30     
#macro INTERACTION_OFFSET_Y 45     
#macro INTERACTION_ARRIVAL_DIST 16 
#macro NPC_DEBUG true
#macro PATH_ALLOW_DIAGONAL true

// =============================================================================
// DEBUG
// =============================================================================

function _npc_debug(_msg) {
    if (NPC_DEBUG && !is_undefined(global.npc_debug) && global.npc_debug.show_decision_logs) {
        show_debug_message("[NPC] " + string(_msg));
    }
}

// =============================================================================
// HELPERS
// =============================================================================

function _ensure_global_lists()
{
    if (is_undefined(global.resources)) global.resources = ds_list_create();
    if (is_undefined(global.encounters)) global.encounters = ds_list_create();
    if (is_undefined(global.settlements)) global.settlements = ds_list_create();
    if (is_undefined(global.npcs)) global.npcs = ds_list_create();
    if (is_undefined(global.taverns)) global.taverns = ds_list_create();
    
    var needs_init = false;
    
    if (is_undefined(global.npc_mod)) needs_init = true;
    else if (!is_struct(global.npc_mod)) needs_init = true;
    
    if (is_undefined(global.npc_base)) needs_init = true;
    else if (!is_struct(global.npc_base)) needs_init = true;
    
    if (is_undefined(global.npc_debug)) needs_init = true;
    else if (!is_struct(global.npc_debug)) needs_init = true;
    
    if (needs_init) {
        scr_npc_config_init();
    }
}

function scr_point_in_collision(_x, _y)
{
    if (is_undefined(global.navgrid)) return false;
    
    var gx = floor(_x / global.nav_cell_w);
    var gy = floor(_y / global.nav_cell_h);
    
    if (gx < 0 || gy < 0 || gx >= global.nav_grid_w || gy >= global.nav_grid_h) {
        return true;
    }
    
    return mp_grid_get_cell(global.navgrid, gx, gy);
}

function scr_find_free_point_near(_target_x, _target_y, _from_x, _from_y)
{
    if (!scr_point_in_collision(_target_x, _target_y)) {
        return { x: _target_x, y: _target_y, valid: true };
    }
    
    _npc_debug("Cel w kolizji - szukam wolnego punktu");
    
    var dir = point_direction(_target_x, _target_y, _from_x, _from_y);
    
    for (var dist = 16; dist <= 80; dist += 8) {
        var test_x = _target_x + lengthdir_x(dist, dir);
        var test_y = _target_y + lengthdir_y(dist, dir);
        
        if (!scr_point_in_collision(test_x, test_y)) {
            return { x: test_x, y: test_y, valid: true };
        }
    }
    
    for (var dist = 16; dist <= 80; dist += 8) {
        for (var angle = 0; angle < 360; angle += 30) {
            var test_x = _target_x + lengthdir_x(dist, angle);
            var test_y = _target_y + lengthdir_y(dist, angle);
            
            if (!scr_point_in_collision(test_x, test_y)) {
                return { x: test_x, y: test_y, valid: true };
            }
        }
    }
    
    _npc_debug("NIE znaleziono wolnego punktu!");
    return { x: _target_x, y: _target_y, valid: false };
}

// =============================================================================
// HELPER - POBIERZ AKTUALNĄ PORĘ DNIA
// =============================================================================

/// Zwraca aktualną porę dnia: "night", "morning", "day", "evening"
function _npc_get_phase()
{
    if (variable_global_exists("daynight_phase")) {
        return global.daynight_phase;
    }
    // Fallback jeśli nie ma systemu dnia/nocy
    if (!is_undefined(global.is_night) && global.is_night) {
        return "night";
    }
    return "day";
}

/// Zwraca progress aktualnej pory (0.0 - 1.0)
function _npc_get_phase_progress()
{
    if (variable_global_exists("daynight_phase_progress")) {
        return global.daynight_phase_progress;
    }
    return 0.5;
}

// =============================================================================
// NPC CREATE
// =============================================================================

function scr_npc_create()
{
    var _inst = argument0;
    var _kind = argument1;
    var _home = argument2;
    _ensure_global_lists();
	

    var traits = {
        pracowitosc: irandom_range(20, 80),
        wanderlust: irandom_range(10, 70),
        roztargnienie: irandom_range(5, 40),
        ciekawosc: irandom_range(10, 80),
        podatnosc: irandom_range(10, 70),
        devotion: irandom_range(0, 30),
        fanatyzm: irandom_range(10, 50),
        towarzyskosc: irandom_range(20, 80),  // NOWA CECHA - szansa na karczmę
        sluga: false,
        czas_bez_encountera: 0,
        zdrowie_psych: irandom_range(40, 100),
        stres: 0,
        insane: false,
        follower: false,
    };
    
    var modifiers = {
        pracowitosc: 0,
        wanderlust: 0,
        roztargnienie: 0,
        ciekawosc: 0,
        podatnosc: 0,
        devotion: 0,
        fanatyzm: 0,
        towarzyskosc: 0,
    };

    _inst.npc_data = {
		location_mods: {
        pracowitosc: 0,
        roztargnienie: 0,
        ciekawosc: 0,
        podatnosc: 0,
        towarzyskosc: 0,
        wanderlust: 0
    },
        kind: _kind,
        traits: traits,
        modifiers: modifiers,
        szybkosc: random_range(0.5, 1.2),
        state: "idle",
        target: noone,
        target_point: noone,
        target_type: "",
        home: _home,
        path_id: -1,
        path_started: false,
        path_failed: false,
        path_retry_timer: 0,
        deviation_timer: 0,
        original_target: noone,
        original_target_type: "",
        is_deviating: false,
        reeval_timer: irandom_range(5, 15),
        idle_timer: 0,
        work_timer: 0,
        rest_timer: 0,
        explore_timer: 0,
        tavern_timer: 0,
        detect_range: 120,
        wander_radius: 48,
        saw_encounter: noone,
        visited_encounter: false,
        last_x: _inst.x,
        last_y: _inst.y,
        sprite_idle: noone,
        sprite_walk: noone,
        sprite_work: noone,
		sprite_invisible: noone,
        
        // NOWE - plan dnia
        daily_plan: "none",           // "work", "travel", "none"
        plan_decided: false,          // czy już podjął decyzję dziś rano
        work_done_today: false,       // czy skończył pracę
        travel_done_today: false,     // czy skończył podróż
        visited_tavern_today: false,  // czy był w karczmie
        staying_late: false,          // czy zostaje do rana w karczmie
        last_phase: "night",          // do wykrywania zmiany pory
    };

    ds_list_add(global.npcs, _inst);

    if (_home != noone && instance_exists(_home)) {
        if (is_undefined(_home.settlement_data)) {
            _home.settlement_data = {resources: ds_map_create()};
        }
    }
    
	
    _npc_debug("Utworzono NPC " + string(_inst.id) + 
              " [prac=" + string(traits.pracowitosc) + 
              " wand=" + string(traits.wanderlust) + 
              " tow=" + string(traits.towarzyskosc) + "]");
    
    return _inst.npc_data;
}

// =============================================================================
// TRAIT GETTERS
// =============================================================================

function scr_npc_get_effective(_inst, _trait)
{
    if (!instance_exists(_inst)) return 0;
    if (is_undefined(_inst.npc_data)) return 0;
    
    var base = 0;
    var ind_mod = 0;
    var glob_mod = 0;
    
    if (variable_struct_exists(_inst.npc_data.traits, _trait)) {
        base = variable_struct_get(_inst.npc_data.traits, _trait);
    }
    
    if (variable_struct_exists(_inst.npc_data.modifiers, _trait)) {
        ind_mod = variable_struct_get(_inst.npc_data.modifiers, _trait);
    }
    
    if (!is_undefined(global.npc_mod) && variable_struct_exists(global.npc_mod, _trait)) {
        glob_mod = variable_struct_get(global.npc_mod, _trait);
    }
    
    return clamp(base + ind_mod + glob_mod, 0, 100);
}

function scr_npc_trait(_inst, _trait) {
    if (!instance_exists(_inst)) return 0;
    if (is_undefined(_inst.npc_data)) return 0;
    
    var base = 0;
    var ind_mod = 0;
    var glob_mod = 0;
    var loc_mod = 0;  // NOWE
    
    if (variable_struct_exists(_inst.npc_data.traits, _trait)) {
        base = variable_struct_get(_inst.npc_data.traits, _trait);
    }
    
    if (variable_struct_exists(_inst.npc_data.modifiers, _trait)) {
        ind_mod = variable_struct_get(_inst.npc_data.modifiers, _trait);
    }
    
    if (!is_undefined(global.npc_mod) && variable_struct_exists(global.npc_mod, _trait)) {
        glob_mod = variable_struct_get(global.npc_mod, _trait);
    }
    
    // === NOWE: Modyfikatory lokacyjne ===
    if (!is_undefined(_inst.npc_data.location_mods)) {
        if (variable_struct_exists(_inst.npc_data.location_mods, _trait)) {
            loc_mod = variable_struct_get(_inst.npc_data.location_mods, _trait);
        }
    }
    
    return clamp(base + ind_mod + glob_mod + loc_mod, 0, 100);
}

// =============================================================================
// PATH MANAGEMENT
// =============================================================================

function scr_npc_cleanup_path()
{
    var _inst = argument0;
    if (is_undefined(_inst.npc_data)) return;
    
    var pid = _inst.npc_data.path_id;
    if (pid != -1) {
        if (_inst.npc_data.path_started) {
            with (_inst) { path_end(); }
        }
        path_delete(pid);
        _inst.npc_data.path_id = -1;
        _inst.npc_data.path_started = false;
    }
}

function scr_npc_go_to(_inst, _target, _target_type)
{
    _npc_debug("=== scr_npc_go_to ===");
    _npc_debug("NPC " + string(_inst.id) + " -> " + _target_type);
    
    _inst.npc_data.target = _target;
    _inst.npc_data.target_type = _target_type;
    _inst.npc_data.path_failed = false;
    
    var dest_x, dest_y;
    
    if (_target_type == "point" || _target_type == "explore_point" || _target_type == "deviation_point") {
        if (is_struct(_target)) {
            dest_x = _target.x;
            dest_y = _target.y;
        } else {
            _npc_debug("BLAD: point nie jest structem!");
            _inst.npc_data.path_failed = true;
            return false;
        }
    } else {
        if (!instance_exists(_target)) {
            _npc_debug("BLAD: target nie istnieje!");
            _inst.npc_data.path_failed = true;
            return false;
        }
        
        var offset_x = INTERACTION_OFFSET_X;
        var offset_y = INTERACTION_OFFSET_Y;
        
        if (variable_instance_exists(_target, "nav_offset_x")) {
            offset_x = _target.nav_offset_x;
        }
        if (variable_instance_exists(_target, "nav_offset_y")) {
            offset_y = _target.nav_offset_y;
        }
        
        dest_x = _target.x + offset_x;
        dest_y = _target.y + offset_y;
        
        _npc_debug("Target pos: (" + string(_target.x) + "," + string(_target.y) + ") + offset (" + string(offset_x) + "," + string(offset_y) + ") = (" + string(dest_x) + "," + string(dest_y) + ")");
    }
    
    var dest_in_collision = scr_point_in_collision(dest_x, dest_y);
    _npc_debug("Punkt docelowy w kolizji: " + string(dest_in_collision));
    
    var free_point = scr_find_free_point_near(dest_x, dest_y, _inst.x, _inst.y);
    
    if (!free_point.valid) {
        _npc_debug("Nie mozna znalezc wolnego punktu docelowego!");
        _inst.npc_data.path_failed = true;
        _inst.npc_data.path_retry_timer = room_speed * 2;
        return false;
    }
    
    _npc_debug("Wolny punkt: (" + string(free_point.x) + "," + string(free_point.y) + ")");
    
    dest_x = free_point.x;
    dest_y = free_point.y;
    _inst.npc_data.target_point = { x: dest_x, y: dest_y };
    
    var start_in_collision = scr_point_in_collision(_inst.x, _inst.y);
    _npc_debug("NPC pos: (" + string(round(_inst.x)) + "," + string(round(_inst.y)) + ") w kolizji: " + string(start_in_collision));
    
    if (start_in_collision) {
        _npc_debug("!!! NPC STARTUJE Z POZYCJI W KOLIZJI !!!");
        var free_start = scr_find_free_point_near(_inst.x, _inst.y, dest_x, dest_y);
        if (free_start.valid && (free_start.x != _inst.x || free_start.y != _inst.y)) {
            _inst.x = free_start.x;
            _inst.y = free_start.y;
            _npc_debug("Przesunięto NPC do: (" + string(free_start.x) + "," + string(free_start.y) + ")");
        }
    }
    
    scr_npc_cleanup_path(_inst);
    
    if (is_undefined(global.navgrid)) {
        _npc_debug("BLAD: global.navgrid nie istnieje!");
        _inst.npc_data.path_failed = true;
        return false;
    }
    
    var p = path_add();
    var path_ok = mp_grid_path(global.navgrid, p, _inst.x, _inst.y, dest_x, dest_y, PATH_ALLOW_DIAGONAL);
    
    _npc_debug("mp_grid_path(" + string(round(_inst.x)) + "," + string(round(_inst.y)) + " -> " + string(round(dest_x)) + "," + string(round(dest_y)) + ") = " + string(path_ok));
    
    if (!path_ok) {
        var grid_max_x = global.nav_grid_w * global.nav_cell_w;
        var grid_max_y = global.nav_grid_h * global.nav_cell_h;
        _npc_debug("Navgrid granice: (0,0) do (" + string(grid_max_x) + "," + string(grid_max_y) + ")");
        _npc_debug("Room size: " + string(room_width) + "x" + string(room_height));
        
        var start_in_bounds = (_inst.x >= 0 && _inst.x < grid_max_x && _inst.y >= 0 && _inst.y < grid_max_y);
        var dest_in_bounds = (dest_x >= 0 && dest_x < grid_max_x && dest_y >= 0 && dest_y < grid_max_y);
        _npc_debug("Start w granicach: " + string(start_in_bounds) + ", Cel w granicach: " + string(dest_in_bounds));
        
        var start_gx = floor(_inst.x / global.nav_cell_w);
        var start_gy = floor(_inst.y / global.nav_cell_h);
        var dest_gx = floor(dest_x / global.nav_cell_w);
        var dest_gy = floor(dest_y / global.nav_cell_h);
        
        var start_cell = mp_grid_get_cell(global.navgrid, start_gx, start_gy);
        var dest_cell = mp_grid_get_cell(global.navgrid, dest_gx, dest_gy);
        _npc_debug("Komórka startu [" + string(start_gx) + "," + string(start_gy) + "] = " + string(start_cell));
        _npc_debug("Komórka celu [" + string(dest_gx) + "," + string(dest_gy) + "] = " + string(dest_cell));
        
        path_delete(p);
        _npc_debug("!!! SCIEZKA NIE ZNALEZIONA - NPC CZEKA !!!");
        _inst.npc_data.path_failed = true;
        _inst.npc_data.path_retry_timer = room_speed * 2;
        return false;
    }
    
    _inst.npc_data.path_id = p;
    _inst.npc_data.path_failed = false;
    
    with (_inst) {
        path_start(p, other.npc_data.szybkosc, path_action_stop, false);
    }
    _inst.npc_data.path_started = true;
    
    return true;
}

function scr_npc_check_arrived(_inst)
{
    var tp = _inst.npc_data.target_point;
    if (tp == noone || is_undefined(tp)) return false;
    
    var dist = point_distance(_inst.x, _inst.y, tp.x, tp.y);
    return (dist < INTERACTION_ARRIVAL_DIST);
}

// =============================================================================
// DISTANCE CALCULATIONS
// =============================================================================

function _scr_npc_calc_max_distance(_inst)
{
    var wanderlust = scr_npc_trait(_inst, "wanderlust");
    var base = global.npc_base;
    return base.dystans_min + wanderlust * base.dystans_scale;
}

function _scr_npc_check_distance_penalty(_inst, _target_x, _target_y)
{
    var home = _inst.npc_data.home;
    if (home == noone || !instance_exists(home)) return true;
    
    var max_dist = _scr_npc_calc_max_distance(_inst);
    var dist = point_distance(home.x, home.y, _target_x, _target_y);
    
    if (dist <= max_dist) return true;
    
    var penalty = (dist - max_dist) * global.npc_base.dystans_penalty_scale;
    return (irandom(100) >= penalty * 100);
}

// =============================================================================
// PICKERS
// =============================================================================

function scr_npc_pick_random_resource(_inst)
{
    _ensure_global_lists();
    if (ds_list_size(global.resources) <= 0) return noone;
    
    var home = _inst.npc_data.home;
    var valid = [];
    
    var n = ds_list_size(global.resources);
    for (var i = 0; i < n; i++) {
        var r = global.resources[| i];
        if (!instance_exists(r)) continue;
        
        if (home != noone && instance_exists(home)) {
            if (!_scr_npc_check_distance_penalty(_inst, r.x, r.y)) continue;
        }
        
        array_push(valid, r);
    }
    
    if (array_length(valid) == 0) {
        return global.resources[| irandom(ds_list_size(global.resources)-1)];
    }
    
    return valid[irandom(array_length(valid) - 1)];
}

/// Wybiera zasób blisko domu (do pracy lokalnej)
function scr_npc_pick_nearby_resource(_inst)
{
    _ensure_global_lists();
    if (ds_list_size(global.resources) <= 0) return noone;
    
    var home = _inst.npc_data.home;
    var max_dist = global.npc_base.dystans_min * 1.5; // Blisko domu
    var valid = [];
    
    var n = ds_list_size(global.resources);
    for (var i = 0; i < n; i++) {
        var r = global.resources[| i];
        if (!instance_exists(r)) continue;
        
        if (home != noone && instance_exists(home)) {
            var dist = point_distance(home.x, home.y, r.x, r.y);
            if (dist > max_dist) continue;
        }
        
        array_push(valid, r);
    }
    
    if (array_length(valid) == 0) return noone;
    return valid[irandom(array_length(valid) - 1)];
}

function scr_npc_pick_random_encounter(_inst)
{ 
    _ensure_global_lists();
    if (ds_list_size(global.encounters) <= 0) return noone;
    
    var home = _inst.npc_data.home;
    var max_dist = _scr_npc_calc_max_distance(_inst) * 1.5;
    var valid = [];
    
    var n = ds_list_size(global.encounters);
    for (var i = 0; i < n; i++) {
        var e = global.encounters[| i];
        if (!instance_exists(e)) continue;
        
        if (home != noone && instance_exists(home)) {
            var dist = point_distance(home.x, home.y, e.x, e.y);
            if (dist > max_dist) continue;
        }
        
        array_push(valid, e);
    }
    
    if (array_length(valid) == 0) return noone;
    return valid[irandom(array_length(valid) - 1)];
}

/// Wybiera najbliższą karczmę
function scr_npc_pick_tavern(_inst)
{
    _ensure_global_lists();
    if (ds_list_size(global.taverns) <= 0) return noone;
    
    var best = noone;
    var best_dist = 999999;
    
    var n = ds_list_size(global.taverns);
    for (var i = 0; i < n; i++) {
        var t = global.taverns[| i];
        if (!instance_exists(t)) continue;
        
        var dist = point_distance(_inst.x, _inst.y, t.x, t.y);
        if (dist < best_dist) {
            best = t;
            best_dist = dist;
        }
    }
    
    return best;
}

function scr_npc_pick_random_point(_inst)
{
    var home = _inst.npc_data.home;
    var max_dist = _scr_npc_calc_max_distance(_inst);
    
    var center_x = _inst.x;
    var center_y = _inst.y;
    
    if (home != noone && instance_exists(home)) {
        center_x = home.x;
        center_y = home.y;
    }
    
    for (var i = 0; i < 30; i++) {
        var ang = irandom(359);
        var dist = irandom_range(50, max_dist);
        var rx = center_x + lengthdir_x(dist, ang);
        var ry = center_y + lengthdir_y(dist, ang);
        
        rx = clamp(rx, 32, room_width - 32);
        ry = clamp(ry, 32, room_height - 32);
        
        if (!scr_point_in_collision(rx, ry)) {
            return { x: rx, y: ry };
        }
    }
    
    return { x: _inst.x, y: _inst.y };
}

/// Wybiera daleki punkt do podróży
function scr_npc_pick_travel_point(_inst)
{
    var home = _inst.npc_data.home;
    var max_dist = _scr_npc_calc_max_distance(_inst);
    var min_dist = max_dist * 0.5; // Przynajmniej połowa max dystansu
    
    var center_x = _inst.x;
    var center_y = _inst.y;
    
    if (home != noone && instance_exists(home)) {
        center_x = home.x;
        center_y = home.y;
    }
    
    for (var i = 0; i < 30; i++) {
        var ang = irandom(359);
        var dist = irandom_range(min_dist, max_dist);
        var rx = center_x + lengthdir_x(dist, ang);
        var ry = center_y + lengthdir_y(dist, ang);
        
        rx = clamp(rx, 32, room_width - 32);
        ry = clamp(ry, 32, room_height - 32);
        
        if (!scr_point_in_collision(rx, ry)) {
            return { x: rx, y: ry };
        }
    }
    
    return scr_npc_pick_random_point(_inst);
}

function scr_npc_pick_wander_point(_inst)
{
    var radius = _inst.npc_data.wander_radius;
    
    for (var i = 0; i < 20; i++) {
        var ang = irandom(359);
        var dist = irandom_range(16, radius);
        var rx = _inst.x + lengthdir_x(dist, ang);
        var ry = _inst.y + lengthdir_y(dist, ang);
        
        rx = clamp(rx, 32, room_width - 32);
        ry = clamp(ry, 32, room_height - 32);
        
        if (!scr_point_in_collision(rx, ry)) {
            return { x: rx, y: ry };
        }
    }
    
    return { x: _inst.x, y: _inst.y };
}

// =============================================================================
// DETECTION & DECISIONS
// =============================================================================

function scr_npc_find_encounter_in_range(_inst, _range)
{
    _ensure_global_lists();

    var best = noone;
    var bestd = _range + 1;
    var n = ds_list_size(global.encounters);
    
    for (var i = 0; i < n; i++) {
        var e = global.encounters[| i];
        if (!instance_exists(e)) continue;
        var d = point_distance(_inst.x, _inst.y, e.x, e.y);
        if (d <= _range && d < bestd) {
            best = e;
            bestd = d;
        }
    }
    
    return best;
}

function scr_npc_find_encounter_in_range_dynamic(_inst)
{
    _ensure_global_lists();

    var best = noone;
    var bestd = 999999;
    var n = ds_list_size(global.encounters);
    
    for (var i = 0; i < n; i++) {
        var e = global.encounters[| i];
        if (!instance_exists(e)) continue;
        if (is_undefined(e.encounter_data)) continue;
        
        var enc_range = _inst.npc_data.detect_range;
        if (variable_struct_exists(e.encounter_data, "zasieg")) {
            enc_range = max(enc_range, e.encounter_data.zasieg);
        }
        
        var d = point_distance(_inst.x, _inst.y, e.x, e.y);
        
        if (d <= enc_range && d < bestd) {
            best = e;
            bestd = d;
        }
    }
    
    return best;
}

function scr_npc_should_divert(_inst, _enc)
{
    if (!instance_exists(_enc)) return false;
    if (is_undefined(_enc.encounter_data)) return false;
    if (_inst.npc_data.visited_encounter) return false;

    var ed = _enc.encounter_data;
    var base = global.npc_base;
    
    var ciekawosc = scr_npc_trait(_inst, "ciekawosc");
    var value = ciekawosc * base.ciekawosc_scale + ed.sila * base.sila_bonus;
    value += irandom(30);
    
    var threshold = 60;
    if (variable_struct_exists(ed, "rzadkosc")) {
        threshold -= (ed.rzadkosc - 50) * 0.2;
    }
    
    _npc_debug("should_divert: ciekawosc=" + string(ciekawosc) + 
              " value=" + string(value) + " threshold=" + string(threshold));
    
    return (value >= threshold);
}

// =============================================================================
// DECYZJE ZALEŻNE OD PORY DNIA
// =============================================================================

/// Decyzja poranna - co NPC będzie robić dzisiaj
function scr_npc_decide_morning_plan(_inst)
{
    var nd = _inst.npc_data;
    var base = global.npc_base;
    
    // Jeśli już podjął decyzję, nie zmieniaj
    if (nd.plan_decided) return nd.daily_plan;
    
    var wanderlust = scr_npc_trait(_inst, "wanderlust");
    var pracowitosc = scr_npc_trait(_inst, "pracowitosc");
    
    // Bazowa szansa na podróż: 10% + wanderlust bonus
    var travel_chance = base.travel_base_chance + (wanderlust * base.travel_wanderlust_scale);
    
    // Pracowici mają mniejszą szansę na podróż
    travel_chance -= pracowitosc * 0.1;
    
    travel_chance = clamp(travel_chance, 5, 40);
    
    var roll = irandom(100);
    
    if (roll < travel_chance) {
        nd.daily_plan = "travel";
        _npc_debug("NPC " + string(_inst.id) + " PLAN DNIA: PODRÓŻ (roll=" + string(roll) + " < " + string(travel_chance) + ")");
    } else {
        nd.daily_plan = "work";
        _npc_debug("NPC " + string(_inst.id) + " PLAN DNIA: PRACA (roll=" + string(roll) + " >= " + string(travel_chance) + ")");
    }
    
    nd.plan_decided = true;
    return nd.daily_plan;
}

/// Główna decyzja idle zależna od pory dnia
function scr_npc_decide_idle_action(_inst)
{
    var nd = _inst.npc_data;
    var traits = nd.traits;
    var base = global.npc_base;
    var phase = _npc_get_phase();
    var phase_progress = _npc_get_phase_progress();
    
    // === NOC ===
    if (phase == "night") {
        // Jeśli zostaje późno w karczmie
        if (nd.staying_late && nd.state == "at_tavern") {
            return "stay_tavern";
        }
        
        // W nocy zawsze wracaj do domu
        // Ale może odwiedzić encounter po drodze (normalna szansa)
        if (traits.sluga) {
            var devotion = scr_npc_trait(_inst, "devotion");
            if (irandom(100) < devotion * 0.5) { // Mniejsza szansa w nocy
                return "seek_encounter";
            }
        }
        
        return "return_home";
    }
    
    // === PORANEK ===
    if (phase == "morning") {
        // Reset flag z poprzedniego dnia
        if (!nd.plan_decided) {
            nd.work_done_today = false;
            nd.travel_done_today = false;
            nd.visited_tavern_today = false;
            nd.staying_late = false;
        }
        
        // Podejmij decyzję na cały dzień
        var plan = scr_npc_decide_morning_plan(_inst);
        
        // Jeszcze wcześnie - może powander w pobliżu
        if (phase_progress < 0.3) {
            if (irandom(100) < 30) {
                return "wander";
            }
        }
        
        // Rozpocznij realizację planu
        if (plan == "travel") {
            return "start_travel";
        } else {
            return "work";
        }
    }
    
    // === DZIEŃ ===
    if (phase == "day") {
        var plan = nd.daily_plan;
        
        // Realizuj plan dnia
        if (plan == "travel" && !nd.travel_done_today) {
            // W trakcie podróży - eksploruj
            if (irandom(100) < 40) {
                return "explore";
            }
            return "continue_travel";
        }
        
        if (plan == "work" && !nd.work_done_today) {
            // W trakcie pracy - głównie pracuj
            if (irandom(100) < 70) {
                return "work";
            }
            // Czasem krótka przerwa
            return "wander";
        }
        
        // Plan wykonany - wander lub odpoczynek
        if (irandom(100) < 50) {
            return "wander";
        }
        return "wait";
    }
    
    // === WIECZÓR ===
    if (phase == "evening") {
        // Wczesny wieczór - jeszcze może pracować/eksplorować
        if (phase_progress < 0.3) {
            if (!nd.work_done_today && nd.daily_plan == "work") {
                return "work";
            }
            if (!nd.travel_done_today && nd.daily_plan == "travel") {
                return "explore";
            }
        }
        
        // Środek/późny wieczór - czas na karczmę lub dom
        if (!nd.visited_tavern_today) {
            var towarzyskosc = scr_npc_trait(_inst, "towarzyskosc");
            var tavern_chance = base.tavern_base_chance;
            
            // Bonus za towarzyskość
            tavern_chance += towarzyskosc * base.tavern_towarzyskosc_scale;
            
            // Bonus jeśli skończył plan dnia
            if (nd.work_done_today || nd.travel_done_today) {
                tavern_chance += 15;
            }
            
            tavern_chance = clamp(tavern_chance, 10, 70);
            
            if (irandom(100) < tavern_chance) {
                return "go_tavern";
            }
        }
        
        // Wracaj do domu
        return "return_home";
    }
    
    // Fallback
    return "wander";
}

// =============================================================================
// RESET DZIENNEGO PLANU (wywoływane przy zmianie na noc)
// =============================================================================

function scr_npc_reset_daily_plan(_inst)
{
    var nd = _inst.npc_data;
    nd.daily_plan = "none";
    nd.plan_decided = false;
    // Nie resetujemy work_done_today etc. - to robi się rano
}

// =============================================================================
// PATH DEVIATION
// =============================================================================

function scr_npc_check_deviation(_inst)
{
    var nd = _inst.npc_data;
    
    if (!nd.path_started) return;
    if (nd.is_deviating) return;
    if (nd.state == "working" || nd.state == "resting" || nd.state == "at_encounter" || nd.state == "at_tavern") return;
    
    nd.deviation_timer++;
    
    var interval = global.npc_base.roztarg_check_interval;
    if (nd.deviation_timer < interval) return;
    
    nd.deviation_timer = 0;
    
    var roztargnienie = scr_npc_trait(_inst, "roztargnienie");
    var szansa = roztargnienie * global.npc_base.roztarg_scale;
    
    if (irandom(100) < szansa) {
        var offset = global.npc_base.roztarg_max_offset;
        var ang = irandom(359);
        var dev_x = _inst.x + lengthdir_x(offset, ang);
        var dev_y = _inst.y + lengthdir_y(offset, ang);
        
        dev_x = clamp(dev_x, 32, room_width - 32);
        dev_y = clamp(dev_y, 32, room_height - 32);
        
        if (!scr_point_in_collision(dev_x, dev_y)) {
            nd.original_target = nd.target;
            nd.original_target_type = nd.target_type;
            nd.is_deviating = true;
            
            var dev_point = { x: dev_x, y: dev_y };
            scr_npc_go_to(_inst, dev_point, "deviation_point");
            
            _npc_debug("NPC " + string(_inst.id) + " ZBOCZYL z trasy!");
        }
    }
}

function scr_npc_resume_after_deviation(_inst)
{
    var nd = _inst.npc_data;
    
    if (!nd.is_deviating) return;
    
    nd.is_deviating = false;
    
    if (nd.original_target != noone) {
        var orig_target = nd.original_target;
        var orig_type = nd.original_target_type;
        
        nd.original_target = noone;
        nd.original_target_type = "";
        
        if (orig_type == "point" || orig_type == "explore_point" || orig_type == "travel_point") {
            if (is_struct(orig_target)) {
                scr_npc_go_to(_inst, orig_target, orig_type);
                return;
            }
        } else {
            if (instance_exists(orig_target)) {
                scr_npc_go_to(_inst, orig_target, orig_type);
                nd.state = "to_" + orig_type;
                return;
            }
        }
    }
    
    scr_npc_return_home(_inst);
}

// =============================================================================
// CULT STATUS
// =============================================================================

function scr_npc_update_cult_status(_inst)
{
    var traits = _inst.npc_data.traits;
    
    if (!traits.sluga) return;
    
    traits.czas_bez_encountera += 1;
    
    var fanatyzm = scr_npc_trait(_inst, "fanatyzm");
    var limit = fanatyzm * global.npc_base.utrata_scale * room_speed;
    
    if (traits.czas_bez_encountera > limit) {
        traits.sluga = false;
        traits.follower = false;
        traits.czas_bez_encountera = 0;
        
        if (!is_undefined(global.followers) && global.followers > 0) {
            global.followers -= 1;
        }
        
        _npc_debug("!!! NPC " + string(_inst.id) + " UTRACIL STATUS KULTYSTY !!!");
    }
}

// =============================================================================
// AKCJE
// =============================================================================

function scr_npc_start_work(_inst, _res)
{
    if (!instance_exists(_res)) return false;

    var rd = _res.resource_data;
    var time = room_speed * 2;
    if (!is_undefined(rd) && variable_struct_exists(rd, "czas_pracy")) {
        time = rd.czas_pracy;
    }
    time *= global.npc_mod.czas_pracy_mult;

    _inst.npc_data.state = "working";
    _inst.npc_data.work_timer = time;
    scr_npc_cleanup_path(_inst);
    
    return true;
}

function scr_npc_finish_work(_inst) {
    var _res = _inst.npc_data.target;
    if (instance_exists(_res) && !is_undefined(_res.resource_data)) {
        var rd = _res.resource_data;
        
        if (instance_exists(_inst.npc_data.home) && !is_undefined(_inst.npc_data.home.settlement_data)) {
            var home = _inst.npc_data.home;
            var map = home.settlement_data.resources;
            
            // === NOWE: Modyfikator produktywności od cech ===
            var productivity_mult = scr_trait_get_productivity_modifier(home);
            var actual_value = round(rd.wartosc * productivity_mult);
            
            if (!ds_map_exists(map, rd.typ)) ds_map_add(map, rd.typ, 0);
            var prev = ds_map_find_value(map, rd.typ);
            ds_map_replace(map, rd.typ, prev + actual_value);
        }
    }
    
    _inst.npc_data.work_done_today = true;
    
    var phase = _npc_get_phase();
    if (phase == "evening" || phase == "night") {
        _inst.npc_data.state = "idle";
    } else {
        _inst.npc_data.state = "idle";
    }
}
function scr_npc_handle_encounter(_inst, _enc) {
    if (!instance_exists(_enc)) return;
    
    var ed = _enc.encounter_data;
    if (is_undefined(ed)) return;
    
    _inst.npc_data.visited_encounter = true;
    _inst.npc_data.traits.czas_bez_encountera = 0;
    
    // === NOWE: Znajdź najbliższy settlement i zastosuj modyfikatory ===
    var nearest_settlement = noone;
    var min_dist = infinity;
    
    for (var i = 0; i < ds_list_size(global.settlements); i++) {
        var s = global.settlements[| i];
        if (instance_exists(s)) {
            var d = point_distance(_enc.x, _enc.y, s.x, s.y);
            if (d < min_dist) {
                min_dist = d;
                nearest_settlement = s;
            }
        }
    }
    
    // Modyfikator siły encountera od cech lokacji
    var strength_mult = 1.0;
    var fear_bonus = 0;
    if (instance_exists(nearest_settlement) && min_dist < 200) {
        strength_mult = scr_trait_get_encounter_modifier(nearest_settlement);
        fear_bonus = scr_trait_get_fear_bonus(nearest_settlement);
    }
    
    var modified_sila = ed.sila * strength_mult;
    
    var roll = irandom(100);
    var podatnosc = scr_npc_trait(_inst, "podatnosc");
    var threshold = podatnosc + modified_sila * 20;
    
    if (roll < threshold) {
        switch (ed.efekt) {
            case "strach":
                _inst.npc_data.traits.stres += modified_sila * 10;
                if (!variable_struct_exists(ed, "akumulacja_strachu")) ed.akumulacja_strachu = 0;
                ed.akumulacja_strachu += round(modified_sila) + fear_bonus;
                break;
            case "urok":
                _inst.npc_data.traits.sluga = true;
                _inst.npc_data.traits.follower = true;
                if (is_undefined(global.followers)) global.followers = 0;
                global.followers += 1;
                break;
        }
    }
}

function scr_npc_return_home(_inst)
{
    var home = _inst.npc_data.home;
    
    if (home == noone || !instance_exists(home)) {
        if (ds_list_size(global.settlements) > 0) {
            home = global.settlements[| 0];
            _inst.npc_data.home = home;
        } else {
            scr_npc_start_wander(_inst);
            return;
        }
    }

    scr_npc_go_to(_inst, home, "settlement");
    _inst.npc_data.state = "returning";
}

function scr_npc_start_rest(_inst)
{
    var base = global.npc_base;
    
    var time = irandom_range(
        base.czas_odpoczynku_min * room_speed,
        base.czas_odpoczynku_max * room_speed
    );
    time *= global.npc_mod.czas_odpoczynku_mult;
    
    _inst.npc_data.state = "resting";
    _inst.npc_data.rest_timer = time;
    _inst.npc_data.target = noone;
    _inst.npc_data.target_point = noone;
    _inst.npc_data.target_type = "";
    scr_npc_cleanup_path(_inst);
}

function scr_npc_start_explore(_inst)
{
    var p = scr_npc_pick_random_point(_inst);
    scr_npc_go_to(_inst, p, "explore_point");
    _inst.npc_data.state = "exploring";
}

function scr_npc_start_travel(_inst)
{
    var p = scr_npc_pick_travel_point(_inst);
    scr_npc_go_to(_inst, p, "travel_point");
    _inst.npc_data.state = "traveling";
    _npc_debug("NPC " + string(_inst.id) + " wyrusza w PODRÓŻ!");
}

function scr_npc_start_wander(_inst)
{
    var p = scr_npc_pick_wander_point(_inst);
    scr_npc_go_to(_inst, p, "point");
    _inst.npc_data.state = "wander";
}

function scr_npc_start_idle(_inst)
{
    _inst.npc_data.state = "idle_wait";
    _inst.npc_data.idle_timer = irandom_range(room_speed * 2, room_speed * 5);
    scr_npc_cleanup_path(_inst);
}

function scr_npc_seek_encounter(_inst)
{
    var enc = scr_npc_pick_random_encounter(_inst);
    if (enc != noone) {
        scr_npc_go_to(_inst, enc, "encounter");
        _inst.npc_data.state = "to_encounter";
    } else {
        scr_npc_start_wander(_inst);
    }
}

// =============================================================================
// AKCJE KARCZMY
// =============================================================================

function scr_npc_go_to_tavern(_inst)
{
    var tavern = scr_npc_pick_tavern(_inst);
    if (tavern != noone) {
        scr_npc_go_to(_inst, tavern, "tavern");
        _inst.npc_data.state = "to_tavern";
        _npc_debug("NPC " + string(_inst.id) + " idzie do KARCZMY!");
    } else {
        // Brak karczmy - wróć do domu
        scr_npc_return_home(_inst);
    }
}

function scr_npc_arrive_tavern(_inst)
{
    var nd = _inst.npc_data;
    var base = global.npc_base;
    
    nd.visited_tavern_today = true;
    nd.state = "at_tavern";
    scr_npc_cleanup_path(_inst);
    
    // Podstawowy czas w karczmie
    var time = irandom_range(
        base.czas_karczmy_min * room_speed,
        base.czas_karczmy_max * room_speed
    );
    
    // Czy zostaje do rana?
    var towarzyskosc = scr_npc_trait(_inst, "towarzyskosc");
    var stay_late_chance = base.stay_late_base_chance + towarzyskosc * base.stay_late_towarzyskosc_scale;
    
    if (irandom(100) < stay_late_chance) {
        nd.staying_late = true;
        // Bardzo długi czas - do rana
        time = irandom_range(
            base.czas_karczmy_late_min * room_speed,
            base.czas_karczmy_late_max * room_speed
        );
        _npc_debug("NPC " + string(_inst.id) + " zostaje w karczmie DO RANA!");
    }
    
    nd.tavern_timer = time;
    nd.target = noone;
    nd.target_point = noone;
    nd.target_type = "";
    
    _npc_debug("NPC " + string(_inst.id) + " w KARCZMIE na " + string(time / room_speed) + "s");
}

function scr_npc_leave_tavern(_inst)
{
    var nd = _inst.npc_data;
    nd.staying_late = false;
    
    var phase = _npc_get_phase();
    
    // Jeśli noc lub bardzo wczesny poranek - idź spać
    if (phase == "night" || (phase == "morning" && _npc_get_phase_progress() < 0.2)) {
        scr_npc_return_home(_inst);
    } else {
        // W innych porach - normalna decyzja
        nd.state = "idle";
    }
}

// =============================================================================
// ANIMACJE
// =============================================================================
/*
function scr_npc_update_sprite(_inst)
{
    if (is_undefined(_inst.npc_data)) return;
    
    var nd = _inst.npc_data;
    
    var dx = _inst.x - nd.last_x;
    var dy = _inst.y - nd.last_y;
    var move_dist = point_distance(0, 0, dx, dy);
    
    var is_moving = (move_dist > 0.01);
    
    if (!is_moving && nd.path_started && nd.path_id != -1) {
        with (_inst) {
            if (path_index != -1 && path_position < 0.99) {
                is_moving = true;
            }
        }
    }
    
    if (abs(dx) > 0.01) {
        _inst.image_xscale = (dx < 0) ? -1 : 1;
    }
    
    var target_sprite = noone;
    
    switch (nd.state) {
        // === NIEWIDOCZNY - w budynku ===
        case "resting":
        case "at_tavern":
        case "sleeping":
            target_sprite = spr_npc_invisible;
            break;
        
        // === PRACA ===
        case "working":
            target_sprite = (nd.sprite_work != noone) ? nd.sprite_work : nd.sprite_idle;
            break;
        
        // === IDLE ===
        case "idle":
        case "idle_wait":
        case "at_encounter":
        case "at_explore_point":
            target_sprite = nd.sprite_idle;
            break;
        
        // === DOMYŚLNIE - ruch lub idle ===
        default:
            target_sprite = is_moving ? nd.sprite_walk : nd.sprite_idle;
            break;
    }
    
    if (target_sprite != noone && _inst.sprite_index != target_sprite) {
        _inst.sprite_index = target_sprite;
    }
    
    nd.last_x = _inst.x;
    nd.last_y = _inst.y;
}
*/

function scr_npc_update_sprite(_inst)
{
    if (is_undefined(_inst.npc_data)) return;
    
    var nd = _inst.npc_data;
    
    var dx = _inst.x - nd.last_x;
    var dy = _inst.y - nd.last_y;
    var move_dist = point_distance(0, 0, dx, dy);
    
    var is_moving = (move_dist > 0.01);
    
    if (!is_moving && nd.path_started && nd.path_id != -1) {
        with (_inst) {
            if (path_index != -1 && path_position < 0.99) {
                is_moving = true;
            }
        }
    }
    
    if (abs(dx) > 0.01) {
        _inst.image_xscale = (dx < 0) ? -1 : 1;
    }
    
    var target_sprite = noone;
    
    switch (nd.state) {
        case "working":
            target_sprite = (nd.sprite_work != noone) ? nd.sprite_work : nd.sprite_idle;
            break;

        case "resting":
        case "at_tavern":
            target_sprite = (nd.sprite_invisible != noone) ? nd.sprite_invisible : nd.sprite_idle;
			scr_light_turn_off(my_light);
            break;
            
        case "idle":
        case "idle_wait":
        case "at_encounter":
        case "at_explore_point":
        case "at_travel_point":
            target_sprite = nd.sprite_idle;
            break;
            
        default:
            target_sprite = is_moving ? nd.sprite_walk : nd.sprite_idle;
			scr_light_turn_on(my_light);
            break;
    }
    
    if (target_sprite != noone && _inst.sprite_index != target_sprite) {
        _inst.sprite_index = target_sprite;
    }
    
    nd.last_x = _inst.x;
    nd.last_y = _inst.y;
}

function scr_npc_set_sprites()
{
    var _inst = argument0;
    var _idle = argument1;
    var _walk = argument2;
    var _work = argument3;
    var _invis = argument_count > 4 ? argument4 : noone;
    
    if (is_undefined(_inst.npc_data)) {
        show_debug_message("  ERROR: npc_data is undefined!");
        return;
    }
    
    _inst.npc_data.sprite_idle = _idle;
    _inst.npc_data.sprite_walk = _walk;
    _inst.npc_data.sprite_work = _work;
    _inst.npc_data.sprite_invisible = _invis;
    
    show_debug_message("  ASSIGNED - idle: " + string(_inst.npc_data.sprite_idle));
    show_debug_message("  ASSIGNED - walk: " + string(_inst.npc_data.sprite_walk));
    show_debug_message("  ASSIGNED - invis: " + string(_inst.npc_data.sprite_invisible));
    
    if (_idle != noone) _inst.sprite_index = _idle;
}

// =============================================================================
// SPRAWDZANIE ZMIANY PORY DNIA
// =============================================================================

function scr_npc_check_phase_change(_inst)
{
    var nd = _inst.npc_data;
    var current_phase = _npc_get_phase();
    
    if (nd.last_phase != current_phase) {
        _npc_debug("NPC " + string(_inst.id) + " ZMIANA PORY: " + nd.last_phase + " -> " + current_phase);
        
        // Zmiana z nocy na poranek - reset planu
        if (nd.last_phase == "night" && current_phase == "morning") {
            scr_npc_reset_daily_plan(_inst);
            nd.visited_encounter = false;
        }
        
        // Zmiana na noc - jeśli nie jest w karczmie, wróć do domu
        if (current_phase == "night" && nd.state != "at_tavern" && nd.state != "returning" && nd.state != "resting") {
            if (!nd.staying_late) {
                scr_npc_return_home(_inst);
            }
        }
        
        nd.last_phase = current_phase;
    }
}

// =============================================================================
// MAIN STEP
// =============================================================================

function scr_npc_step()
{
    var _inst = argument0;
    if (is_undefined(_inst.npc_data)) return;

    var nd = _inst.npc_data;
    
    // Timery
    if (nd.reeval_timer > 0) nd.reeval_timer -= 1;
    if (nd.idle_timer > 0) nd.idle_timer -= 1;
    if (nd.work_timer > 0) nd.work_timer -= 1;
    if (nd.rest_timer > 0) nd.rest_timer -= 1;
    if (nd.explore_timer > 0) nd.explore_timer -= 1;
    if (nd.tavern_timer > 0) nd.tavern_timer -= 1;
    if (nd.path_retry_timer > 0) nd.path_retry_timer -= 1;

    // Sprawdź zmianę pory dnia
    scr_npc_check_phase_change(_inst);
    
    scr_npc_update_cult_status(_inst);
    scr_npc_check_deviation(_inst);

    var st = nd.state;
    scr_npc_update_sprite(_inst);

    // === STANY CZEKAJĄCE ===
    
    if (st == "working") {
        if (nd.work_timer <= 0) {
            scr_npc_finish_work(_inst);
        }
        return;
    }

    if (st == "at_encounter") {
        if (nd.idle_timer <= 0) {
            var phase = _npc_get_phase();
            if (phase == "evening" || phase == "night") {
                scr_npc_return_home(_inst);
            } else {
                nd.state = "idle";
            }
        }
        return;
    }
    
    if (st == "at_tavern") {
        if (nd.tavern_timer <= 0) {
            scr_npc_leave_tavern(_inst);
        }
        return;
    }

    if (st == "resting") {
        if (nd.rest_timer <= 0) {
            nd.state = "idle";
            nd.visited_encounter = false;
        }
        return;
    }

    if (st == "idle_wait") {
        if (nd.idle_timer <= 0) {
            nd.state = "idle";
        }
        return;
    }

    if (st == "at_explore_point" || st == "at_travel_point") {
        if (nd.explore_timer <= 0) {
            if (st == "at_travel_point") {
                nd.travel_done_today = true;
                _npc_debug("NPC " + string(_inst.id) + " PODRÓŻ ZAKOŃCZONA");
            }
            
            var phase = _npc_get_phase();
            if (phase == "evening" || phase == "night") {
                scr_npc_return_home(_inst);
            } else {
                nd.state = "idle";
            }
        }
        return;
    }

    // === PRZYBYCIE DO CELU ===
    
    if (nd.path_started && scr_npc_check_arrived(_inst)) {
        var tt = nd.target_type;
        
        if (tt == "deviation_point") {
            scr_npc_resume_after_deviation(_inst);
            return;
        }
        
        if (tt == "resource") {
            scr_npc_start_work(_inst, nd.target);
            return;
        } else if (tt == "encounter") {
            scr_npc_handle_encounter(_inst, nd.target);
            return;
        } else if (tt == "tavern") {
            scr_npc_arrive_tavern(_inst);
            return;
        } else if (tt == "settlement") {
            scr_npc_cleanup_path(_inst);
            nd.target = noone;
            nd.target_point = noone;
            nd.target_type = "";
            nd.visited_encounter = false;
            scr_npc_start_rest(_inst);
            return;
        } else if (tt == "explore_point") {
            scr_npc_cleanup_path(_inst);
            var base = global.npc_base;
            var time = irandom_range(
                base.czas_eksploracji_min * room_speed,
                base.czas_eksploracji_max * room_speed
            );
            time *= global.npc_mod.czas_eksploracji_mult;
            nd.explore_timer = time;
            nd.state = "at_explore_point";
            return;
        } else if (tt == "travel_point") {
            scr_npc_cleanup_path(_inst);
            var base = global.npc_base;
            var time = irandom_range(
                base.czas_eksploracji_min * room_speed * 2,
                base.czas_eksploracji_max * room_speed * 2
            );
            nd.explore_timer = time;
            nd.state = "at_travel_point";
            return;
        } else {
            scr_npc_cleanup_path(_inst);
            nd.target = noone;
            nd.target_point = noone;
            nd.target_type = "";
            scr_npc_start_idle(_inst);
            return;
        }
    }

    // === REEWALUACJA - SZUKANIE ENCOUNTERÓW ===
    
    if (nd.reeval_timer <= 0 && !nd.is_deviating) {
        nd.reeval_timer = irandom_range(10, 20);

        if (st == "to_resource" || st == "returning" || st == "wander" || 
            st == "exploring" || st == "traveling" || st == "to_tavern" || st == "idle") {
            
            var enc = scr_npc_find_encounter_in_range_dynamic(_inst);
            if (enc != noone) {
                _npc_debug("NPC " + string(_inst.id) + " wykrył encounter w zasięgu!");
                if (scr_npc_should_divert(_inst, enc)) {
                    _npc_debug("NPC " + string(_inst.id) + " PRZEKIEROWUJE SIĘ do encountera!");
                    nd.saw_encounter = enc;
                    scr_npc_go_to(_inst, enc, "encounter");
                    nd.state = "to_encounter";
                    return;
                }
            }
        }
    }

    // === STAN IDLE - PODEJMIJ DECYZJĘ ===
    
    if (st == "idle") {
        var action = scr_npc_decide_idle_action(_inst);
        
        switch (action) {
            case "work":
                var res = scr_npc_pick_nearby_resource(_inst);
                if (res == noone) res = scr_npc_pick_random_resource(_inst);
                if (res != noone) {
                    scr_npc_go_to(_inst, res, "resource");
                    nd.state = "to_resource";
                } else {
                    scr_npc_start_wander(_inst);
                }
                break;
            
            case "start_travel":
                scr_npc_start_travel(_inst);
                break;
                
            case "continue_travel":
                if (!nd.travel_done_today) {
                    scr_npc_start_travel(_inst);
                } else {
                    scr_npc_start_wander(_inst);
                }
                break;
                
            case "seek_encounter":
                scr_npc_seek_encounter(_inst);
                break;
                
            case "explore":
                scr_npc_start_explore(_inst);
                break;
                
            case "wander":
                scr_npc_start_wander(_inst);
                break;
                
            case "return_home":
                scr_npc_return_home(_inst);
                break;
                
            case "go_tavern":
                scr_npc_go_to_tavern(_inst);
                break;
                
            case "stay_tavern":
                // Nic nie rób - zostań w karczmie
                break;
                
            case "rest":
                scr_npc_return_home(_inst);
                break;
                
            default:
                scr_npc_start_idle(_inst);
                break;
        }
        return;
    }

    // === RETRY ŚCIEŻKI ===
    
    if (nd.path_failed && nd.path_retry_timer <= 0) {
        if (nd.target != noone) {
            var success = scr_npc_go_to(_inst, nd.target, nd.target_type);
            if (!success) {
                nd.target = noone;
                nd.target_type = "";
                nd.path_failed = false;
                scr_npc_return_home(_inst);
            }
        } else {
            nd.state = "idle";
            nd.path_failed = false;
        }
        return;
    }

    // === RESTART ŚCIEŻKI ===
    
    if (!nd.path_started && !nd.path_failed && nd.target != noone) {
        if (st == "returning" || st == "to_resource" || st == "to_encounter" || st == "to_tavern") {
            if (instance_exists(nd.target)) {
                scr_npc_go_to(_inst, nd.target, nd.target_type);
            } else {
                scr_npc_return_home(_inst);
            }
        } else if (st == "wander" || st == "exploring" || st == "traveling") {
            if (is_struct(nd.target)) {
                scr_npc_go_to(_inst, nd.target, nd.target_type);
            } else {
                nd.state = "idle";
            }
        }
    }
}

// =============================================================================
// DEBUG DRAW - PATHS
// =============================================================================

function scr_npc_debug_draw_paths()
{
    if (!NPC_DEBUG) return;
    
    _draw_interactive_nav_points();
    
    if (is_undefined(global.npcs)) return;
    
    var n = ds_list_size(global.npcs);
    for (var i = 0; i < n; i++) {
        var npc = global.npcs[| i];
        if (!instance_exists(npc)) continue;
        if (is_undefined(npc.npc_data)) continue;
        
        var nd = npc.npc_data;
        
        if (nd.path_id != -1 && path_exists(nd.path_id)) {
            draw_set_color(c_aqua);
            var num = path_get_number(nd.path_id);
            for (var j = 0; j < num - 1; j++) {
                var x1 = path_get_point_x(nd.path_id, j);
                var y1 = path_get_point_y(nd.path_id, j);
                var x2 = path_get_point_x(nd.path_id, j + 1);
                var y2 = path_get_point_y(nd.path_id, j + 1);
                draw_line_width(x1, y1, x2, y2, 2);
            }
        }
        
        if (nd.target_point != noone && is_struct(nd.target_point)) {
            draw_set_color(c_lime);
            draw_circle(nd.target_point.x, nd.target_point.y, 8, false);
            
            draw_set_color(c_yellow);
            draw_line(npc.x, npc.y, nd.target_point.x, nd.target_point.y);
        }
        
        if (nd.target != noone && is_real(nd.target) && instance_exists(nd.target)) {
            draw_set_color(c_red);
            draw_circle(nd.target.x, nd.target.y, 6, true);
        }
        
        // Status z planem dnia
        var status = nd.state;
        if (nd.path_failed) status += " [BLOCKED]";
        if (nd.is_deviating) status += " [DEV]";
        if (nd.traits.sluga) status += " [KULT]";
        if (nd.daily_plan == "travel") status += " [TRAVEL]";
        if (nd.staying_late) status += " [LATE]";
        
        var col = c_white;
        if (nd.path_failed) col = c_red;
        else if (nd.traits.sluga) col = c_purple;
        else if (nd.state == "at_tavern") col = c_orange;
        else if (nd.daily_plan == "travel") col = c_aqua;
        
        draw_set_color(col);
        draw_set_halign(fa_center);
        draw_text(npc.x, npc.y - 28, status);
        draw_set_halign(fa_left);
    }
    
    draw_set_color(c_white);
}

function _draw_interactive_nav_points()
{
    // SETTLEMENTS
    if (!is_undefined(global.settlements)) {
        var n = ds_list_size(global.settlements);
        for (var i = 0; i < n; i++) {
            var obj = global.settlements[| i];
            if (!instance_exists(obj)) continue;
            _draw_nav_point(obj, c_blue, "S");
        }
    }
    
    // RESOURCES
    if (!is_undefined(global.resources)) {
        var n = ds_list_size(global.resources);
        for (var i = 0; i < n; i++) {
            var obj = global.resources[| i];
            if (!instance_exists(obj)) continue;
            _draw_nav_point(obj, c_green, "R");
        }
    }
    
    // ENCOUNTERS
    if (!is_undefined(global.encounters)) {
        var n = ds_list_size(global.encounters);
        for (var i = 0; i < n; i++) {
            var obj = global.encounters[| i];
            if (!instance_exists(obj)) continue;
            _draw_nav_point(obj, c_red, "E");
        }
    }
    
    // TAVERNS
    if (!is_undefined(global.taverns)) {
        var n = ds_list_size(global.taverns);
        for (var i = 0; i < n; i++) {
            var obj = global.taverns[| i];
            if (!instance_exists(obj)) continue;
            _draw_nav_point(obj, c_orange, "T");
        }
    }
}

function _draw_nav_point(_obj, _color, _label)
{
    var offset_x = INTERACTION_OFFSET_X;
    var offset_y = INTERACTION_OFFSET_Y;
    
    if (variable_instance_exists(_obj, "nav_offset_x")) {
        offset_x = _obj.nav_offset_x;
    }
    if (variable_instance_exists(_obj, "nav_offset_y")) {
        offset_y = _obj.nav_offset_y;
    }
    
    var nav_x = _obj.x + offset_x;
    var nav_y = _obj.y + offset_y;
    
    draw_set_color(_color);
    draw_set_alpha(0.5);
    draw_line_width(_obj.x, _obj.y, nav_x, nav_y, 1);
    
    draw_set_alpha(1);
    draw_line_width(nav_x - 6, nav_y, nav_x + 6, nav_y, 2);
    draw_line_width(nav_x, nav_y - 6, nav_x, nav_y + 6, 2);
    
    draw_circle(nav_x, nav_y, 8, true);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text(nav_x, nav_y - 10, _label);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    if (offset_x != INTERACTION_OFFSET_X || offset_y != INTERACTION_OFFSET_Y) {
        draw_set_color(c_yellow);
        draw_text(nav_x + 10, nav_y, "(" + string(offset_x) + "," + string(offset_y) + ")");
    }
}

function scr_draw_navgrid()
{
    show_debug_message("scr_draw_navgrid() wywołane");
    
    if (is_undefined(global.navgrid)) {
        show_debug_message("NAVGRID NIE ISTNIEJE!");
        return;
    }
    
    var cell_w = global.nav_cell_w;
    var cell_h = global.nav_cell_h;
    var cam_x = camera_get_view_x(view_camera[0]);
    var cam_y = camera_get_view_y(view_camera[0]);
    var cam_w = camera_get_view_width(view_camera[0]);
    var cam_h = camera_get_view_height(view_camera[0]);
    
    var start_gx = max(0, floor(cam_x / cell_w));
    var start_gy = max(0, floor(cam_y / cell_h));
    var end_gx = min(global.nav_grid_w, ceil((cam_x + cam_w) / cell_w));
    var end_gy = min(global.nav_grid_h, ceil((cam_y + cam_h) / cell_h));
    
    var blocked_count = 0;
    
    draw_set_alpha(0.5);
    
    for (var gx = start_gx; gx < end_gx; gx++) {
        for (var gy = start_gy; gy < end_gy; gy++) {
            var cell_val = mp_grid_get_cell(global.navgrid, gx, gy);
            if (cell_val != 0) {
                blocked_count++;
                draw_set_color(c_red);
                draw_rectangle(gx * cell_w, gy * cell_h, 
                               (gx + 1) * cell_w - 1, (gy + 1) * cell_h - 1, false);
            }
        }
    }
    
    draw_set_alpha(1);
    draw_set_color(c_white);
    
    draw_text(cam_x + 10, cam_y + 10, "NAVGRID: " + string(global.nav_grid_w) + "x" + string(global.nav_grid_h) + 
              " (cell: " + string(cell_w) + "x" + string(cell_h) + ") blocked: " + string(blocked_count));
    
    show_debug_message("Navgrid: blocked cells visible = " + string(blocked_count));
}



/// Usuwa NPC z osady

/*function scr_settlement_remove_resident(_settlement, _npc) {
    if (!instance_exists(_settlement)) return;
    if (is_undefined(_settlement.settlement_data)) return;
    
    var idx = ds_list_find_index(_settlement.settlement_data.residents, _npc);
    if (idx >= 0) {
        ds_list_delete(_settlement.settlement_data.residents, idx);
        _npc_debug("Usunięto mieszkańca z osady: " + string(_npc.id));
    }
}
*/
/// Zwraca liczbę mieszkańców
function scr_settlement_get_resident_count(_settlement) {
    if (!instance_exists(_settlement)) return 0;
    if (is_undefined(_settlement.settlement_data)) return 0;
    return ds_list_size(_settlement.settlement_data.residents);
}

/// Sprawdza czy osada ma wolne miejsca
function scr_settlement_has_space(_settlement) {
    if (!instance_exists(_settlement)) return false;
    if (is_undefined(_settlement.settlement_data)) return false;
    var sd = _settlement.settlement_data;
    return ds_list_size(sd.residents) < sd.max_residents;
}

