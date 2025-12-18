/// CLEAN UP EVENT - npc_parent

// Poinformuj settlement o usunięciu mieszkańca
if (!is_undefined(npc_data) && !is_undefined(npc_data.home)) {
    if (instance_exists(npc_data.home)) {
        scr_settlement_remove_resident(npc_data.home, self);
    }
}

// Usuń z globalnej listy NPC
if (!is_undefined(global.npcs)) {
    var idx = ds_list_find_index(global.npcs, id);
    if (idx >= 0) {
        ds_list_delete(global.npcs, idx);
    }
}