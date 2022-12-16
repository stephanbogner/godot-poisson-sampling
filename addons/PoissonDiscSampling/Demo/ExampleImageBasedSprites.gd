extends Node2D

var k: int = 0
var points := []
var radii := []
var image_texture_resource = preload("assets/bw_image.png")

var image_texture_resource_1 = preload("assets/plant_1.png")
var image_texture_resource_2 = preload("assets/plant_2.png")
var image_texture_resource_3 = preload("assets/plant_3.png")
var textures = [image_texture_resource_1, image_texture_resource_2, image_texture_resource_3]

func _ready():
	var pds = PoissonDiscSampling.new()
	var start_time = OS.get_ticks_msec()
	var data = pds.generate_points_on_image(14, 30, image_texture_resource, Rect2(Vector2.ZERO, Vector2(1000, 620)), Vector2(1.2, 1.2), 30, Vector2(1000,420))
	points = data.points
	radii = data.radii
	print(points.size(), " points generated in ", OS.get_ticks_msec() - start_time, " miliseconds" )
	get_viewport().render_target_clear_mode = Viewport.UPDATE_ONCE

func _draw() -> void:
	if k == 1:
		draw_rect ( Rect2(Vector2.ZERO, Vector2(1000, 1000)), Color("#253527"))
	
	var index = 0
	var scale = 2
	if radii[k] > 25:
		index = 2
		scale = 1.2
	elif radii[k] > 17:
		index = 1
		scale = 1.3
	draw_texture_rect(textures[index], Rect2(points[k] + Vector2(-10,-10) * scale, Vector2(20, 20) * scale), false)
	
	#draw_circle(points[k], radii[k]/2 - 4, Color("#000"))
	#draw_circle(points[k], radii[k]/2 - 8, Color("#44A587"))

func _process(delta: float) -> void:
	if k < points.size() - 1:
		update()
		k += 1
