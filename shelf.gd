extends Node3D
class_name GroceryShelf

# What category of items spawn here
@export var shelf_category: String = "pasta"

# Reference to spawn points
var spawn_points: Array[Marker3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collect_spawn_points()

func collect_spawn_points():
	var spawn_container = get_node_or_null("SpawnPoints")
	if spawn_container:
		for child in spawn_container.get_children():
			if child is Marker3D:
				spawn_points.append(child)
	print("Shelf '%s' has %d spawn points" % [shelf_category, spawn_points.size()])
	
#Get a random spawn point
func get_random_spawn_point() -> Marker3D:
	if spawn_points.is_empty():
		return null
	return spawn_points[randi() % spawn_points.size()]
	
# Get spawn point by index
func get_spawn_point(index: int) -> Marker3D:
	if index < 0 or index >= spawn_points.size():
		return null
	return spawn_points[index]
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
