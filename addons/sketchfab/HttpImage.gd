@tool
extends TextureRect

const MAX_COUNT = 4

@export var max_size = 256
@export var background = Color(0, 0, 0, 0)
@export var immediate = false

var url : set = _set_url
var url_to_load

var http_request = null
var busy

func _enter_tree():

	if !http_request:
		http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(self._http_request_completed)
		http_request.set_tls_options(TLSOptions.client())

	busy = false
	if url_to_load:
		_start_load()

func _exit_tree():
	if busy:
		http_request.cancel_request()
		get_tree().set_meta("__http_image_count", get_tree().get_meta("__http_image_count") - 1)
		busy = false




func _set_url(url):
	url_to_load = url
	if !is_inside_tree():
		return

	_start_load()

func _start_load():
	http_request.cancel_request()
	texture = null
	queue_redraw()

	if !url_to_load:
		print("there was no url to load from")
		return

	while true:
		if !is_inside_tree():
			return
		var count = get_tree().get_meta("__http_image_count")
		if immediate || count < MAX_COUNT:
			get_tree().set_meta("__http_image_count", count + 1)
			break
		else:
			await get_tree().process_frame

	_load(url_to_load)
	url_to_load = null

func _load(url_to_load):# Create an HTTP request node and connect its completion signal.
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var error = http_request.request(url_to_load)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):

	get_tree().set_meta("__http_image_count", get_tree().get_meta("__http_image_count") - 1)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")

	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
		return

	# Display the image in a TextureRect node.
	var w = image.get_width()
	var h = image.get_height()
	if w > h:
		var new_w = min(w, max_size)
		image.resize(new_w, (float(h) / w) * new_w)
	else:
		var new_h = min(h, max_size)
		image.resize((float(w) / h) * new_h, new_h)

	texture = ImageTexture.create_from_image(image)


