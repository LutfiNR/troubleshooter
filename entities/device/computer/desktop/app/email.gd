extends Control

@export_category("Panels")
@export var login_panel: Control
@export var main_panel: Control

@export_category("Login UI")
@export var email_input: LineEdit
@export var pass_input: LineEdit
@export var imap_input: LineEdit
@export var smtp_input: LineEdit
@export var ssl_check: CheckButton
@export var login_btn: Button
@export var login_status_label: Label

@export_category("Main UI")
@export var welcome_label: Label
@export var logout_btn: Button
@export var inbox_list: ItemList
@export var email_reader: RichTextLabel
@export var to_input: LineEdit
@export var subject_input: LineEdit
@export var body_input: TextEdit
@export var send_btn: Button
@export var send_status_label: Label

var target_device_id: String = ""
var current_logged_in_email: String = ""
var current_mail_server_ip: String = ""

func setup(device_id: String) -> void:
	target_device_id = device_id
	
	if login_btn and not login_btn.pressed.is_connected(_on_login_pressed):
		login_btn.pressed.connect(_on_login_pressed)
	if logout_btn and not logout_btn.pressed.is_connected(_on_logout_pressed):
		logout_btn.pressed.connect(_on_logout_pressed)
	if send_btn and not send_btn.pressed.is_connected(_on_send_pressed):
		send_btn.pressed.connect(_on_send_pressed)
	if inbox_list and not inbox_list.item_selected.is_connected(_on_inbox_item_selected):
		inbox_list.item_selected.connect(_on_inbox_item_selected)
		
	refresh_data()

func refresh_data() -> void:
	if current_logged_in_email == "":
		_show_login_panel()
	else:
		_show_main_panel()

func _on_login_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = pass_input.text.strip_edges()
	var imap_server = imap_input.text.strip_edges()
	
	if email == "" or password == "" or imap_server == "":
		login_status_label.text = "Error: Harap isi semua kolom!"
		return
	login_status_label.text = "Connecting to " + imap_server + "..."
	await get_tree().create_timer(0.5).timeout

	var target_ip = imap_server
	if not _is_valid_ip(imap_server):
		target_ip = GameManager.request_dns_resolve(target_device_id, imap_server)
		if target_ip == "":
			login_status_label.text = "DNS Error: Cannot resolve " + imap_server
			return
			
	var email_parts = email.split("@")
	if email_parts.size() != 2:
		login_status_label.text = "Auth Error: Format email salah."
		return
		
	var response = GameManager.request_mail_login(target_ip, email_parts[0], password)
	
	if response.success:
		var server = GameManager._find_server_by_ip(target_ip)
		if server and server.handle_mail_request() and server.handle_mail_request().domain_name != email_parts[1]:
			login_status_label.text = "Auth Error: Domain email tidak dikenali server ini."
			return
			
		current_logged_in_email = email
		current_mail_server_ip = target_ip
		login_status_label.text = ""
		_show_main_panel()
	else:
		login_status_label.text = "Auth Error: " + response.error

func _on_send_pressed() -> void:
	var client_device = GameManager.get_runtime_device_data_by_id(target_device_id) as ComputerDeviceData
	if not client_device: return
	
	var target_email = to_input.text.strip_edges()
	var subject = subject_input.text.strip_edges()
	var body = body_input.text.strip_edges()
	
	if target_email == "":
		send_status_label.text = "Harap masukkan alamat tujuan!"
		return
		
	var email_parts = target_email.split("@")
	if email_parts.size() != 2:
		send_status_label.text = "Format email tujuan salah!"
		return
		
	var target_domain = email_parts[1]
	send_status_label.text = "Sending email via SMTP..."
	await get_tree().create_timer(0.5).timeout
	
	var mx_ip = ""
	var dns_server_ip = client_device.dns_server
	var dns_server_obj = GameManager._find_server_by_ip(dns_server_ip)
	
	if dns_server_obj and dns_server_obj.dns_service == ServerDeviceData.ServiceState.ON:
		for dns_pool in dns_server_obj.dns_configuration:
			mx_ip = dns_pool.resolve_mx(target_domain)
			if mx_ip != "": break
			
	if mx_ip == "":
		send_status_label.text = "SMTP Error: MX Record untuk " + target_domain + " tidak ditemukan."
		return
		
	var target_server = GameManager._find_server_by_ip(mx_ip)
	if not target_server or target_server.mail_service == ServerDeviceData.ServiceState.OFF:
		send_status_label.text = "Delivery Failed: Mail Server tujuan (" + mx_ip + ") tidak merespon."
		return
		
	var user_exists = false
	var mail_service_obj = target_server.handle_mail_request()
	if mail_service_obj:
		for user in mail_service_obj.users:
			if user != null and user.username == email_parts[0]:
				user_exists = true
				break
				
	if user_exists:
		send_status_label.text = "Email berhasil dikirim ke " + target_email + "!"
		to_input.text = ""
		subject_input.text = ""
		body_input.text = ""
		
		if target_email == current_logged_in_email:
			inbox_list.add_item(subject + " (Baru)")
	else:
		send_status_label.text = "Bounced: User " + email_parts[0] + " tidak ditemukan di server tujuan."

func _show_login_panel() -> void:
	login_panel.show()
	main_panel.hide()
	current_logged_in_email = ""
	if pass_input: pass_input.text = ""

func _show_main_panel() -> void:
	login_panel.hide()
	main_panel.show()
	if welcome_label: welcome_label.text = "Inbox - " + current_logged_in_email
	if send_status_label: send_status_label.text = ""
	_load_dummy_inbox()

func _load_dummy_inbox() -> void:
	inbox_list.clear()
	email_reader.text = "Pilih pesan untuk membaca."
	inbox_list.add_item("Welcome to Mail Server!")
	inbox_list.add_item("Test Koneksi LKS/UKK")

func _on_inbox_item_selected(index: int) -> void:
	if index == 0:
		email_reader.text = "From: admin@server\nTo: " + current_logged_in_email + "\n\nSelamat! Anda berhasil login ke Mail Server. Konfigurasi Dovecot dan Postfix berjalan dengan baik."
	elif index == 1:
		email_reader.text = "From: juri@ukk\nTo: " + current_logged_in_email + "\n\nPastikan Anda mengetes fitur kirim (SMTP) dan MX Record berfungsi!"
	else:
		email_reader.text = "Pesan simulasi dari sistem."

func _on_logout_pressed() -> void:
	_show_login_panel()

func _is_valid_ip(ip: String) -> bool:
	return ip.count(".") == 3 and ip.replace(".", "").is_valid_int()
