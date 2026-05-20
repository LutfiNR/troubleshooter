extends Node

@export var export_connections: Array[NetworkConnection]

var connections: Dictionary[String, NetworkConnection]

func _ready() -> void:
	if export_connections:
		for connection in export_connections:
			connections[connection.connection_id] = connection
			print("[ConnectionManager] Total Connections: " + str(connections.size()))
			print("[ConnectionManager] " + connection.connection_id + " Connection Added")
	
func setup_connection_data(connection_data: NetworkConnection) -> void:
	connections[connection_data.connection_id] = connection_data
	print("[ConnectionManager] Total Connections: " + str(connections.size()))
	print("[ConnectionManager] " + connection_data.connection_id + " Connection Added")


func remove_connection_data(connection_id: String) -> void:
	connections.erase(connection_id)
	print("[ConnectionManager] Total Connections: " + str(connections.size()))
	print("[ConnectionManager] " + connection_id + " Connection Removed")


func get_connection(connection_id: String):
	return connections.get(connection_id)
