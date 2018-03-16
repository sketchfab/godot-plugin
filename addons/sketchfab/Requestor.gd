tool
extends Object

signal completed

class Result:
	var ok setget , _is_ok
	var code
	var data

	func _init(code, data = null):
		self.code = code
		self.data = data

	func _is_ok():
		return code >= 0

const DEFAULT_OPTIONS = {
	"method": HTTPClient.METHOD_GET,
	"encoding": "query",
	"token": null,
}

var hostname
var use_ssl

var http = HTTPClient.new()
var busy = false
var canceled = false
var terminated = false

func _init(hostname, use_ssl):
	self.hostname = hostname
	self.use_ssl = use_ssl

func cancel():
	if busy:
		if _is_debugging():
			print("CANCEL REQUESTED")
		canceled = true
	else:
		call_deferred("emit_signal", "completed", null)
	yield(self, "completed")

func term():
	if _is_debugging():
		print("TERMINATE REQUESTED")
	terminated = true
	http.close()

func request(path, payload = null, options = DEFAULT_OPTIONS):
	while busy && !terminated:
		yield(Engine.get_main_loop(), "idle_frame")
		if terminated:
			if _is_debugging():
				print("TERMINATE HONORED")
			return

	busy = true

	var status

	if canceled:
		if _is_debugging():
			print("CANCEL HONORED (SOFT)")
		canceled = false
		busy = false
		emit_signal("completed", null)
		return

	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		http.connect_to_host(hostname, -1, use_ssl, false)
		while true:
			yield(Engine.get_main_loop(), "idle_frame")
			if terminated:
				if _is_debugging():
					print("TERMINATE HONORED")
				return

			http.poll()
			status = http.get_status()
			if status in [
				HTTPClient.STATUS_CANT_CONNECT,
			    HTTPClient.STATUS_CANT_RESOLVE,
				HTTPClient.STATUS_SSL_HANDSHAKE_ERROR,
			]:
				busy = false
				emit_signal("completed", Result.new(-1))
				return

			if status == HTTPClient.STATUS_CONNECTED:
				break

	if canceled:
		if _is_debugging():
			print("CANCEL HONORED (SOFT)")
		canceled = false
		busy = false
		emit_signal("completed", null)
		return

	var uri = path
	var encoded_payload = ""
	var headers = []

	if payload:
		var encoding = _get_option(options, "encoding")
		if encoding == "query":
			uri += "?" + http.query_string_from_dict(payload)
		elif encoding == "json":
			headers.append("Content-Type: application/json")
			encoded_payload = to_json(payload)
		elif encoding == "form":
			headers.append("Content-Type: application/x-www-form-urlencoded")
			encoded_payload = http.query_string_from_dict(payload)

	var token = _get_option(options, "token")
	if token:
		headers.append("Authorization: Bearer %s" % token)

	if _is_debugging():
		print("QUERY")
		print("URI: %s" % uri)
		if headers.size():
			print("Headers:")
			print(headers)
		if encoded_payload:
			print("Payload:")
			print(encoded_payload)

	http.request(_get_option(options, "method"), uri, headers, encoded_payload)
	while true:
		yield(Engine.get_main_loop(), "idle_frame")
		if terminated:
			if _is_debugging():
				print("TERMINATE HONORED")
			return
		if canceled:
			if _is_debugging():
				print("CANCEL HONORED (HARD)")
			http.close()
			canceled = false
			busy = false
			emit_signal("completed", null)
			return

		http.poll()
		status = http.get_status()
		if status in [
			HTTPClient.STATUS_DISCONNECTED,
			HTTPClient.STATUS_CONNECTION_ERROR,
		]:
			busy = false
			emit_signal("completed", Result.new(-1))
			return

		if status in [
			HTTPClient.STATUS_CONNECTED,
			HTTPClient.STATUS_BODY,
		]:
			break

	if _is_debugging():
		print("RESPONSE")
		print("Code: %d" % http.get_response_code())
		print("HEADERS")
		print(http.get_response_headers())

	var response_body
	while status == HTTPClient.STATUS_BODY:
		response_body = response_body if response_body else ""
		response_body += http.read_response_body_chunk().get_string_from_utf8()

		yield(Engine.get_main_loop(), "idle_frame")
		if terminated:
			if _is_debugging():
				print("TERMINATE HONORED")
			return
		if canceled:
			if _is_debugging():
				print("CANCEL HONORED (HARD)")
			http.close()
			canceled = false
			busy = false
			emit_signal("completed", null)
			return

		http.poll()
		status = http.get_status()
		if status in [
			HTTPClient.STATUS_DISCONNECTED,
		    HTTPClient.STATUS_CONNECTION_ERROR
		]:
			busy = false
			emit_signal("completed", Result.new(-1))
			return

	busy = false

	if response_body:
		if _is_debugging():
			print("Body: %s..." % response_body.left(70))

	var data = parse_json(response_body) if response_body else null
	emit_signal("completed", Result.new(http.get_response_code(), data))

func _is_debugging():
	return true

func _get_option(options, key):
	return options[key] if options.has(key) else DEFAULT_OPTIONS[key]
