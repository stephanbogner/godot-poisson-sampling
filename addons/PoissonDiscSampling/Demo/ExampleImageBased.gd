extends Node2D

var k: int = 0
var points := []
var radii := []
var image_texture_resource = preload("assets/bw_image.png")

func _ready():
	var pds = PoissonDiscSampling.new()
	var start_time = OS.get_ticks_msec()
	var data = pds.generate_points_on_image(14, 40, image_texture_resource, Rect2(Vector2.ZERO, Vector2(1000, 620)), Vector2(1.2, 1.2))
	points = data.points
	radii = data.radii
	print(points.size(), " points generated in ", OS.get_ticks_msec() - start_time, " miliseconds" )
	get_viewport().render_target_clear_mode = Viewport.UPDATE_ONCE

func _draw() -> void:
	if k == 1:
		draw_rect ( Rect2(Vector2.ZERO, Vector2(1000, 1000)), Color("#44A587"))
	draw_circle(points[k], radii[k]/2 - 4, Color("#000"))
	draw_circle(points[k], radii[k]/2 - 8, Color("#44A587"))

func _process(delta: float) -> void:
	if k < points.size() - 1:
		update()
		k += 1
