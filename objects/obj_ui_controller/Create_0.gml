/// obj_ui_controller - Create Event

// === BEZPIECZNA INICJALIZACJA ===
// Upewnij się że globalna zmienna istnieje (może już być utworzona przez o_game)
if (!variable_global_exists("ui_blocking_input")) {
    global.ui_blocking_input = false;
}

// Stan UI
ui_active_panel = noone;
ui_selected_target = noone;

// Zmienne dla panelu karczmy
ui_tavern_visitors = [];
ui_tavern_last_result = undefined;
ui_tavern_result_timer = 0;

show_debug_message("UI CONTROLLER: Created, blocking=" + string(global.ui_blocking_input));