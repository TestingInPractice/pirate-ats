extends Control
## Главное меню: список 12 тематических экранов книги.

const CARD_SCENE := preload("res://scenes/ScreenCard.tscn")
const CAT_TEXTURE := preload("res://assets/cat.png")

var _data: Dictionary = {}
var _cat: Sprite2D
var _cat_dir := 1.0
var _run_time := 0.0


func _ready() -> void:
	_data = _load_json("res://data/screens.json")
	if _data.is_empty():
		push_error("Не удалось загрузить data/screens.json")
		return
	_build_ui()


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1d3557")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Котята-пираты"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#ffd166"))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Интерактивная обучающая книга — выбери экран"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", Color("#f1faee"))
	vbox.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	for screen: Dictionary in _data.get("screens", []):
		grid.add_child(_make_screen_button(screen))

	_spawn_cat()


func _spawn_cat() -> void:
	# Котик из «Азбуки» бегает по нижнему краю меню между кнопками.
	_cat = Sprite2D.new()
	_cat.texture = CAT_TEXTURE
	var target_size := 150.0
	_cat.scale = Vector2.ONE * (target_size / float(CAT_TEXTURE.get_width()))
	add_child(_cat)
	_cat.position = Vector2(120.0, get_viewport_rect().size.y - 82.0)


func _process(delta: float) -> void:
	if _cat == null:
		return
	var view := get_viewport_rect().size
	var half_w: float = CAT_TEXTURE.get_width() * _cat.scale.x * 0.5
	_run_time += delta

	_cat.position.x += _cat_dir * 170.0 * delta
	if _cat.position.x < half_w + 12.0 or _cat.position.x > view.x - half_w - 12.0:
		_cat_dir *= -1.0
		# Если кот побежит «хвостом вперёд» — заменить знак сравнения на ">".
		_cat.flip_h = _cat_dir < 0.0

	# Лёгкие подпрыгивания и покачивание, чтобы был виден бег.
	_cat.position.y = view.y - 82.0 - abs(sin(_run_time * 7.0)) * 18.0
	_cat.rotation = sin(_run_time * 14.0) * 0.05


func _make_screen_button(screen: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(430, 126)
	btn.text = "%d. %s\n%s" % [screen.get("num", 0), screen.get("title", ""), screen.get("topic", "")]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", 24)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var accent := Color(String(screen.get("sticker_color", "#f4a261")))
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent.darkened(0.15)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = accent
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = accent.darkened(0.35)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	btn.pressed.connect(_open_screen.bind(screen))
	return btn


func _open_screen(screen: Dictionary) -> void:
	var card := CARD_SCENE.instantiate()
	card.setup(screen, _data)
	card.closed.connect(func(): card.queue_free())
	get_tree().root.add_child.call_deferred(card)
