extends SceneTree
## Изолированный пробник: один экран, один вызов раскладки, замер по времени.
## Запуск: godot --headless -s tools/probe_layout.gd

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data = JSON.parse_string(text)
	var screens: Array = data.get("screens", [])
	var packed: PackedScene = load("res://scenes/ScreenCard.tscn")

	var scr: Dictionary
	for s in screens:
		if s.get("id") == "05_counting_4":
			scr = s
			break
	print("instantiating card for screen 9...")
	var t0 := Time.get_ticks_msec()
	var card := packed.instantiate()
	card.setup(scr, data)
	root.add_child(card)
	await process_frame
	await process_frame
	print("after 2 frames: %d ms" % (Time.get_ticks_msec() - t0))
	print("buttons:", card._item_buttons.size())
	for i in card._item_buttons.size():
		var b: Button = card._item_buttons[i]["btn"]
		print("  ", i, " pos=", b.position, " size=", b.size)
	quit(0)
