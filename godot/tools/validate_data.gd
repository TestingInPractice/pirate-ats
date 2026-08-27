extends SceneTree
## Валидация data/screens.json: у каждого задания должна быть цель.
## Запуск: godot --headless -s tools/validate_data.gd

func _init() -> void:
	var text := FileAccess.get_file_as_string("res://data/screens.json")
	var data = JSON.parse_string(text)
	if not (data is Dictionary) or (data as Dictionary).is_empty():
		push_error("JSON не читается")
		quit(1)
		return
	var errors: Array[String] = []
	var screens: Array = (data as Dictionary).get("screens", [])
	for s: Dictionary in screens:
		var sid := String(s.get("id", "?"))
		var items: Array = s.get("items", [])
		var contact_nums: Array = []
		for c: Dictionary in s.get("contacts", []):
			contact_nums.append(int(c.get("num", -1)))
		for task: Dictionary in s.get("tasks", []):
			var label := "%s / «%s»" % [sid, String(task.get("text", ""))]
			match String(task.get("type", "tap")):
				"dial":
					if not contact_nums.has(int(task.get("contact", -1))):
						errors.append(label + " — контакт не найден")
				"count":
					if _count_matching(items, task) < 1:
						errors.append(label + " — нет предметов для счёта")
				_:
					if _count_matching(items, task) == 0:
						errors.append(label + " — нет ни одного подходящего предмета")
	if errors.is_empty():
		print("OK: %d экранов, все задания имеют цель" % screens.size())
		quit(0)
	else:
		for e in errors:
			printerr("FAIL: " + e)
		quit(1)


func _matches(item: Dictionary, task: Dictionary) -> bool:
	var tid := String(task.get("target_id", ""))
	if not tid.is_empty():
		return String(item.get("id", "")) == tid
	var want: Array = task.get("target_tags", [])
	if want.is_empty():
		return false
	var have: Array = item.get("tags", [])
	for w: Variant in want:
		if have.has(w):
			return true
	return false


func _count_matching(items: Array, task: Dictionary) -> int:
	var n := 0
	for it: Dictionary in items:
		if _matches(it, task):
			n += 1
	return n
