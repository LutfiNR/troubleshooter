extends Node

var current_overlay_instance: Node = null

func open_overlay(scene: PackedScene, device: Device) -> void:
	if current_overlay_instance:
		return # already open
	
	# Access the active scene currently running
	var current_scene = get_tree().current_scene
	var main = current_scene.get_node_or_null("Main")
	var overlay_container = current_scene.get_node_or_null("Overlay")

	if not main or not overlay_container:
		push_error("OverlayManager: Could not find 'Main' or 'Overlay' in " + current_scene.name)
		return

	# Instantiate and add to the Overlay node
	current_overlay_instance = scene.instantiate()
	current_overlay_instance.device = device
	overlay_container.add_child(current_overlay_instance)

	# Pause the game world and show the UI layer
	main.process_mode = Node.PROCESS_MODE_DISABLED
	main.hide()
	overlay_container.show()

	# Connect the close logic using a lambda or bind to pass the references
	current_overlay_instance.tree_exited.connect(
		func(): _on_overlay_closed(main, overlay_container)
	)
	

func _on_overlay_closed(main: Node, overlay_container: Node) -> void:
	current_overlay_instance = null
	main.process_mode = Node.PROCESS_MODE_INHERIT
	main.show()
	overlay_container.hide()
