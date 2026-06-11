class_name AuthService
extends RefCounted

var bm: Node

func _init(backend_manager: Node) -> void:
	bm = backend_manager

func signup_user(user_id: String, password: String) -> void:
	Global.show_loading("新規登録中...")
	var safe_email = user_id.to_utf8_buffer().hex_encode() + "@chikenrace.com"
	var url = bm._get_supabase_url() + "/auth/v1/signup"
	var body = {
		"email": safe_email,
		"password": password
	}

	bm._send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), false, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201):
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("access_token"):
					bm.auth_token = data["access_token"]
					if data.has("user") and data["user"] is Dictionary:
						bm.logged_in_uuid = data["user"].get("id", "")
					bm.auth_completed.emit(true, "")
					return
			bm.auth_completed.emit(true, "") 
		else:
			var err_msg = "接続エラー"
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.has("msg"): err_msg = data["msg"]
					elif data.has("message"): err_msg = data["message"]
					elif data.has("error_description"): err_msg = data["error_description"]
					elif data.has("error"): err_msg = data["error"]

			if err_msg == "接続エラー" and response_code != 0:
				err_msg += " (HTTP " + str(response_code) + ")"
			bm.auth_completed.emit(false, err_msg)
	)

func login_user(user_id: String, password: String) -> void:
	Global.show_loading("ログイン中...")
	var safe_email = user_id.to_utf8_buffer().hex_encode() + "@chikenrace.com"
	var url = bm._get_supabase_url() + "/auth/v1/token?grant_type=password"
	var body = {
		"email": safe_email,
		"password": password
	}

	bm._send_request(url, HTTPClient.METHOD_POST, JSON.stringify(body), false, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("access_token"):
					bm.auth_token = data["access_token"]
					if data.has("user") and data["user"] is Dictionary:
						bm.logged_in_uuid = data["user"].get("id", "")
					bm.auth_completed.emit(true, "")
					return
			bm.auth_completed.emit(false, "データ解析エラー")
		else:
			var err_msg = "IDまたはパスワードが違います"
			var json = JSON.new()
			if json.parse(body_data.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.has("error_description"): err_msg = data["error_description"]
					elif data.has("msg"): err_msg = data["msg"]
					elif data.has("message"): err_msg = data["message"]

			if err_msg == "IDまたはパスワードが違います" and response_code != 0:
				if response_code >= 500:
					err_msg = "サーバーエラー (HTTP " + str(response_code) + ")"
			bm.auth_completed.emit(false, err_msg)
	)

func verify_token(token: String, uuid: String) -> void:
	if token == "" or uuid == "":
		bm.auth_completed.emit(false, "トークンが無効です")
		return

	Global.show_loading("セッション復旧中...")
	bm.auth_token = token
	bm.logged_in_uuid = uuid
	var url = bm._get_supabase_url() + "/auth/v1/user"

	bm._send_request(url, HTTPClient.METHOD_GET, "", true, func(result, response_code, headers, body_data):
		Global.hide_loading()
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			bm.auth_completed.emit(true, "")
		else:
			bm.auth_token = ""
			bm.logged_in_uuid = ""
			bm.auth_completed.emit(false, "セッション期限切れ")
	)
