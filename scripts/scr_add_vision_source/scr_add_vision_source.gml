/// @param instance_id
/// @param radius
function add_vision_source(_inst, _radius) {
    with (obj_fog_controller) {
        ds_list_add(vision_sources, {
            inst: _inst,
            radius: _radius
        });
    }
}