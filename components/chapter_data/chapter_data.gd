extends Resource
class_name ChapterData

@export var id: String
@export var title: String
@export var required_progress_id: String 
@export_group("Default Configuration")
@export var default_configs: Dictionary[String,StringName]
@export var default_cables: Dictionary[String,StringName]
@export_group("Mission Data")
@export var missions: Array[MissionData]
