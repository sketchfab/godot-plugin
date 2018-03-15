extends Container

const SafeData = preload("res://SafeData.gd")

onready var user_name = find_node("UserName")
onready var model_name = find_node("ModelName")
onready var image = find_node("Image")

var data

func set_data(data):
	self.data = data

func _ready():
	model_name.text = SafeData.string(data, "name")
	
	var user = SafeData.dictionary(data, "user")
	user_name.text = "by %s" % SafeData.string(user, "displayName")
	
	var thumbnails = SafeData.dictionary(data, "thumbnails")
	var images = SafeData.array(thumbnails, "images")
	
	var smallest_size = 10e20
	var smallest_url
	for img in images:
		var size = SafeData.integer(img, "width") * SafeData.integer(img, "height")
		if size < smallest_size:
			smallest_size = size
			smallest_url = SafeData.string(img, "url")
	self.image.url = smallest_url
