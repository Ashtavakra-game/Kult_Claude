event_inherited();

// Nadpisz sprity
settlement_sprite_empty = spr_hut_empty;
settlement_sprite_occupied = spr_hut_occupied;
sprite_index = settlement_sprite_empty;

// === NOWE: Konfiguracja cech dla chaty ===
settlement_data.trait_slots = 2;         // chaty mają 2 sloty
settlement_data.location_type = "chata";
settlement_data.local_faith = irandom_range(30, 70);  // losowa wiara

settlement_data.max_residents = 2;
settlement_data.name = "Chata";

// Tworzenie NPC
var num_residents = irandom_range(1, settlement_data.max_residents);
for (var i = 0; i < num_residents; i++) {
    scr_settlement_create_npc(id, npc_parent, "mezczyzna");
}