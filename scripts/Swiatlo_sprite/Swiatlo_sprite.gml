function scr_light_draw_sprite(radius){
/// scr_light_draw_sprite(radius)
///
/// @param radius

var r = argument0;

// Skala sprite'a (musi być biały)
//var scale = r / (sprite_get_width(spr_light) * 0.5);
var scale = r / (sprite_get_width(spr_light) * 1);
// Zawsze rysujemy białe światło odejmujące
draw_set_color(c_white);

draw_sprite_ext(
    spr_light,
    0,
    x,
    y,
    scale,
    scale,
    0,
    c_white,
    1
);

}