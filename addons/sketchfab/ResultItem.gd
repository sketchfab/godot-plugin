@tool
extends MarginContainer

const SafeData = preload("res://addons/sketchfab/SafeData.gd")
const Utils = preload("res://addons/sketchfab/Utils.gd")

const ModelDialog = preload("res://addons/sketchfab/ModelDialog.tscn")

@onready var user_name = find_child("UserName")
@onready var model_name = find_child("ModelName")
@onready var image = find_child("Image")

var data

var dialog

func set_data(data):
	self.data = data


func _ready():
	if !data:
		return

	model_name.text = SafeData.string(data, "name")

	var user = SafeData.dictionary(data, "user")
	user_name.text = "by %s" % SafeData.string(user, "displayName")

	var thumbnails = SafeData.dictionary(data, "thumbnails")
	var images = SafeData.array(thumbnails, "images")
	image.url = Utils.get_best_size_url(images, self.image.max_size, SafeData)

func _on_Button_pressed():
	dialog = ModelDialog.instantiate()
	dialog.set_uid(SafeData.string(data, "uid"))
	add_child(dialog)
	dialog.close_requested.connect(_on_dialog_hide)
	dialog.popup_centered_ratio()

func _on_dialog_hide():
	dialog.queue_free()
