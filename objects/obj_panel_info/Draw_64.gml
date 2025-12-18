if (visible) {

    var px = 50;
    var py = 50;

    // tło panelu
	draw_set_color(c_black);
	//draw_sprite(s_ui_panel_1, 0, px+300, py+200);
var _box_nineslice = sprite_get_nineslice(s_ui_panel_1);

_box_nineslice.enabled = true;
_box_nineslice.left = 400;
_box_nineslice.right = 400;
_box_nineslice.top = 400;
_box_nineslice.bottom = 140;


    draw_set_color(c_white);
    draw_set_font(fnt_menu);

    // tytuł
    draw_text(px + 20, py + 20, title);

    // opis
    draw_text(px + 20, py + 50, description);

    // wartości liczbowe
    draw_text(px + 20, py + 100, "Wartosc A: " + string(value1));
    draw_text(px + 20, py + 120, "Wartosc B: " + string(value2));
    draw_text(px + 20, py + 140, "Wartosc C: " + string(value3));
}
