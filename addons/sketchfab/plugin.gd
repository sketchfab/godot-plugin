@tool
extends EditorPlugin

const Utils = preload("res://addons/sketchfab/Utils.gd")

var Main = preload("res://addons/sketchfab/Main.tscn")
var main 

func _enter_tree():
	main = Main.instantiate()
	get_tree().set_meta("__editor_scale", EditorInterface.get_editor_scale())
	get_tree().set_meta("__editor_interface", EditorInterface)
	get_tree().set_meta("__http_image_count", 0)
	get_editor_interface().get_editor_main_screen().add_child(main)
	main.visible = false

func _exit_tree():
	main.queue_free()

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Sketchfab"

func _get_plugin_icon():
	return load("res://addons/sketchfab/icon.png")

func _make_visible(visible):
	main.visible = visible

