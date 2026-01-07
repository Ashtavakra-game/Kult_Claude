/// Player Step Event
/// Ruch gracza i detekcja karczmy dla systemu zasobów

// === RUCH ===
var _hor = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var _ver = keyboard_check(ord("S")) - keyboard_check(ord("W"));

move_and_collide(_hor * move_speed, _ver * move_speed, obj_kolizja_parent);
depth = -y;

// === DETEKCJA KARCZMY DLA SYSTEMU ZASOBÓW ===
// Karczma daje +1 Ofiara i +1 Strach gdy gracz jest w pobliżu (raz na dobę)
var tavern_range = 80;

for (var i = 0; i < ds_list_size(global.taverns); i++) {
    var tavern = global.taverns[| i];
    if (instance_exists(tavern)) {
        var dist = point_distance(x, y, tavern.x, tavern.y);
        if (dist < tavern_range) {
            scr_visit_check_and_apply_player(tavern, "tavern");
        }
    }
}
