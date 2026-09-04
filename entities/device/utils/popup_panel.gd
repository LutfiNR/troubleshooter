extends Panel

@onready var text: RichTextLabel = $Text
@onready var ok_button: Button = $OKButton


func _ready() -> void:
	NetworkManager.error_configuration.connect(_on_error_configuration)
	visible = false


func _on_error_configuration(message: String) -> void:
	text.text = message
	visible = true


func _on_ok_button_pressed() -> void:
	visible = false
