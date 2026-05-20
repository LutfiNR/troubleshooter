extends Node

var connections: Dictionary[String, NetworkConnection] = { }


func _ready() -> void:
	# Dikosongkan agar MissionManager yang menyuntikkan data saat misi dimuat
	pass


func setup_connection_data(connection_data: NetworkConnection) -> void:
	if not connection_data or connection_data.connection_id.is_empty():
		return

	connections[connection_data.connection_id] = connection_data
	print("[ConnectionManager] Connection Added: ", connection_data.connection_id)


func remove_connection_data(connection_id: String) -> void:
	if connections.erase(connection_id):
		print("[ConnectionManager] Connection Removed: ", connection_id)


func get_connection(connection_id: String) -> NetworkConnection:
	return connections.get(connection_id)

# --- FUNGSI TAMBAHAN UNTUK VALIDASI TOPOLOGI ---


# Ambil semua kabel yang menancap pada satu alat tertentu
func get_connections_for_device(device_id: String) -> Array[NetworkConnection]:
	var result: Array[NetworkConnection] = []
	for conn in connections.values():
		if conn.device_a_id == device_id or conn.device_b_id == device_id:
			result.append(conn)
	return result


# Cek spesifik apakah Alat A (di Port A) terhubung langsung ke Alat B (di Port B)
func are_devices_connected(device_a: String, interface_a: String, device_b: String, interface_b: String) -> bool:
	for conn in connections.values():
		if (conn.device_a_id == device_a and conn.interface_a_id == interface_a and conn.device_b_id == device_b and conn.interface_b_id == interface_b) or \
				(conn.device_a_id == device_b and conn.interface_a_id == interface_b and conn.device_b_id == device_a and conn.interface_b_id == interface_a):
			return true
	return false
