function draw_9slice(_spr, _x, _y, _w, _h) {

    var mx = sprite_get_nineslice(_spr);
    var my = sprite_get_nineslice(_spr);
    var mr = sprite_get_nineslice(_spr);
    var mb = sprite_get_nineslice(_spr);

    var sw = sprite_get_width(_spr);
    var sh = sprite_get_height(_spr);

    // Lewy górny róg
    draw_sprite_part(_spr, 0, 0, 0, mx, my, _x, _y);

    // Prawy górny róg
    draw_sprite_part(_spr, 0, sw - mr, 0, mr, my, _x + _w - mr, _y);

    // Lewy dolny róg
    draw_sprite_part(_spr, 0, 0, sh - mb, mx, mb, _x, _y + _h - mb);

    // Prawy dolny róg
    draw_sprite_part(_spr, 0, sw - mr, sh - mb, mr, mb, _x + _w - mr, _y + _h - mb);

    // GÓRA (stretch)
    draw_sprite_stretched_ext(
        _spr, 0,
        _x + mx, _y,
        _w - mx - mr, my,
        c_white, 1
    );

    // DÓŁ (stretch)
    draw_sprite_stretched_ext(
        _spr, 0,
        _x + mx, _y + _h - mb,
        _w - mx - mr, mb,
        c_white, 1
    );

    // LEWA (stretch)
    draw_sprite_stretched_ext(
        _spr, 0,
        _x, _y + my,
        mx, _h - my - mb,
        c_white, 1
    );

    // PRAWA (stretch)
    draw_sprite_stretched_ext(
        _spr, 0,
        _x + _w - mr, _y + my,
        mr, _h - my - mb,
        c_white, 1
    );

    // ŚRODEK (stretch)
    draw_sprite_stretched_ext(
        _spr, 0,
        _x + mx, _y + my,
        _w - mx - mr, _h - my - mb,
        c_white, 1
    );
}
