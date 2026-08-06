extends Resource
class_name MissionData

@export_group("Information")
@export var id: String
@export var title: String
@export var time: float
@export var check_progress_limit: int
@export var required_progress_id: String = ""
@export_multiline() var description: String
@export_multiline() var guide: String

@export_group("Device Data")
@export var correct_configs: Dictionary[String, StringName]
@export var runtime_configs: Dictionary[String, StringName]
@export var runtime_cables: Dictionary[String, StringName]
