extends TabBar

const PACKAGE_NEED: String = "bind9"

@export var record_list: ItemList 
@export var dns_service: CheckButton 
@export var domain_name: LineEdit
@export var type: OptionButton 
@export var target_ip_or_ns: LineEdit

var current_records: Array[DNSRecord] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDeviceData, device_id: String) -> void:
	if not record_list: return
	if target_device_id != device_id:
		target_device_id = device_id
		current_selected_index = -1
		_clear_input_fields()
	
	if device.dns_configuration.is_empty() or device.dns_configuration[0] == null:
		var default_config: Array[DNSService] = [DNSService.new()]
		device.dns_configuration = default_config
		
	var dns_config = device.dns_configuration[0] 
	if dns_service:
		dns_service.set_pressed_no_signal(device.dns_service == ServerDeviceData.ServiceState.ON)
	
	current_records = dns_config.records.duplicate()
	if current_selected_index >= current_records.size():
		current_selected_index = -1
		_clear_input_fields()
		
	_refresh_record_list()

func _refresh_record_list() -> void:
	record_list.clear()
	for i in range(current_records.size()):
		var record = current_records[i]
		if record != null:
			record_list.add_item(record.domain_name if record.domain_name != "" else "Unnamed Record")
	
	if current_selected_index > -1:
		record_list.select(current_selected_index)
	else:
		record_list.deselect_all()

func _on_record_list_item_selected(index: int) -> void:
	current_selected_index = index
	_refresh_input_fields()

func _refresh_input_fields() -> void:
	var record = _get_selected_record()
	if not record:
		_clear_input_fields()
		return
	domain_name.text = record.domain_name
	type.selected = record.type
	target_ip_or_ns.text = record.target_ip_or_name

func _get_selected_record() -> DNSRecord:
	if current_selected_index < 0 or current_selected_index >= current_records.size():
		return null
	return current_records[current_selected_index]

func _clear_input_fields() -> void:
	domain_name.text = ""
	target_ip_or_ns.text = ""

func _on_add_button_pressed() -> void:
	var new_rec = DNSRecord.new()
	new_rec.domain_name = "new.domain"
	current_records.append(new_rec)
	current_selected_index = current_records.size() - 1
	_refresh_record_list()
	_refresh_input_fields()
	_apply_to_server()

func _on_delete_button_pressed() -> void:
	if _get_selected_record() == null: return
	current_records.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_record_list()
	_apply_to_server()

func _validate_domain(domain: String) -> bool:
	var trimmed = domain.strip_edges()
	if trimmed == "":
		return true
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9][-a-zA-Z0-9]*(\\.[a-zA-Z0-9][-a-zA-Z0-9]*)+$")
	var result = regex.search(trimmed)
	return result != null


func _validate_target(target: String, record_type: int) -> bool:
	var trimmed = target.strip_edges()
	if trimmed == "":
		return true
		
	if record_type == DNSRecord.RecordType.A_RECORD:
		return IPAddress.is_valid_ip(trimmed)
	else:
		return _validate_domain(trimmed)


func _on_save_button_pressed() -> void:
	var record = _get_selected_record()
	if not record: return
	
	var new_domain = domain_name.text.strip_edges()
	var new_target = target_ip_or_ns.text.strip_edges()
	var selected_type = type.selected as DNSRecord.RecordType
	
	if not _validate_domain(new_domain):
		NetworkManager.error_configuration.emit("Invalid domain format")
		return
		
	if not _validate_target(new_target, selected_type):
		if selected_type == DNSRecord.RecordType.A_RECORD:
			NetworkManager.error_configuration.emit("Invalid IP Address format")
		else:
			NetworkManager.error_configuration.emit("Invalid target domain format")
		return
		
	record.domain_name = new_domain
	record.type = selected_type
	record.target_ip_or_name = new_target
	
	_refresh_record_list()
	_apply_to_server()

func _on_dns_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkManager.get_runtime_device_data_by_id(target_device_id) as ServerDeviceData
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if dns_service and dns_service.button_pressed:
		master_state = ServerDeviceData.ServiceState.ON
		
	var new_dns_config = DNSService.new()
	new_dns_config.records = current_records.duplicate()
	
	device.dns_service = master_state
	var configs: Array[DNSService] = [new_dns_config]
	device.dns_configuration = configs
	NetworkManager.update_device_data(target_device_id, device)
