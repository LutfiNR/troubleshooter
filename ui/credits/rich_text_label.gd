extends RichTextLabel

@export var scroll_speed: float = 30.0
var current_scroll: float = 0.0
var v_scroll: VScrollBar

func _ready():
	v_scroll = get_v_scroll_bar()
	v_scroll.modulate.a = 0 

func _process(delta):
	if v_scroll.value < v_scroll.max_value - v_scroll.page:
		current_scroll += scroll_speed * delta
		v_scroll.value = current_scroll
	else:
		v_scroll.value = v_scroll.min_value
		current_scroll = 0
