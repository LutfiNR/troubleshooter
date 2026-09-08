extends Control

@export var ssl_icon: TextureRect
@export var secure_texture: Texture2D
@export var unsecure_texture: Texture2D
@export var url: LineEdit
@export var web_content: RichTextLabel
@export var db_list: ItemList
@export var login_panel: Panel
@export var username: LineEdit
@export var password: LineEdit
@export var login_button: Button
@export var validation_label: Label

var target_device_id: String
var phpmyadmin_target_ip := ""


func setup(device_id: String) -> void:
	target_device_id = device_id
	if url and not url.text_submitted.is_connected(_on_url_text_submitted):
		url.text_submitted.connect(_on_url_text_submitted)
	if login_button and not login_button.pressed.is_connected(_on_login_button_pressed):
		login_button.pressed.connect(_on_login_button_pressed)
	refresh_data()


func refresh_data() -> void:
	if db_list:
		db_list.hide()
	if login_panel:
		login_panel.hide()


func _on_url_text_submitted(new_text: String) -> void:
	var raw_device := (
		NetworkManager.get_runtime_device_data_by_id(target_device_id) as ComputerDeviceData
	)
	if not raw_device:
		return

	var request_url = new_text.strip_edges()
	if request_url == "":
		return

	var is_https = request_url.begins_with("https://")
	var host_name = request_url.replace("http://", "").replace("https://", "")
	var request_path := ""
	if "/" in host_name:
		var url_parts := host_name.split("/", true, 1)
		host_name = url_parts[0]
		request_path = "/" + url_parts[1]

	var target_ip = host_name

	if not _is_valid_ip(host_name):
		target_ip = NetworkManager.request_dns_resolve(target_device_id, host_name)
		if target_ip == "":
			_show_error("DNS Error: Domain '" + host_name + "' not found or server unreachable.")
			return

	var response = NetworkManager.request_web(target_device_id, target_ip, is_https, host_name)

	if response.success:
		if request_path.to_lower() == "/phpmyadmin":
			_show_phpmyadmin_login(target_ip)
		else:
			_show_web_content(response.content)
		if ssl_icon:
			ssl_icon.texture = secure_texture if is_https else unsecure_texture
	else:
		_show_error("Error: " + response.error)


func _show_error(msg: String) -> void:
	web_content.text = msg
	if db_list:
		db_list.hide()
	if login_panel:
		login_panel.hide()
	web_content.show()
	if ssl_icon:
		ssl_icon.texture = unsecure_texture


func _show_web_content(content: String) -> void:
	if db_list:
		db_list.hide()
	web_content.show()
	web_content.text = content


func _show_phpmyadmin_login(target_ip: String) -> void:
	phpmyadmin_target_ip = target_ip
	web_content.hide()
	if db_list:
		db_list.hide()
	if validation_label:
		validation_label.text = ""
	if username:
		username.text = ""
	if password:
		password.text = ""
	if login_panel:
		login_panel.show()


func _on_login_button_pressed() -> void:
	var server: ServerDeviceData = NetworkManager.get_server_by_ip(phpmyadmin_target_ip)
	if not server:
		_show_login_error("Database server not found.")
		return
	var response := server.handle_mariadb_login(username.text.strip_edges(), password.text)
	if not response.get("success", false):
		_show_login_error(response.get("error", "Authentication failed."))
		return
	_show_database_list(server, response["user"])


func _show_database_list(server: ServerDeviceData, authenticated_user: MariaDBUser) -> void:
	var database_service: MariaDBService = server.handle_mariadb_request()
	if not database_service:
		_show_error("phpMyAdmin Error: MariaDB service is OFF.")
		return
	web_content.hide()
	if login_panel:
		login_panel.hide()
	if not db_list:
		return
	db_list.clear()
	db_list.show()
	for database in database_service.databases:
		if database != null:
			if authenticated_user.username == "root" \
					or authenticated_user.privileges.has(database.db_name):
				db_list.add_item(database.db_name)


func _show_login_error(message: String) -> void:
	if validation_label:
		validation_label.text = message


func _is_valid_ip(text: String) -> bool:
	return IPAddress.is_valid_ip(text)
