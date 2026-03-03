extends Camera2D

func change_limit_camera(
	limit: Dictionary = {"b": 200, "t": -200, "l": -200, "r": 200}
) -> void:
	limit_bottom = limit.get("b", 200)
	limit_top = limit.get("t", -200)
	limit_left = limit.get("l", -200)
	limit_right = limit.get("r", 200)
