/// DESTROY EVENT – obj_encounter_parent

// Usuń z globalnej listy
var idx = ds_list_find_index(global.encounters, id);
if (idx >= 0) ds_list_delete(global.encounters, idx);

// Cleanup ds_list dla traits
if (variable_instance_exists(id, "encounter_data") && !is_undefined(encounter_data)) {
    if (variable_struct_exists(encounter_data, "traits") && ds_exists(encounter_data.traits, ds_type_list)) {
        ds_list_destroy(encounter_data.traits);
    }
}