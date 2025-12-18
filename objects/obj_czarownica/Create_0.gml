// obj_kapliczka — Create
event_inherited();

//encounter_data.typ = "Czarownica i krzesiwo";
//encounter_data.zasieg = 120;        // domyślne dla kapliczki
//encounter_data.sila = 1.0;
//encounter_data.efekt = "zwodzenie";
//encounter_data.rzadkosc = 50;

// Nadpisz wartościami z edytora (jeśli ustawione)
if (zasieg != 0) encounter_data.zasieg = zasieg;
if (sila_bonus != 0) encounter_data.sila += sila_bonus;
if (efekt != "") encounter_data.efekt = efekt;

// Create event obj_encounter_parent

// Ustaw domyślne wartości TYLKO jeśli nie istnieją
if (!variable_instance_exists(id, "nav_offset_x")) {
    nav_offset_x = 30;  // domyślna wartość
}
if (!variable_instance_exists(id, "nav_offset_y")) {
    nav_offset_y = 45;  // domyślna wartość
}

// reszta kodu rodzica...