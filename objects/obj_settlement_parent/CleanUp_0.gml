/// CLEANUP EVENT - obj_settlement_parent (ROZSZERZONY)

// === CLEANUP CECH ===
if (!is_undefined(settlement_data.traits)) {
    if (ds_exists(settlement_data.traits, ds_type_list)) {
        // Zmniejsz liczniki użycia dla wszystkich cech
        for (var i = 0; i < ds_list_size(settlement_data.traits); i++) {
            var trait = settlement_data.traits[| i];
            scr_trait_decrement_usage(trait.name);
        }
        ds_list_destroy(settlement_data.traits);
    }
}

// Istniejący cleanup...
if (!is_undefined(settlement_data.residents) && ds_exists(settlement_data.residents, ds_type_list)) {
    var n = ds_list_size(settlement_data.residents);
    for (var i = 0; i < n; i++) {
        var npc = settlement_data.residents[| i];
        if (instance_exists(npc)) {
            instance_destroy(npc);
        }
    }
    ds_list_destroy(settlement_data.residents);
}

if (!is_undefined(settlement_data.resources) && ds_exists(settlement_data.resources, ds_type_map)) {
    ds_map_destroy(settlement_data.resources);
}

if (!is_undefined(global.settlements)) {
    var idx = ds_list_find_index(global.settlements, id);
    if (idx >= 0) {
        ds_list_delete(global.settlements, idx);
    }
}