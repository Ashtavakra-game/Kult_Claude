/// obj_settlement_parent - Left Pressed Event
/// Otwiera panel lokacji po kliknięciu LPM

show_debug_message("SETTLEMENT CLICKED: " + string(id) + " (" + object_get_name(object_index) + ")");
scr_ui_open_location_panel(id);
