extends Control

@export var ssl_icon: TextureRect
@export var secure_texture: Texture2D
@export var unsecure_texture: Texture2D
@export var url: LineEdit
@export var web_content: RichTextLabel

var target_device_id: String

func setup(device_id: String) -> void:
	target_device_id = device_id
	if url and not url.text_submitted.is_connected(_on_url_text_submitted):
		url.text_submitted.connect(_on_url_text_submitted)
	refresh_data()

func refresh_data() -> void:
	pass

func _on_url_text_submitted(new_text: String) -> void:
	var raw_device = NetworkDeviceManager.get_device_data(target_device_id) as ComputerDevice
	if not raw_device: return
	
	var request_url = new_text.strip_edges()
	if request_url == "": return
	
	var is_https = request_url.begins_with("https://")
	request_url = request_url.replace("http://", "").replace("https://", "")
		
	var target_ip = request_url
	
	if not _is_valid_ip(request_url):
		target_ip = NetworkServiceManager.request_dns_resolve(target_device_id, request_url)
		if target_ip == "":
			_show_error("DNS Error: Domain '" + request_url + "' not found or server unreachable.")
			return
	
	# Minta NetworkServiceManager untuk HTTP Request
	var response = NetworkServiceManager.request_web(target_device_id, target_ip, is_https)
	
	if response.success:
		web_content.text = response.content
		if ssl_icon: ssl_icon.texture = secure_texture if is_https else unsecure_texture
	else:
		_show_error("Error: " + response.error)

func _show_error(msg: String) -> void:
	web_content.text = msg
	if ssl_icon: ssl_icon.texture = unsecure_texture

func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4: return false
	for p in parts:
		if not p.is_valid_int(): return false
	return true
