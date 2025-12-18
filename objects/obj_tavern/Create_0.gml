/// =============================================================================
/// OBJ_TAVERN - PRZYKŁADOWE EVENTY
/// =============================================================================
/// Skopiuj te fragmenty do odpowiednich eventów obiektu karczmy
/// =============================================================================

// =============================================================================
// CREATE EVENT
// =============================================================================

/// obj_tavern Create Event

// Zarejestruj w globalnej liście karczm
scr_tavern_register(self);

// Opcjonalne: punkt nawigacyjny (gdzie NPC się zatrzymuje)
nav_offset_x = 0;    // dostosuj do sprite'a
nav_offset_y = 65;   // NPC zatrzyma się "przed" karczmą

// Opcjonalne: dane karczmy (na przyszłość)
tavern_data = {
    nazwa: "Karczma Pod Złotym Łabędziem",
    pojemnosc: 10,  // max NPC jednocześnie (na przyszłość)
};


// =============================================================================
// DESTROY / CLEANUP EVENT
// =============================================================================
/*
/// obj_tavern Destroy/CleanUp Event

scr_tavern_unregister(self);
*/

// =============================================================================
// DRAW EVENT (opcjonalne - debug)
// =============================================================================
/*
/// obj_tavern Draw Event

draw_self();

// Debug: pokaż liczbę gości
if (NPC_DEBUG) {
    var count = scr_tavern_get_visitor_count(self);
    if (count > 0) {
        draw_set_color(c_orange);
        draw_set_halign(fa_center);
        draw_text(x, y - sprite_height - 8, "Goście: " + string(count));
        draw_set_halign(fa_left);
        draw_set_color(c_white);
    }
}
*/

// =============================================================================
// MINIMALNA WERSJA - TYLKO CREATE I CLEANUP
// =============================================================================

// Jeśli chcesz mieć najprostszą wersję:

// CREATE:
// scr_tavern_register(self);

// CLEANUP:
// scr_tavern_unregister(self);
