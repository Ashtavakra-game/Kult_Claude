/// obj_tavern - Create Event

// Zarejestruj w globalnej liście karczm
scr_tavern_register(self);

// Punkt nawigacyjny
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = 0;
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 65;
}

// Dane karczmy
tavern_data = {
    nazwa: "Karczma",
    pojemnosc: 10
};

show_debug_message("obj_tavern utworzony: " + string(id));