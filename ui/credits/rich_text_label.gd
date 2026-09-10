extends RichTextLabel

@export var scroll_speed: float = 30.0
var current_scroll: float = 0.0

func _ready():
	get_v_scroll_bar().modulate.a = 0 

func _process(delta):
	var v_scroll = get_v_scroll_bar()
	
	if v_scroll.value < v_scroll.max_value - v_scroll.page:
		current_scroll += scroll_speed * delta
		v_scroll.value = current_scroll
