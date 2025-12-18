/// DRAW EVENT - o_game
/// Rysowanie debugowych elementów w przestrzeni świata (ścieżki, navgrid)
randomize();
// Rysuj ścieżki NPC i ich stany
scr_npc_debug_draw_paths();

// Rysuj navgrid - toggle klawiszem F10
if (variable_global_exists("show_navgrid") && global.show_navgrid) {
    scr_draw_navgrid();
}

// Rysuj okręgi encounterów w przestrzeni świata
scr_npc_debug_draw_world();
