





var _hor = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var _ver = keyboard_check(ord("S")) - keyboard_check(ord("W"));

move_and_collide(_hor * move_speed, _ver * move_speed, obj_kolizja_parent);
depth = -y;

/*
// W utwórz instancję lub w kodzie obiektu
instance_create_layer(x, y, layer, obj_clear_fog);

// Albo jeśli masz już obiekt i chcesz mu dać widzenie:
with (obj_moj_sprite) {
    object_set_parent(object_index, obj_clear_fog);
    vision_radius = 5;
}
*/
//add_vision_source(id, 3);
//scr_light_flicker(my_light, 0.8, 0.15);