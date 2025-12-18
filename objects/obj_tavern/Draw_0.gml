
// =============================================================================
// DRAW EVENT (opcjonalne - debug)
// =============================================================================

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
