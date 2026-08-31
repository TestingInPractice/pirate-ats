extends SceneTree
## Диагностика: дампим геометрию экранов 07_emotions(11) и 11_sport(18),
## находим пересекающиеся пары и печатаем их прямоугольники.

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data = JSON.parse_string(text)
	var screens: Array = data.get("screens", [])
	var packed: PackedScene = load("res://scenes/ScreenCard.tscn")

	for scr: Dictionary in screens:
		if scr.get("id", "") not in ["07_emotions", "11_sport"]:
			continue
		var card := packed.instantiate()
		card.setup(scr, data)
		root.add_child(card)
		await process_frame
		await process_frame

		var btns: Array = []
		for e in card._item_buttons:
			var b: Button = e["btn"]
			if b.size == Vector2.ZERO:
				continue
			btns.append(Rect2(b.position, b.size).grow(8.0))

		print("=== %s items=%d field_size=%s ===" % [scr.get("id", ""), btns.size(), card._play_field.size])
		for a in btns.size():
			for c in range(a + 1, btns.size()):
				if (btns[a] as Rect2).intersects(btns[c] as Rect2):
					print("OVERLAP %d-%d: A rect=%s B rect=%s" % [a, c, btns[a], btns[c]])
		# Дампим все позиции, чтобы посмотреть раскладку.
		for idx in btns.size():
			print("  btn %d rect=%s" % [idx, btns[idx]])
		card.queue_free()
		await process_frame

	quit(0)
