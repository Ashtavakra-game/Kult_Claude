/// CREATE EVENT - obj_tavern (ROZSZERZONA WERSJA)
/*
scr_tavern_register(self);

nav_offset_x = 0;
nav_offset_y = 65;

// === NOWE: Dane cech dla karczmy ===
settlement_data = {
    trait_slots: 3,              // karczmy mają 3 sloty
    traits: ds_list_create(),
    location_type: "karczma",
    local_faith: 40,             // karczmy mają niższą wiarę
    accumulated_fear: 0
};

tavern_data = {
    nazwa: "Karczma Pod Złotym Łabędziem",
    pojemnosc: 10,
};

*/

event_inherited();

// Ustaw offsety nawigacyjne
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = -65;
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 55;
}

// Opcjonalnie: nadpisz dane karczmy
if (variable_instance_exists(id, "tavern_data")) {
    tavern_data.nazwa = "Karczma";
}

show_debug_message("obj_karczma utworzona: " + string(id));