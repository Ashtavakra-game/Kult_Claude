/// obj_tavern - Left Pressed Event
/// Otwiera panel karczmy po kliknięciu LPM

show_debug_message("TAVERN CLICKED: " + string(id) + " (" + object_get_name(object_index) + ")");
scr_ui_open_tavern_panel(id);
