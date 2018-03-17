tool
extends EditorPlugin

var main = preload("res://addons/sketchfab/Main.tscn").instance()

func _enter_tree():
	get_editor_interface().get_editor_viewport().add_child(main)
	main.visible = false
	
func _exit_tree():
	get_editor_interface().get_editor_viewport().remove_child(main)

func has_main_screen():
	return true

func get_plugin_name():
	return "Sketchfab"

func get_plugin_icon():
	return load("res://addons/sketchfab/icon.png")

func make_visible(visible):
	main.visible = visible
