tool
extends EditorPlugin

const Utils = preload("res://addons/sketchfab/Utils.gd")

var main = preload("res://addons/sketchfab/Main.tscn").instance()

func _enter_tree():
	get_tree().set_meta("__editor_interface", get_editor_interface())
	get_editor_interface().get_editor_viewport().add_child(main)
	main.visible = false

func _exit_tree():
	get_editor_interface().get_editor_viewport().remove_child(main)

func has_main_screen():
	return true

func get_plugin_name():
	return "Sketchfab"

func get_plugin_icon():
	return Utils.create_texture_from_file("res://addons/sketchfab/icon.png.noimport")

func make_visible(visible):
	main.visible = visible
