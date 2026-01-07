/// DESTROY EVENT – obj_resource_parent

// Usuń z globalnej listy
var idx = ds_list_find_index(global.resources, id);
if (idx >= 0) ds_list_delete(global.resources, idx);

// Cleanup ds_list dla traits
if (variable_instance_exists(id, "resource_data") && !is_undefined(resource_data)) {
    if (variable_struct_exists(resource_data, "traits") && ds_exists(resource_data.traits, ds_type_list)) {
        ds_list_destroy(resource_data.traits);
    }
}