extends Container

const SafeData = preload("res://SafeData.gd")

var data
var viewer_url

func set_data(data):
	self.data = data

func _ready():
	$Label.text = (
		SafeData.string(data, "name") + "\n" +
		SafeData.string(data, "publishedAt") + "\n"
	)
	viewer_url = SafeData.string(data, "viewerUrl")
