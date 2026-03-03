class_name ActionPopup
extends VBoxContainer

var _is_open := false
var _tween: Tween

func is_open() -> bool:
	return _is_open


func open() -> void:
	if _is_open:
		return
	
	visible = true
	modulate.a = 0.0
	scale = Vector2(0, 0)
	_is_open = true
	await _fade_to(1.0,)
	await _scale_to(Vector2(1,1))


func close() -> void:
	if not _is_open:
		return
	
	await _scale_to(Vector2(0,0))
	await _fade_to(0.0)
	_is_open = false
	visible = false


func _fade_to(target_alpha: float) -> void:
	if _tween:
		_tween.kill()

	_tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE)
	_tween.tween_property(self, "modulate:a", target_alpha, 0.15)
	await _tween.finished

func _scale_to( target_scale: Vector2) -> void:
	if _tween:
		_tween.kill()

	_tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE)
	_tween.tween_property(self, "scale", target_scale, 0.15)
	await _tween.finished
