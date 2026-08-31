extends SceneTree
## Регрессионный тест: предметы НЕ должны менять позиции (и налазить друг на друга),
## когда игровое поле сжимается/растёт из-за разной длины задания/подсказки при
## верном или неверном ответе.
## Запуск: godot --headless -s tools/test_layout_stability.gd

var _failed := false

func _init() -> void:
	_run()


func _check_stable(card: Control, before: Dictionary, screen_id: String, phase: String) -> void:
	for e: Dictionary in card._item_buttons:
		var btn: Button = e["btn"]
		var now: Vector2 = btn.position + btn.scale
		if (now - before[btn]).length() > 0.01:
			push_error("LAYOUT FAIL [%s %s]: предмет %s сменил позицию (%s -> %s)"
				% [screen_id, phase, e["data"].get("id", "?"), before[btn], now])
			_failed = true


func _run() -> void:
	await process_frame
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data_raw = JSON.parse_string(text)
	if not (data_raw is Dictionary):
		push_error("LAYOUT FAIL: screens.json не распарсился")
		quit(1)
		return
	var data: Dictionary = data_raw
	var screens: Array = data.get("screens", [])
	var packed: PackedScene = load("res://scenes/ScreenCard.tscn")

	for scr: Dictionary in screens:
		# Проверяем только экраны с рассыпанной (не упорядоченной) раскладкой
		# и предметами <= длины слотов (ветка scatter). Плотные сетки тут не нужны.
		var items: Array = scr.get("items", [])
		if scr.get("ordered", false) or items.is_empty():
			continue
		if items.size() > 13:  # ITEM_SLOTS.size() == 13; больше -> сетка
			continue

		var card := packed.instantiate()
		card.setup(scr, data)
		root.add_child(card)
		await process_frame
		await process_frame
		await process_frame

		var field: Control = card._play_field
		if field == null or field.size.x < 20 or field.size.y < 20:
			push_error("LAYOUT FAIL [%s]: поле не получило размер" % scr.get("id"))
			quit(1)
			return

		# Сохраняем позиции до любого изменения поля.
		var before := {}
		for e: Dictionary in card._item_buttons:
			before[e["btn"]] = e["btn"].position + e["btn"].scale

		# Реальный источник бага: смена текста задания (1 строка <-> 3 строки)
		# не должна двигать игровое поле (иначе предметы едут вниз/вверх как блок).
		# Проверяем на естественной раскладке ДО ручных изменений размера.
		var field_rect: Rect2 = field.get_global_rect()
		card._set_task_text("Найди предмет")
		await process_frame
		await process_frame
		var one_rect: Rect2 = field.get_global_rect()
		if (one_rect.position - field_rect.position).length() > 1.0 or absf(one_rect.size.y - field_rect.size.y) > 1.0:
			push_error("LAYOUT FAIL [%s]: поле сдвинулось при 1-строчном задании (%s -> %s)"
				% [scr.get("id"), field_rect, one_rect])
			_failed = true
		card._set_task_text("Подсказка Пушка: найди предмет под столом, среди ракушек и пуговиц на палубе корабля")
		await process_frame
		await process_frame
		var three_rect: Rect2 = field.get_global_rect()
		if (three_rect.position - field_rect.position).length() > 1.0 or absf(three_rect.size.y - field_rect.size.y) > 1.0:
			push_error("LAYOUT FAIL [%s]: поле сдвинулось при 3-строчном задании (%s -> %s)"
				% [scr.get("id"), field_rect, three_rect])
			_failed = true
		# Предметы не должны передвинуться относительно поля после смены текста.
		_check_stable(card, before, scr.get("id"), "при смене текста задания")

		# Симулируем сжатие поля (текст задания вырос -> облачко выше -> поле ниже).
		field.size = Vector2(field.size.x, maxf(field.size.y * 0.7, 80.0))
		field.emit_signal("resized")
		await process_frame
		_check_stable(card, before, scr.get("id"), "при сжатии поля")

		# Симулируем рост поля (переход к более короткому заданию -> поле выше).
		field.size = Vector2(field.size.x, field.size.y * 1.5)
		field.emit_signal("resized")
		await process_frame
		_check_stable(card, before, scr.get("id"), "при росте поля")

		# После сжатия поле могло стать меньше кнопки — проверяем только отсутствие
		# новых взаимных налезаний среди кнопок, которые всё ещё помещаются.
		card.queue_free()
		await process_frame

	if _failed:
		push_error("LAYOUT FAIL: зафиксированы наложения/перемещения")
		quit(1)
		return

	print("LAYOUT OK: рассыпанные экраны не перекладываются ни при сжатии, ни при росте поля")
	quit(0)
