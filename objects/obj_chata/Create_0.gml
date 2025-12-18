/// CREATE EVENT - obj_settlement_hut (DZIECKO obj_settlement_parent)

/// CREATE EVENT - obj_settlement_hut (DZIECKO obj_settlement_parent)

event_inherited();

// Nadpisz sprity
settlement_sprite_empty = spr_hut_empty;
settlement_sprite_occupied = spr_hut_occupied;

settlement_data.max_residents = 2;
settlement_data.name = "Chata";

sprite_index = settlement_sprite_empty;

// === TWORZENIE NPC - użyj ID zamiast SELF ===
var num_residents = irandom_range(1, settlement_data.max_residents);
for (var i = 0; i < num_residents; i++) {
    scr_settlement_create_npc(id, npc_parent, "mezczyzna");  // <-- ID zamiast SELF
}
