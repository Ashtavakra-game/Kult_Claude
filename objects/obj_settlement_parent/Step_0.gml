/// STEP EVENT - obj_settlement_parent

depth = -y;

var residents_inside = 0;
var home_radius = 75;

var n = ds_list_size(global.npcs);
for (var i = 0; i < n; i++) {

    var npc = global.npcs[| i];
    if (instance_exists(npc) && !is_undefined(npc.npc_data)) {
        // Tylko NPC których DOM to ten settlement
        if (npc.npc_data.home == id) {
            var dist = point_distance(x, y, npc.x, npc.y);
            if (dist < home_radius && npc.npc_data.state == "resting") {
                residents_inside++;
            }
        }
    }
}

if (residents_inside > 0) {
    sprite_index = settlement_sprite_occupied;
} else {
    sprite_index = settlement_sprite_empty;
}