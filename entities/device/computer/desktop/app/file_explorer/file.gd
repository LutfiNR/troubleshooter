extends Control

@export var ssl_icon: TextureRect
@export var secure_texture: Texture2D
@export var unsecure_texture: Texture2D
@export var path: LineEdit
@export var content_list: ItemList
@export var credential_popup: Panel
@export var credential_username: LineEdit 
@export var credential_password: LineEdit
@export var validation_label: Label

@export var file_texture: Texture2D
@export var folder_texture: Texture2D
@export var button_container: HBoxContainer
@export var upload_button: Button
@export var delete_button: Button

@export var local_items: Array[FileExplorerItem] = []
@export var network_items: Array[FileExplorerItem] = []

var target_device_id: String
var target_ip: String = ""

var is_secure_request: bool = false
var is_logged_in: bool = false
var current_write_enable: bool = false
var current_selected_index: int = -1

# ==========================================
# INISIALISASI & METODE LOKAL
# ==========================================
func setup(device_id: String) -> void:
	target_device_id = device_id
	
	if path and not path.text_submitted.is_connected(_on_path_text_submitted):
		path.text_submitted.connect(_on_path_text_submitted)
		
	_load_local_files()
	refresh_data()

func refresh_data() -> void:
	if target_device_id == "": return
	if upload_button: upload_button.disabled = not current_write_enable
	if delete_button: delete_button.disabled = not current_write_enable

func _load_local_files() -> void:
	var device = NetworkDeviceManager.get_device_data(target_device_id)
	if device:
		path.text = "/" + device.device_id
		
	content_list.clear()
	current_selected_index = -1
	if ssl_icon: ssl_icon.texture = null
	if button_container: button_container.visible = false
	
	is_logged_in = false
	current_write_enable = true
	
	for item in local_items:
		var index = content_list.add_item(item.file_or_folder_name)
		var tex = folder_texture if item.type == FileExplorerItem.ItemType.FOLDER else file_texture
		content_list.set_item_icon(index, tex)
		
	refresh_data()

# ==========================================
# MANAJEMEN EKSPRESI JALUR (PATH) NETWORK
# ==========================================
func _on_path_text_submitted(new_text: String) -> void:
	var input_path = new_text.strip_edges()
	
	if not is_path_network(input_path):
		_load_local_files()
		return
		
	is_secure_request = input_path.begins_with("ftps://")
	var request_url = input_path.replace("ftps://", "").replace("ftp://", "").strip_edges()
	
	# Potong sub-folder tambahan jika ada (misal: ftp://192.168.1.2/var/www)
	if "/" in request_url:
		request_url = request_url.split("/")[0]
		
	target_ip = request_url
	
	# Resolusi DNS jika berupa domain string
	if not _is_valid_ip(request_url):
		target_ip = NetworkServiceManager.request_dns_resolve(target_device_id, request_url)
		if target_ip == "":
			_show_error("DNS Error: Domain '" + request_url + "' not found or server unreachable.")
			return

	# Pengecekan awal kesiapan server FTP
	var server = NetworkServiceManager._find_server_by_ip(target_ip)
	if not server or server.ftp_service == ServerDevice.ServiceState.OFF:
		_show_error("Error: Connection refused. FTP Service is OFF.")
		return

	# Cegah enkripsi silang jika tidak didukung pengaturan server
	var ftp_obj = server.handle_ftp_request()
	if is_secure_request and ftp_obj.ftps_state == FTPService.ServiceState.OFF:
		_show_error("Error: Server does not support SSL/TLS encryption (FTPS).")
		return

	open_credential_popup()

func is_path_network(check_path: String) -> bool:
	return check_path.begins_with("ftp://") or check_path.begins_with("ftps://")

# ==========================================
# POPUP KREDENSIAL LOGIN
# ==========================================
func open_credential_popup() -> void:
	if credential_username: credential_username.text = ""
	if credential_password: credential_password.text = ""
	if validation_label: validation_label.text = ""
	credential_popup.show()

func close_credential_popup() -> void:
	credential_popup.hide()

func _on_credential_login_button_pressed() -> void:
	var input_user = ""
	var input_pass = ""
	if credential_username: input_user = credential_username.text.strip_edges()
	if credential_password: input_pass = credential_password.text.strip_edges()
	
	# Tembak login request langsung ke Router Simulasi Autoload
	var response = NetworkServiceManager.request_ftp_login(target_ip, input_user, input_pass)
	
	if response.success:
		close_credential_popup()
		is_logged_in = true
		
		# Sinkronisasikan hak penulisan (write_enable) dari status server asli
		var server = NetworkServiceManager._find_server_by_ip(target_ip)
		if server and server.handle_ftp_request():
			current_write_enable = server.handle_ftp_request().write_enable
			
		path.text = path.text + response.home_dir
		
		if ssl_icon:
			ssl_icon.texture = secure_texture if is_secure_request else unsecure_texture
		
		_load_ftp_dummy_files()
		refresh_data()
	else:
		if credential_password: credential_password.text = ""
		validation_label.text = response.error

func _on_credential_cancel_button_pressed() -> void:
	if validation_label: validation_label.text = "" 
	close_credential_popup()

# ==========================================
# OPERASI MANIPULASI BUCKET DATA FTP DUMMY
# ==========================================
func _load_ftp_dummy_files() -> void:
	content_list.clear()
	current_selected_index = -1
	if button_container: button_container.visible = true
	
	for item in network_items:
		var index = content_list.add_item(item.file_or_folder_name)
		var tex = folder_texture if item.type == FileExplorerItem.ItemType.FOLDER else file_texture
		content_list.set_item_icon(index, tex)

func _on_content_list_item_selected(index: int) -> void:
	current_selected_index = index

func _on_upload_button_pressed() -> void:
	if not current_write_enable: return
	var new_file_name = "uploaded_file_" + str(randi() % 1000) + ".txt"
	var index = content_list.add_item(new_file_name)
	content_list.set_item_icon(index, file_texture)

func _on_delete_button_pressed() -> void:
	if not current_write_enable or current_selected_index == -1: return
	content_list.remove_item(current_selected_index)
	current_selected_index = -1

func _show_error(msg: String) -> void:
	content_list.clear()
	content_list.add_item(msg)
	if ssl_icon: ssl_icon.texture = unsecure_texture

func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4: return false
	for p in parts:
		if not p.is_valid_int(): return false
	return true
