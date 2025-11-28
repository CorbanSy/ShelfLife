extends PathFollow3D
class_name ShoppingCart

# Movement settings
@export var base_speed: float = 2.0  # Base movement speed
@export var max_speed: float = 8.0   # Maximum speed
@export var player_boost: float = 2.0  # Speed added per player

# Cart capacity
@export var max_items: int = 20
@export var max_weight: float = 100.0

# Current state
var current_speed: float = 0.0
var pushing_players: Array = []
var items_in_cart: Array = []
var total_weight: float = 0.0
var is_locked: bool = false

# Node references
@onready var cart_body = $CartBody
@onready var cart_collision = $CartBody/CartCollision
@onready var interaction_area = $InteractionArea
@onready var item_container = $CartBody/ItemContainer
@onready var cart_label = $CartBody/CartLabel

# Signals
signal item_added(item: Node3D)
signal item_removed(item: Node3D)
signal cart_full()
signal reached_destination()

func _ready():
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	
	# Connect cart collision for items
	if cart_collision:
		cart_collision.area_entered.connect(_on_item_detected)
	
	update_label()

func _process(delta):
	if is_locked:
		return
	
	# Calculate speed based on players pushing
	if pushing_players.size() > 0:
		current_speed = base_speed + (pushing_players.size() * player_boost)
		current_speed = min(current_speed, max_speed)
	else:
		# Slow down when no one is pushing
		current_speed = lerp(current_speed, base_speed * 0.5, delta * 2.0)
	
	# Move along path
	progress += current_speed * delta
	
	# Check if reached end of path
	if progress_ratio >= 0.99:
		_on_reached_end()
	
	update_label()

func _on_player_entered(body):
	if body.is_in_group("player") and body not in pushing_players:
		pushing_players.append(body)
		print("Player started pushing. Total: %d" % pushing_players.size())

func _on_player_exited(body):
	if body in pushing_players:
		pushing_players.erase(body)
		print("Player stopped pushing. Total: %d" % pushing_players.size())

func _on_item_detected(area):
	# When cart touches an item, automatically pick it up
	var item = area.get_parent()
	if item.has_method("pick_up"):
		add_item(item)

func add_item(item: Node3D) -> bool:
	# Check if cart is full
	if items_in_cart.size() >= max_items:
		cart_full.emit()
		return false
	
	# Check weight limit
	var item_weight = item.get("weight") if item.get("weight") else 1.0
	if total_weight + item_weight > max_weight:
		return false
	
	# Add to cart
	items_in_cart.append(item)
	total_weight += item_weight
	
	# Reparent item to cart
	item.reparent(item_container)
	
	# Stack items vertically
	var stack_height = items_in_cart.size() * 0.15
	item.position = Vector3(
		randf_range(-0.3, 0.3),  # Random X offset
		stack_height,
		randf_range(-0.3, 0.3)   # Random Z offset
	)
	item.rotation = Vector3(0, randf_range(0, TAU), 0)  # Random rotation
	
	# Disable item physics while in cart
	if item.has_method("disable_physics"):
		item.disable_physics()
	
	item_added.emit(item)
	print("Item added to cart. Total: %d/%d" % [items_in_cart.size(), max_items])
	return true

func remove_item(item: Node3D) -> bool:
	if item not in items_in_cart:
		return false
	
	items_in_cart.erase(item)
	
	var item_weight = item.get("weight") if item.get("weight") else 1.0
	total_weight -= item_weight
	
	# Re-enable physics
	if item.has_method("enable_physics"):
		item.enable_physics()
	
	item_removed.emit(item)
	return true

func remove_all_items():
	for item in items_in_cart.duplicate():
		remove_item(item)

func _on_reached_end():
	is_locked = true
	reached_destination.emit()
	print("Cart reached destination with %d items!" % items_in_cart.size())
	
	# Unload items (call game manager or restaurant system)
	await get_tree().create_timer(1.0).timeout
	unload_items()

func unload_items():
	# Transfer items to restaurant/pantry
	for item in items_in_cart.duplicate():
		# Game manager would handle this
		print("Unloading: %s" % item.name)
		item.queue_free()
	
	items_in_cart.clear()
	total_weight = 0.0
	
	# Reset cart position
	await get_tree().create_timer(2.0).timeout
	reset_to_start()

func reset_to_start():
	progress_ratio = 0.0
	is_locked = false
	current_speed = 0.0
	pushing_players.clear()
	print("Cart reset to start position")

func update_label():
	if cart_label:
		cart_label.text = "CART\n%d/%d Items\n%.1f kg" % [
			items_in_cart.size(),
			max_items,
			total_weight
		]

func lock():
	is_locked = true

func unlock():
	is_locked = false
