tool
extends WindowDialog

const SafeData = preload("res://addons/sketchfab/SafeData.gd")
const Utils = preload("res://addons/sketchfab/Utils.gd")

var api = preload("res://addons/sketchfab/Api.gd").new()

onready var label_model = find_node("Model")
onready var label_user = find_node("User")
onready var image = find_node("Image")

onready var info = find_node("Info")
onready var license = find_node("License")

var uid

func set_uid(uid):
	self.uid = uid

func _ready():
	$All.visible = false

func _on_about_to_show():
	if !uid:
		hide()
		return

	var data = yield(api.get_model_detail(uid), "completed")
	if typeof(data) != TYPE_DICTIONARY:
		hide()
		return

	label_model.text = SafeData.string(data, "name")

	var user = SafeData.dictionary(data, "user")
	label_user.text = "by %s" % SafeData.string(user, "displayName")

	var thumbnails = SafeData.dictionary(data, "thumbnails")
	var images = SafeData.array(thumbnails, "images")
	image.max_size = image.get_rect().size.x
	image.url = Utils.get_best_size_url(images, self.image.max_size, SafeData)

	var vc = SafeData.integer(data, "vertexCount")
	var fc = SafeData.integer(data, "faceCount")
	var ac = SafeData.integer(data, "animationCount")
	info.text = (
		"Vertex count: %.1fk\n" +
		"Face count: %.1fk\n" +
		"Animation: %s") % [
			vc * 0.001,
			fc * 0.001,
			"Yes" if ac else "No",
		]

	var license_data = SafeData.dictionary(data, "license")
	license.text = "%s\n(%s)" % [
		SafeData.string(license_data, "fullName"),
		SafeData.string(license_data, "requirements"),
	]

	$All.visible = true
