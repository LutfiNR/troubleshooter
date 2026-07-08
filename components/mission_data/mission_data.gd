extends Resource
class_name MissionData

@export var id: String
@export var title: String
@export var description: String
@export var time: float
@export var check_progress_limit: int
@export_multiline() var guide: String

@export var correct_configs: Dictionary[String, StringName]
@export var runtime_configs: Dictionary[String, StringName]
@export var runtime_cables: Dictionary[String, StringName]
