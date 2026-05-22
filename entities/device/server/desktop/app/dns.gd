extends TabBar

@export var record_list: ItemList 
@export var dns_service: CheckButton 
@export var domain_name: LineEdit
@export var type: OptionButton 
@export var target_ip_or_ns: LineEdit

var package_need: String = "bind9"
var current_records: Array[DNSRecord] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDevice, device_id: String) -> void:
	if not record_list: return
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	if device.dns_configuration.is_empty() or device.dns_configuration[0] == null:
		device.dns_configuration = [DNSService.new()]
		
	var dns_config = device.dns_configuration[0] 
	if dns_service:
		dns_service.set_pressed_no_signal(device.dns_service == ServerDevice.ServiceState.ON)
	
	current_records = dns_config.records.duplicate()
	_refresh_record_list()

func _refresh_record_list() -> void:
	record_list.clear()
	for i in range(current_records.size()):
		var record = current_records[i]
		if record != null:
			record_list.add_item(record.domain_name if record.domain_name != "" else "Unnamed Record")

func _on_record_list_item_selected(index: int) -> void:
	current_selected_index = index
	var record = current_records[index]
	if record:
		domain_name.text = record.domain_name
		type.selected = record.type
		target_ip_or_ns.text = record.target_ip_or_name

func _clear_input_fields() -> void:
	domain_name.text = ""
	target_ip_or_ns.text = ""

func _on_add_button_pressed() -> void:
	var new_rec = DNSRecord.new()
	new_rec.domain_name = "new.domain"
	current_records.append(new_rec)
	_refresh_record_list()
	_apply_to_server()

func _on_delete_button_pressed() -> void:
	if current_selected_index == -1: return
	current_records.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_record_list()
	_apply_to_server()

func _on_save_button_pressed() -> void:
	if current_selected_index == -1: return
	var record = current_records[current_selected_index]
	record.domain_name = domain_name.text.strip_edges()
	record.type = type.selected as DNSRecord.RecordType
	record.target_ip_or_name = target_ip_or_ns.text.strip_edges()
	
	_refresh_record_list()
	record_list.select(current_selected_index)
	_apply_to_server()

func _on_dns_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ServerDevice
	if not device: return
	
	var master_state = ServerDevice.ServiceState.OFF
	if dns_service and dns_service.button_pressed:
		master_state = ServerDevice.ServiceState.ON
		
	var new_dns_config = DNSService.new()
	new_dns_config.records = current_records.duplicate()
	
	device.dns_service = master_state
	device.dns_configuration = [new_dns_config]
	NetworkDeviceManager.update_device(target_device_id, device)
