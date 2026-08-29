extends Control
## Экран-карточка темы: заголовок сверху, текст задания ниже,
## предметы для тапов в центре, обратная связь облачком.

signal closed

const CARD := preload("res://scenes/ScreenCard.tscn")
const SND_SUCCESS := preload("res://assets/sounds/success.wav")
const SND_FAIL := preload("res://assets/sounds/fail.wav")

# Слоты «рассыпанной» раскладки предметов (доли ширины/высоты игрового поля).
const ITEM_SLOTS: Array[Vector2] = [
	Vector2(0.20, 0.07), Vector2(0.55, 0.05), Vector2(0.86, 0.09),
	Vector2(0.35, 0.25), Vector2(0.70, 0.23),
	Vector2(0.14, 0.41), Vector2(0.50, 0.44), Vector2(0.82, 0.40),
	Vector2(0.30, 0.59), Vector2(0.65, 0.62),
	Vector2(0.16, 0.77), Vector2(0.50, 0.80), Vector2(0.84, 0.76),
	Vector2(0.93, 0.57),
]

var _screen: Dictionary = {}
var _data: Dictionary = {}

var _tasks: Array = []
var _t_index: int = -1
var _misses: int = 0
var _found: int = 0
var _total: int = 0
var _stars: int = 0
var _busy := false

var _item_buttons: Array = []  # [{ "data": Dictionary, "btn": Button }]
var _keypad_buttons: Array = []
var _play_field: Control

# Раскладка предметов строится ровно один раз. Повторный вызов _layout_items()
# снова раскидывает предметы случайно, поэтому при сжатии поля (длинная подсказка
# или реплика после неверного ответа) их нельзя перекладывать — иначе они
# «прыгают» и налезают друг на друга.
var _laid_out := false
var _laid_out_area := Vector2.ZERO

var _bg: ColorRect
var _title_label: Label
var _stars_label: Label
var _audio: AudioStreamPlayer
var _task_cloud: PanelContainer
var _task_label: Label
var _center_box: VBoxContainer

# Зарезервированная высота облачка задания (под ~3 строки текста 28px), чтобы
# смена задания (1 строка <-> 3 строки) не толкала игровое поле вниз/вверх.
var _card_cloud_reserve := 168


func setup(screen: Dictionary, data: Dictionary) -> void:
	_screen = screen
	_data = data


func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	add_child(_audio)
	_tasks = (_screen.get("tasks", []) as Array).duplicate()
	# Для упорядоченных экранов (змейка с номерами) вопросы идут строго по порядку
	# появления предметов — перемешивать нельзя.
	if not _screen.get("ordered", false):
		_tasks.shuffle()
	_build_ui()
	_next_task()


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(String(_screen.get("bg_color", "#8ecae6")))
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# --- Заголовок
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var back := Button.new()
	back.text = " ← В меню "
	back.custom_minimum_size = Vector2(230, 76)
	back.add_theme_font_size_override("font_size", 28)
	back.pressed.connect(func(): closed.emit())
	header.add_child(back)

	_title_label = Label.new()
	_title_label.text = "%d. %s" % [_screen.get("num", 0), _screen.get("title", "")]
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 34)
	_title_label.add_theme_color_override("font_color", Color("#1d3557"))
	header.add_child(_title_label)

	_stars_label = Label.new()
	_stars_label.custom_minimum_size = Vector2(170, 0)
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stars_label.add_theme_font_size_override("font_size", 30)
	_stars_label.add_theme_color_override("font_color", Color("#e09f3e"))
	_stars_label.text = ""
	header.add_child(_stars_label)

	# --- Облачко с заданием
	var cloud_wrap := CenterContainer.new()
	vbox.add_child(cloud_wrap)
	_task_cloud = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Color("#f4a261")
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_task_cloud.add_theme_stylebox_override("panel", sb)
	_card_cloud_reserve = 168
	_task_cloud.custom_minimum_size = Vector2(0, _card_cloud_reserve)
	cloud_wrap.add_child(_task_cloud)
	_task_label = Label.new()
	_task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_task_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_task_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_label.add_theme_font_size_override("font_size", 28)
	_task_label.add_theme_color_override("font_color", Color("#333333"))
	_task_cloud.add_child(_task_label)

	# --- Центр: предметы / рация
	_center_box = VBoxContainer.new()
	_center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_center_box)

	if String(_screen.get("id", "")) == "06_radio":
		_build_radio_ui()
	else:
		_build_items_ui()

	# --- Нижняя панель
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	vbox.add_child(bottom)

	var repeat_btn := Button.new()
	repeat_btn.text = " 🔁 Повторить задание "
	repeat_btn.custom_minimum_size = Vector2(320, 56)
	repeat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	repeat_btn.add_theme_font_size_override("font_size", 24)
	repeat_btn.pressed.connect(_repeat_task)
	bottom.add_child(repeat_btn)


func _build_items_ui() -> void:
	# Игровое поле: кнопки-предметы рассыпаны не подряд, а по слотам
	# с наклоном и разным размером — как вещи на пиратском столе.
	_play_field = Control.new()
	_play_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_field.clip_contents = false
	_center_box.add_child(_play_field)

	for item: Dictionary in _screen.get("items", []):
		var btn := _make_item_button(item)
		_play_field.add_child(btn)
		_item_buttons.append({"data": item, "btn": btn})

	_play_field.resized.connect(_on_play_field_resized)
	_layout_once.call_deferred()


func _layout_items() -> void:
	if _play_field == null or _play_field.size == Vector2.ZERO:
		return
	var area := _play_field.size
	var n := _item_buttons.size()
	if n == 0:
		return

	# Упорядоченные экраны (04_day): змейка сверху вниз по рядам, с номерами.
	if _screen.get("ordered", false):
		_layout_snake(n)
		return

	# Очень плотные экраны (предметов больше, чем слотов): «пиратский стол»
	# не вмещает их без наложений, поэтому раскладываем по аккуратной сетке.
	# Счётным экранам (как 05_counting_4: крабы/кораллы) сетка даже удобнее.
	if n > ITEM_SLOTS.size():
		_layout_grid(n)
		return

	var scales: Array[float] = [1.0, 0.92, 1.06]
	var used := {}
	# Зазор между кнопками, чтобы предметы не слипались.
	var gap := 8.0
	# Прямоугольники уже размещённых кнопок (с зазором) для проверки пересечений.
	var placed: Array[Rect2] = []

	# Целевая площадь: сумма кнопок >= 50% площади игрового поля.
	var per_side := sqrt(maxf(0.5 * area.x * area.y / float(n), 64.0))

	for i in n:
		var e: Dictionary = _item_buttons[i]
		var btn: Button = e["btn"]

		# Раскидываем предметы равномерно по всему полю, без повторов слотов.
		var si := int(floor(i * ITEM_SLOTS.size() / float(n)))
		var reused := false
		if used.size() >= ITEM_SLOTS.size():
			# Слотов меньше, чем предметов: переиспользуем слоты, но уже с учётом
			# проверки пересечений повторный предмет будет сдвинут в свободное место.
			si = i % ITEM_SLOTS.size()
			reused = true
		else:
			var guard := 0
			while used.has(si) and guard <= ITEM_SLOTS.size():
				si = (si + 1) % ITEM_SLOTS.size()
				guard += 1
		used[si] = true
		var slot: Vector2 = ITEM_SLOTS[si]

		var s: float = scales[i % scales.size()]
		var side := per_side * s
		# Зазор с запасом на поворот кнопки (±6°): повёрнутый квадрат выступает
		# за свой осевой прямоугольник, поэтому сверяем пересечения по увеличенной
		# рамке, чтобы предметы не налезали друг на друга.
		var margin := gap + side * 0.12
		var btn_size := Vector2(side, side)
		btn.custom_minimum_size = Vector2.ZERO
		btn.size = btn_size
		btn.pivot_offset = btn_size / 2.0
		btn.scale = Vector2.ONE
		btn.set_meta("base_scale", Vector2.ONE)
		btn.rotation_degrees = randf_range(-6.0, 6.0)

		# Повторно занятый слот раздвигаем сильнее, чтобы базовая точка не совпадала.
		var spread := 2.2 if reused else 1.0
		var center := Vector2(
			slot.x * area.x + randf_range(-10.0, 10.0) * spread,
			slot.y * area.y + randf_range(-14.0, 14.0) * spread
		)

		# Ищем позицию без пересечений с уже размещёнными кнопками. От базовой
		# точки уходим по спирали Ферма (равномерное заполнение) всё дальше по
		# полю, пока не найдём свободное место или не кончатся попытки.
		var attempts := 60
		var search_radius := maxf(side * 2.0, area.x * 0.5)
		var min_overlaps := 0x7fffffff
		var best := (center - btn_size / 2.0).clamp(
			Vector2(4.0, 4.0),
			Vector2(maxf(area.x - btn_size.x - 4.0, 4.0), maxf(area.y - btn_size.y - 4.0, 4.0))
		)
		var free_found := false
		for a in attempts:
			var ang := a * (TAU * 0.61803398875)
			var rad := search_radius * (float(a + 1) / float(attempts))
			var cand := center + Vector2(cos(ang), sin(ang)) * rad
			var pos := cand - btn_size / 2.0
			pos.x = clampf(pos.x, 4.0, maxf(area.x - btn_size.x - 4.0, 4.0))
			pos.y = clampf(pos.y, 4.0, maxf(area.y - btn_size.y - 4.0, 4.0))
			var rect := Rect2(pos, btn_size).grow(margin)
			var overlaps := 0
			for pr: Rect2 in placed:
				if pr.intersects(rect):
					overlaps += 1
			if overlaps == 0:
				best = pos
				free_found = true
				break
			if overlaps < min_overlaps:
				min_overlaps = overlaps
				best = pos
		# Если спираль не нашла свободного места, проходимся по всему полю грубой
		# сеткой и берём первую по-настоящему свободную ячейку. Для неплотных
		# экранов (слотов хватает) такая ячейка гарантированно найдётся — так
		# предметы никогда не ложатся друг на друга.
		if not free_found:
			var step := maxf(side * 0.08, 12.0)
			var cy := 4.0
			while cy < area.y - btn_size.y:
				var cx := 4.0
				while cx < area.x - btn_size.x:
					var rect := Rect2(Vector2(cx, cy), btn_size).grow(margin)
					var overlaps := 0
					for pr: Rect2 in placed:
						if pr.intersects(rect):
							overlaps += 1
							break
					if overlaps == 0:
						best = Vector2(cx, cy)
						free_found = true
						break
					cx += step
				if free_found:
					break
				cy += step
		btn.position = best
		placed.append(Rect2(best, btn_size).grow(margin))


func _on_play_field_resized() -> void:
	# Раскладка предметов строится ровно один раз — при первом реальном размере
	# поля. Дальше поле может «дышать» (текст задания разной длины сжимает/растягивает
	# центр между задачами, после верного/неверного ответа), но перераскладывать
	# предметы нельзя: они начнут «прыгать» по случайным позициям и налазить.
	_layout_once()


func _layout_once() -> void:
	if _laid_out:
		return
	if _play_field == null or _play_field.size.x < 20 or _play_field.size.y < 20:
		return
	_laid_out = true
	_laid_out_area = _play_field.size
	_layout_items()


func _layout_snake(n: int) -> void:
	# Змейка: 3 колонки, ряды сверху вниз; чётный ряд слева направо,
	# нечётный — справа налево. Каждый предмет занимает слот по порядку.
	var area := _play_field.size
	var cols := 3
	var rows := ceili(float(n) / float(cols))
	# Кнопка занимает примерно 1/cols ширины и 1/rows высоты.
	var side := minf(area.x / float(cols) * 0.86, area.y / float(rows) * 0.86)
	side = maxf(side, 64.0)
	for i in n:
		var e: Dictionary = _item_buttons[i]
		var btn: Button = e["btn"]
		var col := i % cols
		var row := int(floor(i / float(cols)))
		# Змейка: нечётные ряды разворачиваем справа налево.
		if row % 2 == 1:
			col = cols - 1 - col
		var btn_size := Vector2(side, side)
		btn.custom_minimum_size = Vector2.ZERO
		btn.size = btn_size
		btn.pivot_offset = btn_size / 2.0
		btn.scale = Vector2.ONE
		btn.set_meta("base_scale", Vector2.ONE)
		btn.rotation_degrees = 0.0
		var center := Vector2(
			(float(col) + 0.5) * (area.x / float(cols)),
			(float(row) + 0.5) * (area.y / float(rows))
		)
		var pos := center - btn_size / 2.0
		pos.x = clampf(pos.x, 4.0, maxf(area.x - btn_size.x - 4.0, 4.0))
		pos.y = clampf(pos.y, 4.0, maxf(area.y - btn_size.y - 4.0, 4.0))
		btn.position = pos


func _layout_grid(n: int) -> void:
	# Аккуратная сетка для плотных экранов: предметы не накладываются друг на друга.
	# Число столбцов подбирается под ландшафт поля, ряды заполняются сверху вниз.
	var area := _play_field.size
	var cols := maxi(2, int(round(sqrt(float(n) * area.x / maxf(area.y, 1.0)))))
	cols = mini(cols, n)
	var rows := maxi(1, ceili(float(n) / float(cols)))
	var side := minf(area.x / float(cols) * 0.9, area.y / float(rows) * 0.9)
	side = maxf(side, 64.0)
	for i in n:
		var e: Dictionary = _item_buttons[i]
		var btn: Button = e["btn"]
		var col := i % cols
		var row := int(floor(i / float(cols)))
		var btn_size := Vector2(side, side)
		btn.custom_minimum_size = Vector2.ZERO
		btn.size = btn_size
		btn.pivot_offset = btn_size / 2.0
		btn.scale = Vector2.ONE
		btn.set_meta("base_scale", Vector2.ONE)
		btn.rotation_degrees = randf_range(-4.0, 4.0)
		var center := Vector2(
			(float(col) + 0.5) * (area.x / float(cols)),
			(float(row) + 0.5) * (area.y / float(rows))
		)
		var pos := center - btn_size / 2.0
		btn.position = pos


func _make_item_button(item: Dictionary) -> Button:
	var item_id: String = item.get("id", "")
	var screen_id: String = _screen.get("id", "")
	var img_path := "res://assets/art/%s/%s.png" % [screen_id, item_id]
	var has_art := ResourceLoader.exists(img_path)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(340, 360)
	btn.add_theme_font_size_override("font_size", 22)

	var base := Color(String(item.get("color", "#cccccc")))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

	if has_art:
		# Контейнер картинки занимает всю кнопку (кнопка фиксированного размера)
		btn.clip_contents = true

		# Картинка предмета — вся кнопка, пропорции сохранены
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(img_path) as Texture2D
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)

		# Лапка 8 мм в диаметре, случайная позиция в пределах кнопки (не по центру).
		var paw_path := "res://assets/art/paw_outline.png"
		if ResourceLoader.exists(paw_path):
			var paw := TextureRect.new()
			paw.texture = load(paw_path) as Texture2D
			paw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			paw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var paw_d := 122.0
			# Смещение от центра по кругу на 20% радиуса кнопки — направление случайное.
			var ang := randf() * TAU
			var off := 0.2
			paw.anchor_left = 0.5 + cos(ang) * off
			paw.anchor_right = paw.anchor_left
			paw.anchor_top = 0.5 + sin(ang) * off
			paw.anchor_bottom = paw.anchor_top
			paw.position = Vector2(-paw_d / 2.0, -paw_d / 2.0)
			paw.size = Vector2(paw_d, paw_d)
			paw.modulate = Color(0.2, 0.2, 0.2, 0.45)
			paw.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(paw)

		# Подпись снизу-по центру
		var label := Label.new()
		label.text = item.get("label", "?")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_left = 0.1
		label.anchor_right = 0.9
		label.anchor_top = 1.0
		label.anchor_bottom = 1.0
		label.offset_top = -34
		label.offset_bottom = -6
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#1d3557"))
		label.add_theme_color_override("font_outline_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", 6)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(label)

		# Для упорядоченных экранов (04_day) — номер занятия сверху-слева.
		if _screen.get("ordered", false):
			var idx := 0
			for j in _screen.get("items", []):
				if (j as Dictionary).get("id", "") == item_id:
					break
				idx += 1
			var num := Label.new()
			num.text = str(idx + 1)
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			num.anchor_left = 0.0
			num.anchor_right = 0.0
			num.anchor_top = 0.0
			num.anchor_bottom = 0.0
			num.offset_left = 6
			num.offset_top = 6
			num.size = Vector2(70, 70)
			num.add_theme_font_size_override("font_size", 40)
			num.add_theme_color_override("font_color", Color("#1d3557"))
			num.add_theme_color_override("font_outline_color", Color.WHITE)
			num.add_theme_constant_override("outline_size", 8)
			num.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(num)
	else:
		# Фолбэк — текст как раньше
		btn.text = item.get("label", "?")
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_stylebox_override("normal", sb)
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = base
		sb2.set_corner_radius_all(14)
		sb2.set_border_width_all(3)
		sb2.border_color = base.darkened(0.35)
		btn.add_theme_stylebox_override("normal", sb2)
		var sb_hover := sb2.duplicate() as StyleBoxFlat
		sb_hover.bg_color = base.lightened(0.12)
		btn.add_theme_stylebox_override("hover", sb_hover)
		var sb_pressed := sb2.duplicate() as StyleBoxFlat
		sb_pressed.bg_color = base.darkened(0.25)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		if base.get_luminance() < 0.55:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
			btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		else:
			btn.add_theme_color_override("font_color", Color("#2b2d42"))

	btn.pressed.connect(_on_item_pressed.bind(item, btn))
	return btn


func _build_radio_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_box.add_child(vbox)

	# Список контактов
	var contacts_panel := PanelContainer.new()
	contacts_panel.size_flags_horizontal = Control.SIZE_FILL
	var cp_sb := StyleBoxFlat.new()
	cp_sb.bg_color = Color(1, 1, 1, 0.75)
	cp_sb.set_corner_radius_all(14)
	cp_sb.content_margin_left = 20
	cp_sb.content_margin_right = 20
	cp_sb.content_margin_top = 12
	cp_sb.content_margin_bottom = 12
	contacts_panel.add_theme_stylebox_override("panel", cp_sb)
	vbox.add_child(contacts_panel)

	var contacts_inner := VBoxContainer.new()
	contacts_inner.add_theme_constant_override("separation", 6)
	contacts_panel.add_child(contacts_inner)

	var cl_head := Label.new()
	cl_head.text = "Кого позовём?"
	cl_head.add_theme_font_size_override("font_size", 28)
	contacts_inner.add_child(cl_head)

	var grid_contacts := GridContainer.new()
	grid_contacts.columns = 2
	grid_contacts.add_theme_constant_override("h_separation", 28)
	grid_contacts.add_theme_constant_override("v_separation", 4)
	contacts_inner.add_child(grid_contacts)

	for c: Dictionary in _screen.get("contacts", []):
		var row := Label.new()
		row.text = "%d — %s" % [c.get("num", 0), c.get("label", "")]
		row.add_theme_font_size_override("font_size", 27)
		grid_contacts.add_child(row)

	# Цифровая клавиатура по центру
	var keypad_wrap := CenterContainer.new()
	keypad_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(keypad_wrap)

	var keypad := GridContainer.new()
	keypad.columns = 3
	keypad.add_theme_constant_override("h_separation", 14)
	keypad.add_theme_constant_override("v_separation", 14)
	keypad_wrap.add_child(keypad)

	# Клавиши 1-9 с аватаром персонажа внутри (для нечитающих детей).
	for n in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		var kb := Button.new()
		kb.clip_contents = true
		kb.custom_minimum_size = Vector2(230, 170)
		# Аватар персонажа-контакта внутри клавиши
		var contact_path := "res://assets/art/misc/contact_%d.png" % n
		if ResourceLoader.exists(contact_path):
			var av := TextureRect.new()
			av.texture = load(contact_path) as Texture2D
			av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			av.set_anchors_preset(Control.PRESET_FULL_RECT)
			av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			kb.add_child(av)
		# Цифра-бейдж сверху-слева
		var num := Label.new()
		num.text = str(n)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.anchor_left = 0.0
		num.anchor_right = 0.0
		num.anchor_top = 0.0
		num.anchor_bottom = 0.0
		num.offset_left = 6
		num.offset_top = 6
		num.size = Vector2(56, 56)
		num.add_theme_font_size_override("font_size", 34)
		num.add_theme_color_override("font_color", Color("#1d3557"))
		num.add_theme_color_override("font_outline_color", Color.WHITE)
		num.add_theme_constant_override("outline_size", 7)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kb.add_child(num)
		kb.pressed.connect(_on_digit_pressed.bind(n))
		keypad.add_child(kb)
		_keypad_buttons.append(kb)


# ---------------------------------------------------------------- Движок

func _next_task() -> void:
	_t_index += 1
	if _t_index >= _tasks.size():
		_show_reward()
		return
	_misses = 0
	_found = 0
	_busy = false

	var task: Dictionary = _tasks[_t_index]
	_set_task_text(String(task.get("text", "")))
	_update_progress()
	if String(task.get("type", "tap")) == "count":
		var tag := _first_tag(task)
		_total = 0
		for e: Dictionary in _item_buttons:
			if _has_tag(e["data"], tag):
				e["btn"].disabled = false
				_total += 1
			else:
				e["btn"].disabled = false


func _current_task() -> Dictionary:
	return _tasks[_t_index] if _t_index >= 0 and _t_index < _tasks.size() else {}


func _set_task_text(text: String) -> void:
	_task_label.text = text
	_pulse_node(_task_cloud, 1.08)


func _repeat_task() -> void:
	if not _current_task().is_empty():
		_set_task_text(String(_current_task().get("text", "")))


func _update_progress() -> void:
	if _stars > 0:
		_stars_label.text = "★ ".repeat(mini(_stars, 10)).strip_edges()


func _first_tag(task: Dictionary) -> String:
	var tags: Array = task.get("target_tags", [])
	return String(tags[0]) if tags.size() > 0 else ""


func _matches(item: Dictionary, task: Dictionary) -> bool:
	if task.has("target_id") and not String(task["target_id"]).is_empty():
		return String(item.get("id", "")) == String(task["target_id"])
	var want: Array = task.get("target_tags", [])
	if not want.is_empty():
		var have: Array = item.get("tags", [])
		for w: Variant in want:
			if have.has(w):
				return true
	return false


func _has_tag(item: Dictionary, tag: String) -> bool:
	if tag.is_empty():
		return false
	return (item.get("tags", []) as Array).has(tag)


func _on_item_pressed(item: Dictionary, btn: Button) -> void:
	if _busy or _current_task().is_empty():
		return
	var task := _current_task()
	match String(task.get("type", "tap")):
		"count":
			_handle_count(item, btn, task)
		_:
			if _matches(item, task):
				_correct(btn)
			else:
				_wrong()


func _handle_count(item: Dictionary, btn: Button, task: Dictionary) -> void:
	if _has_tag(item, _first_tag(task)):
		if btn.disabled:
			return
		_found += 1
		btn.disabled = true
		# Не меняем btn.text — смена текста меняет размер повёрнутой кнопки вокруг
		# старого pivot_offset, и объект «елозит». Прогресс и так виден в задании:
		# «Найдено: N из M». Найденный предмет просто затемняем.
		btn.modulate = Color(1, 1, 1, 0.55)
		_set_task_text("%s\nНайдено: %d из %d" % [String(task.get("text", "")), _found, _total])
		if _found >= _total:
			_correct(btn)
	else:
		_wrong()


func _on_digit_pressed(digit: int) -> void:
	if _busy or _current_task().is_empty():
		return
	var task := _current_task()
	if int(task.get("contact", -1)) == digit:
		var name := ""
		for c: Dictionary in _screen.get("contacts", []):
			if int(c.get("num", -1)) == digit:
				name = String(c.get("label", ""))
				break
		_flash_keypad(Color("#43aa8b"))
		_correct(null, "На связи! %s отвечает." % name)
	else:
		_wrong()


func _correct(btn: Button, custom_praise: String = "") -> void:
	_busy = true
	_stars += 1
	_play_sound(SND_SUCCESS)
	_update_progress()
	var praise := custom_praise
	if praise.is_empty():
		var pool: Array = _data.get("praise", ["Верно!"])
		praise = String(pool[randi() % pool.size()])
	_set_task_text(praise)
	if btn != null:
		_flash_button(btn, Color("#57cc99"))
	await get_tree().create_timer(1.4).timeout
	_next_task()


func _wrong() -> void:
	_misses += 1
	_play_sound(SND_FAIL)
	# Всегда сохраняем исходный вопрос задачи (что именно искать) и дополняем его
	# репликой + подсказкой, а не заменяем вопрос на бессмысленную фразу.
	var task := _current_task()
	var question := String(task.get("text", ""))
	var pool: Array = _data.get("wrong", ["Попробуй ещё!"])
	var rep := String(pool[randi() % pool.size()])
	var text := question + "\n" + rep
	var hint := String(task.get("hint", ""))
	if _misses >= 2 and not hint.is_empty():
		text += "\nПодсказка Пушка: " + hint
		_pulse_targets()
	elif _misses >= 1 and not hint.is_empty():
		text += "\nПодумай ещё немножко — это в вопросе выше."
	_set_task_text(text)


func _play_sound(stream: AudioStream) -> void:
	if _audio == null or stream == null:
		return
	_audio.stream = stream
	_audio.play()


func _pulse_targets() -> void:
	var task := _current_task()
	await get_tree().process_frame
	for e: Dictionary in _item_buttons:
		var btn: Button = e["btn"]
		if btn.disabled:
			continue
		if _matches(e["data"], task):
			_pulse_node(btn, 1.12)


func _flash_button(btn: Button, color: Color) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "modulate", color, 0.15)
	tw.tween_interval(0.4)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.3)


func _flash_keypad(color: Color) -> void:
	for kb in _keypad_buttons:
		_flash_button(kb, color)


func _pulse_node(node: Control, amount: float) -> void:
	node.pivot_offset = node.size / 2.0
	# Пульсация не должна сбивать индивидуальный масштаб кнопки.
	var base: Vector2 = node.get_meta("base_scale", Vector2.ONE)
	var tw := create_tween()
	tw.tween_property(node, "scale", base * amount, 0.12)
	tw.tween_property(node, "scale", base, 0.18)


# ---------------------------------------------------------------- Награда

func _show_reward() -> void:
	_busy = true
	_stars_label.text = "★ ".repeat(mini(_stars, 10)).strip_edges()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#fffdf7")
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 48
	sb.content_margin_right = 48
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var head := Label.new()
	head.text = "Экран пройден!"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 44)
	head.add_theme_color_override("font_color", Color("#1d3557"))
	v.add_child(head)

	var stars := Label.new()
	stars.text = "★".repeat(mini(_stars, 12))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 38)
	stars.add_theme_color_override("font_color", Color("#e09f3e"))
	v.add_child(stars)

	var sticker_wrap := CenterContainer.new()
	v.add_child(sticker_wrap)
	var swatch := PanelContainer.new()
	var s_sb := StyleBoxFlat.new()
	s_sb.bg_color = Color(String(_screen.get("sticker_color", "#f4a261")))
	s_sb.set_corner_radius_all(16)
	s_sb.content_margin_left = 28
	s_sb.content_margin_right = 28
	s_sb.content_margin_top = 12
	s_sb.content_margin_bottom = 12
	swatch.add_theme_stylebox_override("panel", s_sb)
	sticker_wrap.add_child(swatch)

	# Показываем котика-пирата в случайной позе из готовых 10 поз (misc/happy_kitten).
	# Каждое прохождение экрана — новая случайная поза.
	var pose_pool := []
	for k in range(1, 11):
		var pp := "res://assets/art/misc/happy_kitten/pose_%02d.png" % k
		if ResourceLoader.exists(pp):
			pose_pool.append(pp)
	if not pose_pool.is_empty():
		var pick: String = pose_pool[randi() % pose_pool.size()]
		var tex := load(pick) as Texture2D
		var img := TextureRect.new()
		img.texture = tex
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(320, 320)
		swatch.add_child(img)
	else:
		# Фолбэк — текст как раньше
		var st := Label.new()
		st.text = "Наклейка «%s»" % _screen.get("topic", _screen.get("title", ""))
		st.add_theme_font_size_override("font_size", 24)
		swatches_white(st)
		swatch.add_child(st)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	v.add_child(buttons)

	var again := Button.new()
	again.text = " Играть ещё "
	again.custom_minimum_size = Vector2(200, 56)
	again.add_theme_font_size_override("font_size", 24)
	again.pressed.connect(_restart)
	buttons.add_child(again)

	var menu := Button.new()
	menu.text = " Выбрать другой экран "
	menu.custom_minimum_size = Vector2(260, 56)
	menu.add_theme_font_size_override("font_size", 24)
	menu.pressed.connect(func(): closed.emit())
	buttons.add_child(menu)


func swatches_white(label: Label) -> void:
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _restart() -> void:
	var card := CARD.instantiate()
	card.setup(_screen, _data)
	card.closed.connect(func(): card.queue_free())
	get_tree().root.add_child.call_deferred(card)
	queue_free()
