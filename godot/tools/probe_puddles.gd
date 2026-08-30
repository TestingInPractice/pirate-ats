extends SceneTree

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data_raw = JSON.parse_string(text)
	var data: Dictionary = data_raw
	var screens: Array = data.get("screens", [])
	var idx := 0
	if "--colors" in OS.get_cmdline_user_args():
		idx = 1
	var scr: Dictionary = screens[idx]
	print("probe screen: ", scr.get("id"), " num=", scr.get("num"))
	var packed: PackedScene = load("res://scenes/ScreenCard.tscn")
	var card := packed.instantiate()
	card.setup(scr, data)
	root.add_child(card)
	await process_frame
	await process_frame
	print("probe buttons: ", card._item_buttons.size())
	var btn: Button = card._item_buttons[0]["btn"]
	print("probe btn size: ", btn.size, " pos ", btn.position, " children ", btn.get_child_count())
	card.queue_free()
	await process_frame
	print("PROBE DONE")
	quit(0)
