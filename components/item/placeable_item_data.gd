extends ItemData
class_name PlaceableItem

enum Type{
	COMPUTER,
	SERVER,
	ROUTER,
	SWITCH
}
@export var scene: PackedScene
@export var type: Type
