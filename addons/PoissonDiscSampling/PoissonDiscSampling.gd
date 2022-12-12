class_name PoissonDiscSampling

var _radius: float
var _sample_region_shape
var _retries: int
var _start_pos: Vector2
var _sample_region_rect: Rect2
var _cell_size: float
var _rows: int
var _cols: int
var _cell_size_scaled: Vector2
var _grid: Array = []
var _points: Array = []
var _spawn_points: Array = []
var _transpose: Vector2

# radius - minimum distance between points
# sample_region_shape - takes any of the following:
# 		-a Rect2 for rectangular region
#		-an array of Vector2 for polygon region
#		-a Vector3 with x,y as the position and z as the radius of the circle
# retries - maximum number of attempts to look around a sample point, reduce this value to speed up generation
# start_pos - optional parameter specifying the starting point
#
# returns an Array of Vector2D with points in the order of their discovery
func generate_points(radius: float, sample_region_shape, retries:int = 30, start_pos := Vector2(INF, INF)) -> Array:
	randomize()
	
	_radius = radius
	_sample_region_shape = sample_region_shape
	_retries = retries
	_start_pos = start_pos
	
	# If no special start position is defined, pick one
	if _start_pos.x == INF:
		_start_pos = get_default_start_position(sample_region_shape)
	
	_sample_region_rect = get_region_bbox(sample_region_shape)
	_cell_size = get_cell_size(_radius)
	var cols_and_rows = get_cols_and_rows(_sample_region_rect, _cell_size)
	_cols = cols_and_rows.cols
	_rows = cols_and_rows.rows
	
	_cell_size_scaled = get_cell_size_scaled(_sample_region_rect, cols_and_rows.cols, cols_and_rows.rows)
	# use tranpose to map points starting from origin to calculate grid position
	_transpose = get_transpose(_sample_region_rect)
	
	_points = []
	_spawn_points = []
	_spawn_points.append(_start_pos)
	
	_grid = get_grid(cols_and_rows.cols, cols_and_rows.rows)
	
	while _spawn_points.size() > 0:
		var spawn_index: int = randi() % _spawn_points.size()
		var spawn_centre: Vector2 = _spawn_points[spawn_index]
		var sample_accepted: bool = false
		for i in retries:
			var angle: float = 2 * PI * randf()
			var sample: Vector2 = spawn_centre + Vector2(cos(angle), sin(angle)) * (radius + radius * randf())
			if _is_valid_sample(sample, _radius, _sample_region_shape, _sample_region_rect):
				_grid[int((_transpose.x + sample.x) / _cell_size_scaled.x)][int((_transpose.y + sample.y) / _cell_size_scaled.y)] = _points.size()
				_points.append(sample)
				_spawn_points.append(sample)
				sample_accepted = true
				break
		if not sample_accepted:
			_spawn_points.remove(spawn_index)
	return _points


func _is_valid_sample(sample: Vector2, radius:float, region_shape, region_bbox) -> bool:
	if _is_point_in_region(sample, region_shape, region_bbox):
		var cell := Vector2(int((_transpose.x + sample.x) / _cell_size_scaled.x), int((_transpose.y + sample.y) / _cell_size_scaled.y))
		var cell_start := Vector2(max(0, cell.x - 2), max(0, cell.y - 2))
		var cell_end := Vector2(min(cell.x + 2, _cols - 1), min(cell.y + 2, _rows - 1))
	
		for i in range(cell_start.x, cell_end.x + 1):
			for j in range(cell_start.y, cell_end.y + 1):
				var search_index: int = _grid[i][j]
				if search_index != -1:
					var dist: float = _points[search_index].distance_to(sample)
					if dist < radius:
						return false
		return true
	return false


func _is_point_in_region(sample: Vector2, region_shape, region_bbox) -> bool:
	if region_bbox.has_point(sample):
		match typeof(region_shape):
			TYPE_RECT2:
				return true
			TYPE_VECTOR2_ARRAY, TYPE_ARRAY:
				if Geometry.is_point_in_polygon(sample, region_shape):
					return true
			TYPE_VECTOR3:
				if Geometry.is_point_in_circle(sample, Vector2(region_shape.x, region_shape.y), region_shape.z):
					return true
			_:
				return false
	return false

#if _start_pos.x == INF:
func get_default_start_position(region_shape):
	match typeof(region_shape):
		TYPE_RECT2:
			return Vector2(
				region_shape.position.x + region_shape.size.x * randf(),
				region_shape.position.y + region_shape.size.y * randf()
			)
		
		TYPE_VECTOR2_ARRAY, TYPE_ARRAY:
			var n: int = region_shape.size()
			var i: int = randi() % n
			return region_shape[i] + (region_shape[(i + 1) % n] - region_shape[i]) * randf()
		
		TYPE_VECTOR3:
			var angle: float = 2 * PI * randf()
			return Vector2(region_shape.x, region_shape.y) + Vector2(cos(angle), sin(angle)) * region_shape.z * randf()
	
		_:
			return Vector2.ZERO

func get_region_bbox(region_shape):
	match typeof(region_shape):
		TYPE_RECT2:
			return region_shape
	
		TYPE_VECTOR2_ARRAY, TYPE_ARRAY:
			var start: Vector2 = region_shape[0]
			var end: Vector2 = region_shape[0]
			for i in range(1, region_shape.size()):
				start.x = min(start.x, region_shape[i].x)
				start.y = min(start.y, region_shape[i].y)
				end.x = max(end.x, region_shape[i].x)
				end.y = max(end.y, region_shape[i].y)
			return Rect2(start, end - start)
		
		TYPE_VECTOR3:
			var x = region_shape.x
			var y = region_shape.y
			var r = region_shape.z
			return Rect2(x - r, y - r, r * 2, r * 2)

		_:
			push_error("Unrecognized shape!!! Please input a valid shape")
			return Rect2(0, 0, 0, 0)

func get_cell_size(radius):
	return radius / sqrt(2)

func get_cols_and_rows(region_bbox, cell_size):
	return {
		"cols": max(floor(region_bbox.size.x / cell_size), 1),
		"rows": max(floor(region_bbox.size.y / cell_size), 1)
	}

func get_cell_size_scaled(region_bbox, cols, rows) -> Vector2:
	return Vector2(
		region_bbox.size.x / cols,
		region_bbox.size.y / rows
	)

func get_transpose(region_bbox):
	return -region_bbox.position

func get_grid(cols, rows):
	var grid = []
	for i in cols:
		grid.append([])
		for j in rows:
			grid[i].append(-1)
	return grid
