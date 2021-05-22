extends Control

var receiver : Node = null
var info : Dictionary = {}

func set_connection_info(info : Dictionary) -> void:
	self.info = info
	if info.has("claimid"): 
		$VBoxContainer/MarginContainerClientId/ClaimId.text = info["claimid"]

func verify_connection(receiver : Node) -> void:
	self.receiver = receiver
	var publisher_id = $VBoxContainer/MarginContainerClientId/ClaimId.text
	print("verify connection")
	$HTTPRequest.connect("request_completed", self, "_on_odysee_verify", [], CONNECT_DEFERRED)
	var err = $HTTPRequest.request("https://chainquery.lbry.com/api/sql?query=SELECT%20*%20FROM%20claim%20WHERE%20publisher_id=%22" +  publisher_id + "%22%20AND%20bid_state%3C%3E%22Spent%22%20AND%20claim_type=1%20AND%20source_hash%20IS%20NULL%20ORDER%20BY%20id%20DESC%20LIMIT%201")
	assert(err==OK)

func _on_odysee_verify(result, response_code, headers, body) -> void:
	$HTTPRequest.disconnect("request_completed", self, "_on_odysee_verify")
	var userResponse : JSONParseResult = JSON.parse(body.get_string_from_utf8())

	if response_code == 200:
		var response = {
			"error": false,
			"name": $VBoxContainer/MarginContainerClientId/ClaimId.text,
			"icon": load("res://widgets/odyseechat.png"),
			"valid": true,
			"type": "odysee",
			"claimid": $VBoxContainer/MarginContainerClientId/ClaimId.text
		}
		
		if info:
			response["uuid"] = info["uuid"]

		receiver.connection_verified(response)
	else:
		var response : Dictionary
		
		if userResponse:
			response = {
				"error": true,
				"message": userResponse.result["message"],
				"valid": false
			}
		else:
			response = {
				"error": true,
				"message": "Temporary connection problem. Please verify your connection.",
				"valid": true
			}
		
		if info:
			response["uuid"] = info["uuid"]
		
		
		receiver.connection_verified(response)

func _on_RichTextLabel_meta_clicked(meta):
	OS.shell_open(meta)
