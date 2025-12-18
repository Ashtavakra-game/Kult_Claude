/// =============================================================================
/// SCR_TAVERN - SYSTEM KARCZMY
/// =============================================================================
/// Funkcje do zarządzania karczmami w grze
/// =============================================================================

/// Zarejestruj karczmę w globalnej liście
/// Wywołaj w Create event obiektu karczmy
function scr_tavern_register(_inst)
{
    if (is_undefined(global.taverns)) {
        global.taverns = ds_list_create();
    }
    
    // Sprawdź czy już nie jest zarejestrowana
    var idx = ds_list_find_index(global.taverns, _inst);
    if (idx < 0) {
        ds_list_add(global.taverns, _inst);
        show_debug_message("TAVERN: Zarejestrowano karczmę " + string(_inst.id));
    }
}

/// Wyrejestruj karczmę z globalnej listy
/// Wywołaj w Destroy/CleanUp event obiektu karczmy
function scr_tavern_unregister(_inst)
{
    if (is_undefined(global.taverns)) return;
    
    var idx = ds_list_find_index(global.taverns, _inst);
    if (idx >= 0) {
        ds_list_delete(global.taverns, idx);
        show_debug_message("TAVERN: Wyrejestrowano karczmę " + string(_inst.id));
    }
}

/// Sprawdź ile NPC jest aktualnie w karczmie
function scr_tavern_get_visitor_count(_tavern)
{
    if (is_undefined(global.npcs)) return 0;
    
    var count = 0;
    var n = ds_list_size(global.npcs);
    
    for (var i = 0; i < n; i++) {
        var npc = global.npcs[| i];
        if (!instance_exists(npc)) continue;
        if (is_undefined(npc.npc_data)) continue;
        
        if (npc.npc_data.state == "at_tavern") {
            // Sprawdź czy to ta karczma (przez dystans)
            var dist = point_distance(npc.x, npc.y, _tavern.x, _tavern.y);
            if (dist < 64) {
                count++;
            }
        }
    }
    
    return count;
}

/// Pobierz listę NPC w karczmie
function scr_tavern_get_visitors(_tavern)
{
    var visitors = [];
    if (is_undefined(global.npcs)) return visitors;
    
    var n = ds_list_size(global.npcs);
    
    for (var i = 0; i < n; i++) {
        var npc = global.npcs[| i];
        if (!instance_exists(npc)) continue;
        if (is_undefined(npc.npc_data)) continue;
        
        if (npc.npc_data.state == "at_tavern") {
            var dist = point_distance(npc.x, npc.y, _tavern.x, _tavern.y);
            if (dist < 64) {
                array_push(visitors, npc);
            }
        }
    }
    
    return visitors;
}
