// =============================================================================
// DESTROY / CLEANUP EVENT
// =============================================================================

/// obj_tavern Destroy/CleanUp Event

scr_tavern_unregister(self);

// Cleanup ds_list dla traits
if (variable_instance_exists(id, "tavern_data") && !is_undefined(tavern_data)) {
    if (variable_struct_exists(tavern_data, "traits") && ds_exists(tavern_data.traits, ds_type_list)) {
        ds_list_destroy(tavern_data.traits);
    }
}
