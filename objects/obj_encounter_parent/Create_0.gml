// obj_encounter_parent — Create (na samym początku)

// Domyślne wartości jeśli nie zdefiniowane
if (!variable_instance_exists(id, "typ")) typ = "";
if (!variable_instance_exists(id, "zasieg")) zasieg = 0;
if (!variable_instance_exists(id, "sila_bonus")) sila_bonus = 0;
if (!variable_instance_exists(id, "efekt")) efekt = "";



encounter_data = {
    typ: (typ != "") ? typ : "kapliczka",
    zasieg: (zasieg != 0) ? zasieg : 120,
    sila: 1.0 + sila_bonus,
    poziom: 1,
    efekt: (efekt != "") ? efekt : "strach",
    rzadkosc: 50,
    akumulacja_strachu: 0
};

ds_list_add(global.encounters, id);