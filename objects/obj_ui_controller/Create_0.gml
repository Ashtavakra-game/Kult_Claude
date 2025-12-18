/// obj_ui_controller - Create Event

// Stan UI
ui_active_panel = noone;  // aktualnie otwarty panel
ui_selected_target = noone;  // kliknięty obiekt (encounter, NPC, etc.)

// Blokada sterowania gdy UI jest otwarte
global.ui_blocking_input = false;