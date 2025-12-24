/// ============================================================================
/// SYSTEM TWORZENIA NPC PRZEZ SETTLEMENT
/// ============================================================================

/// scr_settlement_create_npc(_settlement_inst, _npc_object, _kind, [_spawn_offset])
/// Tworzy NPC przypisanego do danego settlement
/// Parametry:
///   _settlement_inst - instancja settlement (self w Create event)
///   _npc_object - obiekt NPC do utworzenia (np. npc_parent lub konkretny typ)
///   _kind - rodzaj NPC (string, np. "mezczyzna", "kobieta")
///   _spawn_offset - opcjonalny offset od pozycji settlement (domyślnie losowy 16-32px)
/// Zwraca: instance id utworzonego NPC lub noone jeśli błąd
function scr_settlement_create_npc()
{
    var _settlement = argument0;
    var _npc_obj = argument1;
    var _kind = argument2;
    var _offset = argument_count > 3 ? argument3 : irandom_range(16, 32);
    
    if (!instance_exists(_settlement)) {
        show_debug_message("ERROR: scr_settlement_create_npc - settlement nie istnieje!");
        return noone;
    }
    
    if (is_undefined(_settlement.settlement_data)) {
        show_debug_message("ERROR: scr_settlement_create_npc - brak settlement_data!");
        return noone;
    }
    
    var spawn_x = _settlement.x + -30;
    var spawn_y = _settlement.y + 40;
    
    var npc = instance_create_layer(spawn_x, spawn_y, "Instances", _npc_obj);
    
    if (!instance_exists(npc)) {
        show_debug_message("ERROR: Nie udało się utworzyć NPC!");
        return noone;
    }
    
    // Inicjalizuj NPC z referencją do settlement jako home
    scr_npc_create(npc, _kind, _settlement);
    
    // === DODAJ SPRITE'Y W ZALEŻNOŚCI OD TYPU ===
    switch (_kind) {
        case "mezczyzna":
            scr_npc_set_sprites(npc, spr_npc_mezczyzna_idle, spr_npc_mezczyzna_walk, spr_npc_mezczyzna_work, spr_npc_invisible);
            break;
        case "kobieta":
            scr_npc_set_sprites(npc, spr_npc_kobieta_idle, spr_npc_kobieta_walk, spr_npc_kobieta_work, spr_npc_invisible);
            break;
        default:
            scr_npc_set_sprites(npc, spr_npc_mezczyzna_idle, spr_npc_mezczyzna_walk, spr_npc_mezczyzna_work, spr_npc_invisible);
            break;
    }
    
    _settlement.settlement_data.population = ds_list_size(_settlement.settlement_data.residents);
    
    //show_debug_message("Settlement " + string(_settlement.id) + " utworzył NPC " + string(npc.id) + " typu " + _kind);
    
    return npc;
}
/// scr_settlement_init(_inst, _name, _initial_population, _npc_object, _npc_kind)
/// Inicjalizuje settlement z podstawowymi danymi i mieszkańcami
/// Parametry:
///   _inst - instancja settlement (self)
///   _name - nazwa settlement (string)
///   _initial_population - liczba mieszkańców do utworzenia
///   _npc_object - obiekt NPC do spawnu (np. npc_parent)
///   _npc_kind - typ NPC lub array typów (string lub array)
function scr_settlement_init()
{
    var _inst = argument0;
    var _name = argument1;
    var _initial_pop = argument2;
    var _npc_obj = argument3;
    var _npc_kind = argument4;
    
    // Zaktualizuj istniejące settlement_data (NIE nadpisuj całego struct!)
    _inst.settlement_data.name = _name;
    _inst.settlement_data.population = 0;
    _inst.settlement_data.max_population = 10;
    _inst.settlement_data.npc_object = _npc_obj;
    _inst.settlement_data.npc_kinds = _npc_kind;
    
    // Utwórz początkowych mieszkańców
    for (var i = 0; i < _initial_pop; i++) {
        var kind = _npc_kind;
        
        // Jeśli _npc_kind jest array, wybierz losowy typ
        if (is_array(_npc_kind)) {
            var idx = irandom(array_length(_npc_kind) - 1);
            kind = _npc_kind[idx];
        }
        
        scr_settlement_create_npc(_inst, _npc_obj, kind);
    }
    
    show_debug_message("Settlement '" + _name + "' zainicjalizowany z " + string(_initial_pop) + " mieszkańcami");
}

/// scr_settlement_cleanup(_inst)
/// Czyści zasoby settlement (wywołaj w Clean Up event)
function scr_settlement_cleanup()
{
    var _inst = argument0;
    
    if (is_undefined(_inst.settlement_data)) return;
    
    var sd = _inst.settlement_data;
    
    // Usuń wszystkich mieszkańców
    if (!is_undefined(sd.residents) && ds_exists(sd.residents, ds_type_list)) {
        var n = ds_list_size(sd.residents);
        for (var i = 0; i < n; i++) {
            var npc = sd.residents[| i];
            if (instance_exists(npc)) {
                instance_destroy(npc);
            }
        }
        ds_list_destroy(sd.residents);
    }
    
    // Usuń zasoby
    if (!is_undefined(sd.resources) && ds_exists(sd.resources, ds_type_map)) {
        ds_map_destroy(sd.resources);
    }
    
    // Usuń z globalnej listy
    if (!is_undefined(global.settlements)) {
        var idx = ds_list_find_index(global.settlements, _inst);
        if (idx >= 0) {
            ds_list_delete(global.settlements, idx);
        }
    }
}

/// scr_settlement_remove_resident(_inst, _npc_inst)
/// Usuwa NPC z listy mieszkańców (np. gdy umiera)
function scr_settlement_remove_resident()
{
    var _inst = argument0;
    var _npc = argument1;

    if (!instance_exists(_inst)) return;
    if (is_undefined(_inst.settlement_data)) return;
    if (is_undefined(_inst.settlement_data.residents)) return;
    // Sprawdź czy ds_list jeszcze istnieje (może być zniszczona przy cleanup)
    if (!ds_exists(_inst.settlement_data.residents, ds_type_list)) return;

    var idx = ds_list_find_index(_inst.settlement_data.residents, _npc);
    if (idx >= 0) {
        ds_list_delete(_inst.settlement_data.residents, idx);
        _inst.settlement_data.population = ds_list_size(_inst.settlement_data.residents);
        show_debug_message("Settlement " + string(_inst.id) + " stracił mieszkańca. Pozostało: " + string(_inst.settlement_data.population));
    }
}

/// scr_settlement_can_spawn_npc(_inst)
/// Sprawdza czy settlement może utworzyć nowego NPC
function scr_settlement_can_spawn_npc()
{
    var _inst = argument0;
    
    if (is_undefined(_inst.settlement_data)) return false;
    
    var sd = _inst.settlement_data;
    var current = ds_list_size(sd.residents);
    var max_pop = sd.max_population;
    if (is_undefined(max_pop)) max_pop = sd.max_residents;
    
    return (current < max_pop);
}

/// scr_settlement_spawn_new_resident(_inst)
/// Tworzy nowego mieszkańca jeśli to możliwe
/// Zwraca: instance id NPC lub noone
function scr_settlement_spawn_new_resident()
{
    var _inst = argument0;
    
    if (!scr_settlement_can_spawn_npc(_inst)) {
        show_debug_message("Settlement osiągnął maksymalną populację!");
        return noone;
    }
    
    var sd = _inst.settlement_data;
    var kind = sd.npc_kinds;
    
    if (is_array(kind)) {
        var idx = irandom(array_length(kind) - 1);
        kind = kind[idx];
    }
    
    return scr_settlement_create_npc(_inst, sd.npc_object, kind);
}

