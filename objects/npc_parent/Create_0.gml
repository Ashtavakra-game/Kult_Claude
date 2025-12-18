
// CREATE EVENT NPC (zaktualizowany przykład)
/// zakłada, że scr_npc_system został zaimportowany do projektu

// Jeśli używasz systemu świateł
scr_light_register(60, c_white, spr_light);

var my_kind = "mezczyzna"; // lub przekazane parametry
var home_inst = noone;     // ustaw referencję do chaty przy tworzeniu

// Utwórz NPC data

scr_npc_create(self, "mezczyzna", home_inst);
scr_npc_set_sprites(self, spr_npc_mezczyzna_idle, spr_npc_mezczyzna_walk, spr_npc_mezczyzna_work, spr_npc_invisible);
depth = -y;

