/// scr_light_register(radius, color, spr_light)
/// Rejestruje światło przypisane do obiektu wywołującego
/// Wywołuj w Create event obiektu który ma emitować światło

function scr_light_register(_radius, _color, _sprite) {
    // Jeśli lista globalna nie istnieje, stwórz ją
    if (!variable_global_exists("lights")) {
        global.lights = ds_list_create();
    }

    // Utwórz wpis światła (struct) z referencją do właściciela
    var light = {
        owner: id,          // referencja do obiektu-właściciela
        radius: _radius,
        color: _color,
        sprite: _sprite,
        offset_x: 0,        // opcjonalny offset od pozycji właściciela
        offset_y: 0
    };

    // Zapisz referencję w obiekcie żeby móc ją później usunąć
    if (!variable_instance_exists(id, "my_light")) {
        my_light = light;
    }

    ds_list_add(global.lights, light);
    return light;
}

/// scr_light_register_offset(radius, color, spr_light, off_x, off_y)
/// Rejestruje światło z offsetem od pozycji obiektu
function scr_light_register_offset(_radius, _color, _sprite, _off_x, _off_y) {
    var light = scr_light_register(_radius, _color, _sprite);
    light.offset_x = _off_x;
    light.offset_y = _off_y;
    return light;
}

/// scr_light_unregister()
/// Usuwa światło przypisane do tego obiektu (wywołaj w Destroy/CleanUp)
function scr_light_unregister() {
    if (!variable_instance_exists(id, "my_light")) return;
    
    var idx = ds_list_find_index(global.lights, my_light);
    if (idx >= 0) {
        ds_list_delete(global.lights, idx);
    }
    my_light = undefined;
}
