/// DESTROY EVENT – obj_zasob

var idx = ds_list_find_index(global.encounters, id);
if (idx >= 0) ds_list_delete(global.encounters, idx);