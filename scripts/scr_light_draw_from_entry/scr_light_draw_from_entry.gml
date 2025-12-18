/// scr_light_draw_from_entry(e)
/// Rysuje światło (subtract pass) - pobiera aktualną pozycję z właściciela
/// ZAKTUALIZOWANA WERSJA - obsługuje parametr intensity

function scr_light_draw_from_entry(e) {
    // Pobierz aktualną pozycję z właściciela (jeśli istnieje)
    var lx, ly;
   
    if (variable_struct_exists(e, "owner") && instance_exists(e.owner)) {
        lx = e.owner.x + e.offset_x;
        ly = e.owner.y + e.offset_y;
    } else if (variable_struct_exists(e, "x")) {
        // Fallback dla świateł statycznych (bez właściciela)
        lx = e.x;
        ly = e.y;
    } else {
        return; // Brak pozycji - pomiń
    }

    // Pobierz intensity (domyślnie 1.0 jeśli nie ustawiono)
    var intensity = 1.0;
    if (variable_struct_exists(e, "intensity")) {
        intensity = e.intensity;
    }
    
    // Jeśli światło jest wyłączone, nie rysuj go
    if (intensity <= 0) return;

    // Skala zależna od sprite'a i intensity
    // Intensity wpływa zarówno na rozmiar jak i przezroczystość
    var base_scale = e.radius / (sprite_get_width(e.sprite) * 0.5);
    var scale = base_scale * lerp(0.3, 1.0, intensity); // min 30% rozmiaru przy intensity 0

    draw_sprite_ext(
        e.sprite,
        0,
        lx, ly,
        scale, scale,
        0,
        c_white,
        intensity  // alpha zależna od intensity
    );
}
