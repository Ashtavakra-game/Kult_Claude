visible = false;
depth = -99999;
/// Rejestracja w globalnym katalogu
if (!variable_global_exists("trait_catalog")) {
    global.trait_catalog = ds_map_create();
}

// Zbuduj definicję z Variable Definitions
// Konwertuj prereq_location na tablicę valid_locations
var _valid_locs = [];
if (prereq_location == "any" || prereq_location == "all" || prereq_location == "") {
    _valid_locs = ["all"];
} else {
    _valid_locs = [prereq_location];
}

var def = {
    id: trait_id,
    display_name: trait_display_name,
    description: trait_description,
    base_cost: trait_base_cost,
    type: trait_type,
    max_level: trait_max_level,
    sprite: sprite_index,
    valid_locations: _valid_locs,

    effects: {
        fear_mult: effect_fear_mult,
        npc_roztargnienie: effect_npc_roztargnienie,
        wsm_bonus: effect_wsm_bonus
    },

    prereq: {
        trait: prereq_trait,
        location: prereq_location
    }
};

// Zarejestruj
ds_map_add(global.trait_catalog, trait_id, def);

show_debug_message("TRAIT REGISTERED: " + trait_id);