extends Node3D
class_name DeliDisplayCase

@export var case_category: String = "bread_bakery"
@export var sections: int = 6

# Spawn points organized by section
var section_spawns: Dictionary = {}  # {1: [markers], 2: [markers], ...}
var all_spawns: Array[Marker3D] = []

func _ready():
	collect_spawn_points()
	print("Deli Case '%s' initialized with %d sections" % [case_category, sections])
	for section_num in section_spawns:
		print("  Section %d: %d spawns" % [section_num, section_spawns[section_num].size()])

func collect_spawn_points():
	var spawn_container = get_node_or_null("SpawnPoints")
	if not spawn_container:
		return
	
	for child in spawn_container.get_children():
		if child is Marker3D:
			all_spawns.append(child)
			
			# Extract section number from name: "Spawn_Section3_01" -> 3
			var regex = RegEx.new()
			regex.compile("Section(\\d+)")
			var result = regex.search(child.name)
			
			if result:
				var section_num = result.get_string(1).to_int()
				if section_num not in section_spawns:
					section_spawns[section_num] = []
				section_spawns[section_num].append(child)

# Get random spawn from specific section
func get_spawn_from_section(section_num: int) -> Marker3D:
	if section_num not in section_spawns:
		return null
	var section_array = section_spawns[section_num]
	if section_array.is_empty():
		return null
	return section_array[randi() % section_array.size()]

# Get any random spawn
func get_random_spawn() -> Marker3D:
	if all_spawns.is_empty():
		return null
	return all_spawns[randi() % all_spawns.size()]

# Check if section is full (for restocking logic)
func is_section_full(section_num: int, occupied_spawns: Array) -> bool:
	if section_num not in section_spawns:
		return true
	
	for spawn in section_spawns[section_num]:
		if spawn not in occupied_spawns:
			return false
	return true
