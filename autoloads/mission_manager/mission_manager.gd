extends Node

@onready var correct_configuration: MissionData = preload("uid://dwqknavuvqsr")
@onready var empty_configuration: MissionData = preload("uid://dwqknavuvqsr")

# Dictionary utama yang menampung evaluasi hierarkis untuk Tree UI
var mission_item: Dictionary = {}

func _ready() -> void:
	NetworkDeviceManager.device_updated.connect(_on_device_updated)
	if empty_configuration:
		load_mission_configuration(empty_configuration)

func load_mission_configuration(configuration: MissionData) -> void:
	if not configuration:
		return

	# Bersihkan papan simulasi sebelum memuat misi baru
	NetworkDeviceManager.computer_devices.clear()
	NetworkDeviceManager.server_devices.clear()
	NetworkDeviceManager.router_devices.clear()
	NetworkDeviceManager.switch_devices.clear()
	ConnectionManager.connections.clear()

	# Muat alat ke NetworkDeviceManager (gunakan duplicate agar data asli tidak tertimpa saat runtime)
	if configuration.computer_devices: _load_devices_to_manager(configuration.computer_devices)
	if configuration.server_devices: _load_devices_to_manager(configuration.server_devices)
	if configuration.router_devices: _load_devices_to_manager(configuration.router_devices)
	if configuration.switch_devices: _load_devices_to_manager(configuration.switch_devices)

	# Muat koneksi kabel ke ConnectionManager
	if configuration.connections:
		for conn_id in configuration.connections:
			ConnectionManager.setup_connection_data(configuration.connections[conn_id].duplicate(true))

	print("[MissionManager] Mission loaded: ", configuration.title)
	
	# Panggil evaluasi pertama kali untuk mengisi mission_item
	evaluate_mission()

func _load_devices_to_manager(devices_dict: Dictionary) -> void:
	for id in devices_dict:
		NetworkDeviceManager.add_device_data(devices_dict[id].duplicate(true))

func _on_device_updated(_device_id: String) -> void:
	# Setiap kali ada yang colok kabel/ubah IP, re-evaluasi
	evaluate_mission()

func get_mission_tree_data() -> Dictionary:
	if mission_item.is_empty():
		evaluate_mission()
	return mission_item

func evaluate_mission() -> Dictionary:
	if not correct_configuration:
		push_warning("Correct configuration is missing for grading!")
		return {"mission_cleared": false}

	var is_mission_cleared = true
	
	# Bersihkan data lama
	mission_item.clear()
	
	# Buat kantong-kantong per kategori
	var comp_results = {}
	var server_results = {}
	var router_results = {}
	var switch_results = {}

	# Verifikasi semua kategori perangkat, hasilnya dimasukkan ke kantongnya masing-masing
	is_mission_cleared = _verify_category(NetworkDeviceManager.computer_devices, correct_configuration.computer_devices, comp_results) and is_mission_cleared
	is_mission_cleared = _verify_category(NetworkDeviceManager.server_devices, correct_configuration.server_devices, server_results) and is_mission_cleared
	is_mission_cleared = _verify_category(NetworkDeviceManager.router_devices, correct_configuration.router_devices, router_results) and is_mission_cleared
	is_mission_cleared = _verify_category(NetworkDeviceManager.switch_devices, correct_configuration.switch_devices, switch_results) and is_mission_cleared

	# Cek Koneksi Fisik / Pengkabelan
	var expected_conn = correct_configuration.connections.size() if correct_configuration.connections else 0
	var current_conn = ConnectionManager.connections.size()
	var conn_status = (current_conn == expected_conn)
	
	if not conn_status:
		is_mission_cleared = false

	# Susun mission_item secara hierarkis (Bentuk Inilah yang paling gampang dibaca oleh Tree Node)
	mission_item["Komputer"] = comp_results
	mission_item["Server"] = server_results
	mission_item["Router"] = router_results
	mission_item["Switch"] = switch_results
	mission_item["Koneksi Kabel"] = {
		"status": conn_status,
		"error": "Jumlah kabel tidak sesuai (Seharusnya %d, Terpasang %d)" % [expected_conn, current_conn] if not conn_status else "",
		"expected": expected_conn,
		"current": current_conn
	}

	return {
		"mission_cleared": is_mission_cleared,
		"details": mission_item
	}

func _verify_category(runtime_dict: Dictionary, correct_dict: Dictionary, results_out: Dictionary) -> bool:
	if not correct_dict: return true
	var category_cleared = true

	for correct_id in correct_dict:
		var correct_device = correct_dict[correct_id]

		# Kasus 1: Siswa menghapus / tidak membuat alat yang diwajibkan oleh soal
		if not runtime_dict.has(correct_id):
			results_out[correct_id] = { "status": false, "error": "Device is missing" }
			category_cleared = false
			continue

		var runtime_device = runtime_dict[correct_id]
		var result = runtime_device.verify_configuration(correct_device)

		# Masukkan hasil tes ke dalam parameter "results_out" sesuai nama alat
		results_out[correct_id] = result

		# Kasus 2: Alat ada, tetapi konfigurasinya ada yang salah
		if not result.status:
			category_cleared = false

	return category_cleared
