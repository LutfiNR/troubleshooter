extends Panel

@onready var title: Label = $Title

func set_title(_title: String)-> void:
	title.text = _title
