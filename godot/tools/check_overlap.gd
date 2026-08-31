extends SceneTree
## Проверка пересечений на реальном разрешении игры (1280x720).
## Карточку кладём в контейнер фиксированного размера, чтобы игровое поле
## получило те же размеры, что и в продакшене (а не раздутое окно headless).

const GAME := Vector2(1280.0, 720.0)

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data = JSON.parse_string(text)
	var screens: Array = data.get("screens", [])
	var packed: PackedScene = load("res://scenes/ScreenCard.tscn")

	var host := Control.new()
	host.size = GAME
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)

	for idx: int in range(screens.size()):
		var scr: Dictionary = screens[idx]
		if scr.get("ordered", false):
			continue
		var card := packed.instantiate()
		card.setup(scr, data)
		host.add_child(card)
		# Ждём, пока игровое поле устаканится на реальном размере и раскладка перестроится.
		await process_frame
		await process_frame

		var btns: Array = []
		for e in card._item_buttons:
			var b: Button = e["btn"]
			if b.size == Vector2.ZERO:
				continue
			btns.append(Rect2(b.position, b.size).grow(8.0))

		var overlaps := 0
		for a in btns.size():
			for c in range(a + 1, btns.size()):
				if (btns[a] as Rect2).intersects(btns[c] as Rect2):
					overlaps += 1

		print("screen %2d id=%-16s items=%-3d field=%s overlapping_pairs=%d" % [
			scr.get("num", 0), scr.get("id", ""), btns.size(), card._play_field.size, overlaps
		])
		card.queue_free()
		await process_frame

	quit(0)
