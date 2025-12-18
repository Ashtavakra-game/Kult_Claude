// obj_daynight Destroy
if (variable_global_exists("lights")) {
    // opcjonalnie: sprawdź i usuń struct/zasoby w liście jeśli trzeba
    ds_list_destroy(global.lights);
    global.lights = undefined;
}
