extends Tree

func _ready() -> void:
	clear()
	populate_ui_tree()
	
func populate_ui_tree() -> void:
	var root = create_item()
	var data = MissionManager.get_mission_tree_data()
	# Looping level 1: Kategori (Komputer, Server, Switch, Kabel)
	for category in data.keys():
		var category_item = create_item(root)
		category_item.set_text(0, category)
		var category_data = data[category]
		for device_name in category_data.keys():
			# Abaikan metadata yang bukan merupakan dictionary dari alat
			if typeof(category_data[device_name]) != TYPE_DICTIONARY: continue
			var device_result = category_data[device_name]
			var device_item = create_item(category_item)
			var status_text = "[OK]" if device_result.get("status", false) else "[SALAH]"
			device_item.set_text(0, device_name + " " + status_text)
		 
