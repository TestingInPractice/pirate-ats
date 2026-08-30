class_name PuddleShape
extends Control
## Цветная лужица заданной формы, рисуется кодом (без PNG-артов).
## Формы (поле "shape" предмета): round, oval, blob, drop, wavy, corner.
## Цвет берётся из "color" предмета. Растягивается на всю кнопку.

var puddle_color := Color.WHITE
var shape := "round"


func setup(col: Color, s: String) -> void:
	puddle_color = col
	shape = s
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return
	var edge := puddle_color.darkened(0.18)
	var grad := puddle_color.lightened(0.06)

	match shape:
		"round":
			var r := minf(w, h) * 0.40
			var c := size / 2.0
			draw_circle(c, r + 3.0, edge)
			draw_circle(c, r, grad)
			draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.20, Color(1, 1, 1, 0.35))
			return
		"oval":
			# выпуклый эллипс — триангулируется без проблем
			_draw_ellipse(Rect2(w * 0.10, h * 0.22, w * 0.80, h * 0.52).grow(4.0), edge)
			_draw_ellipse(Rect2(w * 0.10, h * 0.22, w * 0.80, h * 0.52), grad)
			_draw_ellipse(Rect2(w * 0.20, h * 0.28, w * 0.14, h * 0.10), Color(1, 1, 1, 0.35))
			return
		"drop", "blob", "corner":
			# звёздно-выпуклые формы: контур + заливка (простой многоугольник)
			var pts := _star_points(w, h)
			_draw_contour(pts, edge, grad)
			return
		"wavy":
			_draw_wavy_band(w, h, edge, grad)
			return


# --- Выпуклый эллипс по точкам ---
func _draw_ellipse(rect: Rect2, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 40
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(Vector2(
			rect.position.x + rect.size.x * (0.5 + 0.5 * cos(a)),
			rect.position.y + rect.size.y * (0.5 + 0.5 * sin(a))
		))
	draw_colored_polygon(pts, col)


# --- Звёздно-выпуклый многоугольник: радиус — однозначная функция угла. ---
# Точки идут строго по возрастанию угла => многоугольник простой, корректно
# триангулируется даже в headless (без этого Godot выдаёт "triangulation failed").
func _star_points(w: float, h: float) -> PackedVector2Array:
	var cx := w * 0.5
	var cy := h * 0.5
	var base := minf(w, h) * 0.5
	var scale := maxf(w, h)
	var shear := Vector2(w / scale, h / scale)
	var steps := 48
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		var rn := _radius_norm(a)
		pts.append(Vector2(
			cx + rn * cos(a) * base * shear.x,
			cy + rn * sin(a) * base * shear.y
		))
	return pts


# Нормированный радиус (0..1) как функция угла.
func _radius_norm(a: float) -> float:
	match shape:
		"drop":
			# капля: узкий верх (угол 0), широкий низ (угол PI)
			return clampf(0.36 + 0.30 * (0.5 - 0.5 * cos(a)), 0.12, 1.0)
		"blob":
			# волнистая клякса с мягкими буграми
			return clampf(0.62 + 0.16 * sin(5.0 * a + 0.8) + 0.05 * sin(8.0 * a + 2.0), 0.22, 1.0)
		"corner":
			# угловатая: рваные грани (пила от высокочастотного синуса)
			return clampf(0.60 + 0.20 * (0.5 + 0.5 * sin(11.0 * a + 1.7)), 0.22, 1.0)
	return 0.7


# --- Контур (чуть крупнее) + заливка ---
func _draw_contour(pts: PackedVector2Array, edge: Color, fill: Color) -> void:
	if pts.size() < 3:
		return
	var cx := 0.0
	var cy := 0.0
	for p in pts:
		cx += p.x
		cy += p.y
	cx /= float(pts.size())
	cy /= float(pts.size())
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(cx + (p.x - cx) * 1.06, cy + (p.y - cy) * 1.06))
	draw_colored_polygon(out, edge)
	draw_colored_polygon(pts, fill)


# --- «Волнистая» полоса: круги вдоль S-кривой (без полигонов) ---
func _draw_wavy_band(w: float, h: float, edge: Color, fill: Color) -> void:
	var cr := minf(w, h) * 0.16
	var steps := 26
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := Vector2(w * (0.14 + 0.72 * t), h * (0.5 + 0.20 * sin(t * TAU * 2.0)))
		draw_circle(p, cr + 2.0, edge)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := Vector2(w * (0.14 + 0.72 * t), h * (0.5 + 0.20 * sin(t * TAU * 2.0)))
		draw_circle(p, cr, fill)
	var bp := Vector2(w * 0.34, h * (0.5 + 0.20 * sin(0.34 * TAU * 2.0)))
	draw_circle(bp, cr * 0.35, Color(1, 1, 1, 0.30))
