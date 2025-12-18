/// CLEANUP EVENT - obj_settlement_parent

// Usuń z globalnej listy
if (!is_undefined(global.settlements)) {
    var idx = ds_list_find_index(global.settlements, id);
    if (idx >= 0) {
        ds_list_delete(global.settlements, idx);
    }
}

// Wyczyść struktury danych
if (!is_undefined(settlement_data)) {
    if (ds_exists(settlement_data.residents, ds_type_list)) {
        ds_list_destroy(settlement_data.residents);
    }
    if (ds_exists(settlement_data.resources, ds_type_map)) {
        ds_map_destroy(settlement_data.resources);
    }
}

// Wywołaj pełne czyszczenie jeśli funkcja istnieje
// scr_settlement_cleanup(self);
