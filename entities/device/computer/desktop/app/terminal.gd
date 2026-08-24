extends Control

@export var output_history: RichTextLabel
@export var prompt_label: Label
@export var input_line: LineEdit
@export var scroll_container: ScrollContainer

var target_device_id: String = ""
var prompt_string: String = "C:\\> "

const AVAILABLE_COMMANDS = {
	"help": "Menampilkan daftar perintah.",
	"clear": "Membersihkan layar terminal.",
	"ipconfig": "Menampilkan konfigurasi IP saat ini.",
	"ping": "Menguji koneksi. Format: ping <ip/domain>",
	"nslookup": "Mencari informasi DNS. Format: nslookup <domain>",
	"curl": "Mengambil web HTTP. Format: curl <url>",
	"ftp": "Koneksi FTP. Format: ftp <ip/domain>",
	"ssh": "Koneksi SSH. Format: ssh user@<ip/domain>",
}


func _ready() -> void:
	if input_line:
		input_line.text_submitted.connect(_on_text_submitted)
	if prompt_label:
		prompt_label.text = prompt_string
	_print_line("Simulator Command Prompt [Version 1.0]\n")


func setup(device_id: String) -> void:
	target_device_id = device_id
	refresh_data()


func refresh_data() -> void:
	if input_line:
		input_line.grab_focus()


func _on_text_submitted(text: String) -> void:
	var raw_input = text.strip_edges()
	input_line.text = ""
	if raw_input == "":
		_print_line(prompt_string)
		return
	_print_line(prompt_string + raw_input)

	var parts = raw_input.split(" ", false)
	if parts.size() > 0:
		_process_command(parts[0].to_lower(), parts.slice(1))

	call_deferred("_scroll_to_bottom")
	input_line.grab_focus()


func _process_command(command: String, args: Array) -> void:
	match command:
		"help":
			_cmd_help()
		"clear", "cls":
			_cmd_clear()
		"ipconfig", "ifconfig":
			_cmd_ipconfig()
		"ping":
			_cmd_ping(args)
		"nslookup":
			_cmd_nslookup(args)
		"curl":
			_cmd_curl(args)
		"ftp":
			_cmd_ftp(args)
		"ssh":
			_cmd_ssh(args)
		_:
			_print_line("'" + command + "' is not recognized as a command.\n")


func _cmd_help() -> void:
	for cmd in AVAILABLE_COMMANDS.keys():
		_print_line("  " + cmd + " - " + AVAILABLE_COMMANDS[cmd])
	_print_line("")


func _cmd_clear() -> void:
	if output_history:
		output_history.text = ""


func _cmd_ipconfig() -> void:
	var device = NetworkManager.get_runtime_device_data_by_id(target_device_id) as ComputerDeviceData
	if not device:
		return
	var main_iface = device.get_interface("eth0")

	_print_line("\nEthernet adapter Local Area Connection:")
	if main_iface:
		_print_line(
			"   IPv4 Address. . . : "
			+ (main_iface.export_ip_address if main_iface.export_ip_address != "" else "0.0.0.0")
		)
		_print_line(
			"   Subnet Mask . . . : "
			+ (main_iface.export_subnet_mask if main_iface.export_subnet_mask != "" else "0.0.0.0")
		)
	_print_line(
		"   Default Gateway . : "
		+ (device.default_gateway if device.default_gateway != "" else "0.0.0.0")
	)
	_print_line(
		"   DNS Server. . . . : " + (device.dns_server if device.dns_server != "" else "0.0.0.0\n")
	)


func _resolve_target(target: String) -> String:
	if target.count(".") == 3 and target.replace(".", "").is_valid_int():
		return target
	var device = NetworkManager.get_runtime_device_data_by_id(target_device_id) as ComputerDeviceData
	if device.dns_server == "" or device.dns_server == "0.0.0.0":
		_print_line("DNS Error: No DNS server configured.\n")
		return ""
	var resolved_ip = NetworkManager.request_dns_resolve(target_device_id, target)
	if resolved_ip == "":
		_print_line("Ping request could not find host " + target + ".\n")
		return ""
	return resolved_ip


func _cmd_nslookup(args: Array) -> void:
	if args.size() == 0:
		return
	var device = NetworkManager.get_runtime_device_data_by_id(target_device_id) as ComputerDeviceData
	_print_line("Server:  " + device.dns_server)
	var resolved_ip = NetworkManager.request_dns_resolve(target_device_id, args[0])
	if resolved_ip != "":
		_print_line("Name:    " + args[0] + "\nAddress:  " + resolved_ip + "\n")
	else:
		_print_line("*** Can't find " + args[0] + ": No response from server\n")


func _cmd_ping(args: Array) -> void:
	if args.size() == 0:
		return
	var target_ip = _resolve_target(args[0])
	if target_ip == "":
		return
	_print_line("\nPinging " + args[0] + " [" + target_ip + "] with 32 bytes of data:")

	# Find the destination device by its IP across all runtime devices.
	var dst_device_id: String = ""
	for key in NetworkManager.runtime_configs:
		var device: DeviceData = NetworkManager.runtime_configs[key]
		for iface: NetworkInterface in device.interfaces:
			if iface.ip and iface.ip.ip_to_string().split("/")[0] == target_ip:
				dst_device_id = key
				break
		if dst_device_id != "":
			break

	# Use check_connectivity to validate actual network path from this computer.
	var is_reachable: bool = false
	if dst_device_id != "":
		var result: Dictionary = NetworkManager.check_connectivity(target_device_id, dst_device_id)
		is_reachable = result.get("reachable", false)
	await get_tree().create_timer(0.5).timeout
	for i in range(4):
		if is_reachable:
			_print_line("Reply from " + target_ip + ": bytes=32 time<1ms TTL=64")
		else:
			_print_line("Request timed out.")
		await get_tree().create_timer(0.8).timeout
	_print_line("")


func _cmd_curl(args: Array) -> void:
	if args.size() == 0:
		return
	var target_url = args[0].replace("http://", "").replace("https://", "")
	var target_ip = _resolve_target(target_url)
	if target_ip == "":
		return
	var response = NetworkManager.request_web(target_device_id, target_url, false)
	if response.success:
		_print_line("\n" + response.content + "\n")
	else:
		_print_line("curl: " + response.error + "\n")


func _cmd_ftp(args: Array) -> void:
	if args.size() == 0:
		return
	var target_ip = _resolve_target(args[0])
	if target_ip == "":
		return
	_print_line("Trying " + target_ip + "...")
	await get_tree().create_timer(0.5).timeout
	var server = NetworkManager._find_server_by_ip(target_ip)
	if server and server.ftp_service == ServerDeviceData.ServiceState.ON:
		_print_line("Connected to " + args[0] + ". [Gunakan App File untuk Login]\n")
	else:
		_print_line("ftp: connect: Connection refused\n")


func _cmd_ssh(args: Array) -> void:
	if args.size() == 0:
		return
	var target = args[0]
	var _username = "root"
	var host = target
	if "@" in target:
		var split = target.split("@")
		_username = split[0]
		host = split[1]
	var target_ip = _resolve_target(host)
	if target_ip == "":
		return

	await get_tree().create_timer(0.5).timeout
	var server = NetworkManager._find_server_by_ip(target_ip)
	if server and server.remote_service == ServerDeviceData.ServiceState.ON:
		_print_line("Connected. Gunakan aplikasi PuTTY (coming soon).\n")
	else:
		_print_line("ssh: connect to host port 22: Connection refused\n")


func _print_line(text: String) -> void:
	if output_history:
		output_history.text += text + "\n"


func _scroll_to_bottom() -> void:
	if scroll_container:
		await get_tree().process_frame
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
