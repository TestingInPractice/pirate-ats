extends SceneTree
## Смоук-тест: открываем несколько экранов и проверяем,
## что рассыпанная раскладка предметов построилась.
## Запуск: godot --headless -s tools/smoke_screens.gd

func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data_raw = JSON.parse_string(text)
	if not (data_raw is Dictionary):
		push_error("SMOKE FAIL: screens.json не распарсился")
		quit(1)
		return
	var data: Dictionary = data_raw
	var screens: Array = data.get("screens", [])
	var packed: PackedScene = load("res://scenes/ScreenCard.tscn")

	for idx: int in range(screens.size()):
		var scr: Dictionary = screens[idx]
		var card := packed.instantiate()
		card.setup(scr, data)
		root.add_child(card)
		await process_frame
		await process_frame
		var n: int = card._item_buttons.size()
		var expected: int = (scr.get("items", []) as Array).size()
		if n != expected:
			push_error("SMOKE FAIL [%s]: кнопок %d, ожидалось %d" % [scr.get("id"), n, expected])
			quit(1)
			return
		if n > 0:
			var btn: Button = card._item_buttons[0]["btn"]
			if btn.size == Vector2.ZERO:
				push_error("SMOKE FAIL [%s]: кнопка не размещена по слоту" % scr.get("id"))
				quit(1)
				return
		card.queue_free()
		await process_frame

	print("SMOKE OK: все %d экранов, раскладка работает" % screens.size())
	quit(0)
