extends Node

signal device_updated(device_id: String, device_data: DeviceData)

signal cable_updated(cable_id: String, cable_data: CableData)

signal error_configuration(message: String)
