extends Container

var data
var viewer_url

func set_data(data):
	self.data = data

func _ready():
	$Label.text = (
		_safe_get_string(data, "name") + "\n" +
		_safe_get_string(data, "publishedAt") + "\n"
	)
	viewer_url = _safe_get_string(data, "viewerUrl")

func _safe_get_string(data, key):
	return data[key] if data.has(key) && typeof(data[key]) == TYPE_STRING else ""

func _gui_input(event):
	if event is InputEventMouseButton && event.button_index == 1 && event.is_pressed():
		OS.shell_open(viewer_url)
