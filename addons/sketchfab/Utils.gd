tool

static func create_texture_from_file(path):
	var file = File.new()
	file.open(path, File.READ)
	var buffer = file.get_buffer(file.get_len())
	file.close()
	var img = Image.new()
	img.load_png_from_buffer(buffer)
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	return texture

static func get_best_size_url(images, target_size, SafeData):
	var target_length_sq = Vector2(target_size, target_size).length_squared()
	var closest_diff = 10e20
	var closes_url
	for img in images:
		var length_sq = Vector2(SafeData.integer(img, "width"), SafeData.integer(img, "height")).length_squared()
		var diff = abs(target_length_sq - length_sq)
		if diff < closest_diff:
			closest_diff = diff
			closes_url = SafeData.string(img, "url")
	return closes_url
