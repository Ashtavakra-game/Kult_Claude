/// CREATE EVENT - o_game (WERSJA 3.0)
/// Główny kontroler gry z inicjalizacją systemu NPC i karczm

window_set_fullscreen(true);
surface_resize(application_surface, 2560, 1440);

// === INICJALIZACJA ZMIENNYCH GLOBALNYCH UI (NAJPIERW!) ===
if (!variable_global_exists("ui_blocking_input")) {
    global.ui_blocking_input = false;
}

//----------------------
player = noone;

//-------------------
// GLOBAL LISTS (ds_list)

global.resources     = ds_list_create();
global.encounters    = ds_list_create();
global.settlements   = ds_list_create();
global.npcs          = ds_list_create();
global.taverns       = ds_list_create();  // NOWE - lista karczm

// UWAGA: NIE twórz global.npc_debug ani global.npc_base jako ds_list!
// Te zmienne są STRUCTAMI i są tworzone przez scr_npc_config_init()

global.fear_buffer   = 0;
global.followers     = 0;
global.madness_pool  = 0;
global.global_fear   = 0;  // Globalny poziom strachu (generowany przez aktywne encountery)

// ------------------------------------------------------
// NAVGRID
// ------------------------------------------------------

var cell = 8;
var grid_w = room_width div cell;
var grid_h = room_height div cell;

global.navgrid = mp_grid_create(0, 0, grid_w, grid_h, cell, cell);

global.nav_cell_w = cell;
global.nav_cell_h = cell;
global.nav_grid_w = grid_w;
global.nav_grid_h = grid_h;

mp_grid_add_instances(global.navgrid, obj_kolizja_parent, false);
mp_grid_add_instances(global.navgrid, obj_resource_parent, false);
mp_grid_add_instances(global.navgrid, obj_settlement_parent, false);
mp_grid_add_instances(global.navgrid, obj_encounter_parent, false);
// NOWE - jeśli karczmy mają kolizję
// mp_grid_add_instances(global.navgrid, obj_tavern, false);

// ------------------------------------------------------
// DAY/NIGHT CYCLE (stare zmienne dla kompatybilności)
// ------------------------------------------------------

global.day_length   = room_speed * 60;
global.night_length = room_speed * 45;
global.is_night     = false;

// ------------------------------------------------------
// NPC CONFIG - INICJALIZACJA SYSTEMU CECH
// WAŻNE: To tworzy global.npc_mod, global.npc_base, global.npc_debug jako STRUCTY!
// ------------------------------------------------------

scr_npc_config_init();

// Debug flags
global.show_navgrid = false;

// Możesz tu ustawić domyślne modyfikatory do testów:
// scr_npc_set_global_mod("towarzyskosc", 30);  // więcej wizyt w karczmie
// scr_npc_preset_imprezowicz();


// === SYSTEM CECH LOKACJI ===
scr_trait_system_init();
scr_cyrograf_system_init();

// Globalna wiara (nowa zmienna)
global.global_faith = 100;  // 0-100, wysoka = stabilny świat

// === SYSTEM WSKAŹNIKÓW POPULACJI ===
scr_population_system_init();

