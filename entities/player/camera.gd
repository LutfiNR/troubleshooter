extends Camera2D

func change_limit_camera(
	limit: Dictionary = {"b": 2000, "t": -2000, "l": -2000, "r": 2000}
) -> void:
	limit_bottom = limit.get("b", 2000)
	limit_top = limit.get("t", -2000)
	limit_left = limit.get("l", -2000)
	limit_right = limit.get("r", 2000)
