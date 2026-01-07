/// STEP EVENT - o_game (ZAKTUALIZOWANY dla nowego systemu zasobów)

// Jeśli nie mamy odniesienia do gracza — znajdź go
if (player == noone) {
    if (instance_exists(Player)) {
        player = instance_find(Player, 0);
    } else {
        return;
    }
}

// === SYSTEM ZMIANY DNIA - RESET WIZYT ===
// Sprawdź czy zmieniła się faza z nocy na poranek
if (variable_global_exists("daynight_phase")) {
    var current_phase = global.daynight_phase;

    if (global.last_phase == "night" && current_phase == "morning") {
        // Nowy dzień - resetuj listy odwiedzonych miejsc
        scr_visit_daily_reset();
    }

    global.last_phase = current_phase;
}

// === KAMERA ===
var cam = view_camera[0];

var cam_x = player.x - camera_get_view_width(cam) / 2;
var cam_y = player.y - camera_get_view_height(cam) / 2;

cam_x = floor(cam_x);
cam_y = floor(cam_y);

camera_set_view_pos(cam, cam_x, cam_y);

// === FULLSCREEN / QUIT ===
if (keyboard_check_pressed(vk_f11)) {
    window_set_fullscreen(!window_get_fullscreen());
}
// === Kończenie gry ===
if (keyboard_check_pressed(vk_escape)) {
   //game_end();
}

// === DEBUG: NPC PRESETS (F1-F5) ===
if (keyboard_check_pressed(vk_f1)) {
    scr_npc_preset_pracowity();
}
if (keyboard_check_pressed(vk_f2)) {
    scr_npc_preset_eksplorator();
}
if (keyboard_check_pressed(vk_f3)) {
    scr_npc_preset_mistyk();
}
if (keyboard_check_pressed(vk_f4)) {
    scr_npc_preset_fanatyk();
}
if (keyboard_check_pressed(vk_f5)) {
    scr_npc_reset_global_mods();
}

// === DEBUG: Toggle encounter ranges (F6) ===
if (keyboard_check_pressed(vk_f6)) {
    global.npc_debug.show_encounter_ranges = !global.npc_debug.show_encounter_ranges;
    show_debug_message("Encounter ranges: " + string(global.npc_debug.show_encounter_ranges));
}

// === DEBUG: Toggle NPC targets (F7) ===
if (keyboard_check_pressed(vk_f7)) {
    global.npc_debug.show_npc_targets = !global.npc_debug.show_npc_targets;
    show_debug_message("NPC targets: " + string(global.npc_debug.show_npc_targets));
}

// === DEBUG: Print all NPC stats (F8) ===
if (keyboard_check_pressed(vk_f8)) {
    if (!is_undefined(global.npcs)) {
        var n = ds_list_size(global.npcs);
        for (var i = 0; i < n; i++) {
            var npc = global.npcs[| i];
            if (instance_exists(npc)) {
                scr_npc_debug_print(npc);
            }
        }
    }
}

// === DEBUG: Toggle day/night (F9) ===
if (keyboard_check_pressed(vk_f9)) {
    global.is_night = !global.is_night;
    show_debug_message("Is night: " + string(global.is_night));
}

// === DEBUG: Toggle navgrid (F10) ===
if (keyboard_check_pressed(vk_f10)) {
    if (!variable_global_exists("show_navgrid")) {
        global.show_navgrid = false;
    }
    global.show_navgrid = !global.show_navgrid;
    show_debug_message("Show navgrid: " + string(global.show_navgrid));
}

// DEBUG - sprawdź czy są settlements i NPC
if (keyboard_check_pressed(vk_f12)) {
    show_debug_message("=== DEBUG F12 ===");
    show_debug_message("Settlements: " + string(ds_list_size(global.settlements)));
    show_debug_message("NPCs: " + string(ds_list_size(global.npcs)));

    // Pokaż szczegóły settlements
    for (var i = 0; i < ds_list_size(global.settlements); i++) {
        var s = global.settlements[| i];
        if (instance_exists(s)) {
            show_debug_message("  Settlement " + string(i) + ": id=" + string(s.id) +
                " pos=(" + string(s.x) + "," + string(s.y) + ")" +
                " residents=" + string(ds_list_size(s.settlement_data.residents)));
        }
    }
}

// === DEBUG: Zasoby - Numpad ===
// Numpad 1 - Dodaj Ofiarę
if (keyboard_check_pressed(vk_numpad1)) {
    scr_add_ofiara(5, "debug");
    show_debug_message("DEBUG: +5 Ofiara. Total: " + string(global.ofiara));
}

// Numpad 2 - Odejmij Ofiarę
if (keyboard_check_pressed(vk_numpad2)) {
    scr_add_ofiara(-5, "debug");
    show_debug_message("DEBUG: -5 Ofiara. Total: " + string(global.ofiara));
}

// Numpad 4 - Dodaj Strach
if (keyboard_check_pressed(vk_numpad4)) {
    scr_add_strach(5, "debug");
    show_debug_message("DEBUG: +5 Strach. Total: " + string(global.strach));
}

// Numpad 5 - Odejmij Strach
if (keyboard_check_pressed(vk_numpad5)) {
    scr_add_strach(-5, "debug");
    show_debug_message("DEBUG: -5 Strach. Total: " + string(global.strach));
}

// Numpad 0 - Debug info zasobów
if (keyboard_check_pressed(vk_numpad0)) {
    show_debug_message("=== RESOURCE DEBUG ===");
    show_debug_message("Ofiara: " + string(global.ofiara));
    show_debug_message("Strach: " + string(global.strach));
    show_debug_message("Dzien: " + string(global.day_counter));
    show_debug_message("Tavern (gracz): " + (global.visited_today.tavern_active ? "TAK" : "NIE"));

    // Pokaż odwiedziny per NPC
    show_debug_message("Odwiedziny NPC dzis:");
    for (var i = 0; i < ds_list_size(global.npcs); i++) {
        var npc = global.npcs[| i];
        if (instance_exists(npc) && variable_instance_exists(npc, "npc_data")) {
            var nd = npc.npc_data;
            if (variable_struct_exists(nd, "visited_places_today")) {
                var vpt = nd.visited_places_today;
                var s_count = array_length(vpt.settlements);
                var e_count = array_length(vpt.encounters);
                var src_count = array_length(vpt.sources);
                if (s_count > 0 || e_count > 0 || src_count > 0) {
                    show_debug_message("  NPC " + string(npc.id) + ": S=" + string(s_count) + " E=" + string(e_count) + " Src=" + string(src_count));
                }
            }
        }
    }
}

// Numpad 9 - Wymuś reset dzienny
if (keyboard_check_pressed(vk_numpad9)) {
    scr_visit_daily_reset();
    show_debug_message("DEBUG: Forced daily reset");
}
