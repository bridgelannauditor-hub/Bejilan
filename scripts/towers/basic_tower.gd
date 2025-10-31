extends Area2D

# Tower stats
@export var damage: float = 30
@export var fire_rate: float = 3  # shots per second
@export var range_distance: float = 500
@export var projectile_speed: float = 600.0

# Tower state
var target: Area2D = null
var fire_timer: float = 0.0
var is_placed: bool = false

# Node references
@onready var tower_top = $TowerTop
@onready var range_indicator = $RangeIndicator
@onready var range_area = $Range
@onready var shoot_point = $TowerTop/ShootPoint

# Projectile scene
var projectile_scene: PackedScene

func _ready():
	print("Tower _ready() called")
	
	# Load projectile scene
	projectile_scene = load("res://scenes/projectiles/basic_projectile.tscn")
	if projectile_scene:
		print("Projectile scene loaded successfully")
	else:
		print("ERROR: Could not load projectile scene")
	
	# Set up range detection
	$Range/CollisionShape2D.shape.radius = range_distance
	print("Range set to: ", range_distance)
	
	# Set up range indicator visual
	update_range_indicator()
	range_indicator.visible = false
	
	# Connect signals
	range_area.area_entered.connect(_on_target_entered_range)
	range_area.area_exited.connect(_on_target_exited_range)
	
	print("Tower setup complete")

func _process(delta):
	if not is_placed:
		return
	
	fire_timer -= delta
	
	# Update targeting
	if target and is_instance_valid(target):
		# Rotate tower top to face target
		var direction = (target.global_position - global_position).normalized()
		tower_top.rotation = atan2(direction.y, direction.x)
		
		# Shoot if ready and target is in range
		if fire_timer <= 0 and can_shoot():
			print("Shooting at target!")
			shoot()
			fire_timer = 1.0 / fire_rate
	else:
		find_new_target()

func place():
	print("Tower placed!")
	is_placed = true
	add_to_group("towers")
	
	# Debug: Check for enemies in range immediately
	var enemies = range_area.get_overlapping_areas()
	print("Enemies in range on placement: ", enemies.size())
	for enemy in enemies:
		print("Found enemy: ", enemy.name, " in group enemies: ", enemy.is_in_group("enemies"))

func can_shoot() -> bool:
	var can_shoot = (target and 
			is_instance_valid(target) and 
			global_position.distance_to(target.global_position) <= range_distance)
	
	if can_shoot:
		print("Can shoot! Target distance: ", global_position.distance_to(target.global_position))
	else:
		if not target:
			print("Cannot shoot: No target")
		elif not is_instance_valid(target):
			print("Cannot shoot: Target invalid")
		else:
			print("Cannot shoot: Target too far (", global_position.distance_to(target.global_position), " > ", range_distance, ")")
	
	return can_shoot

func shoot():
	if not target or not projectile_scene:
		print("Cannot shoot: No target or projectile scene")
		return
	
	print("Creating projectile...")
	# Create projectile
	var projectile = projectile_scene.instantiate()
	
	# Try different methods to find projectiles node
	var projectiles_node = get_tree().get_first_node_in_group("projectiles")
	if projectiles_node:
		projectiles_node.add_child(projectile)
		print("Projectile added to projectiles node")
	else:
		# Fallback: add to current scene
		get_parent().add_child(projectile)
		print("Projectile added to parent node")
	
	# Set projectile position and properties
	projectile.global_position = shoot_point.global_position
	if projectile.has_method("setup"):
		projectile.setup(target, damage, projectile_speed)
		print("Projectile setup complete")
	else:
		print("ERROR: Projectile has no setup method")
	
	# Play shoot effects
	play_shoot_effects()

func play_shoot_effects():
	print("Playing shoot effects")
	# Tower shoot animation (scale bounce)
	var tween = create_tween()
	tween.tween_property(tower_top, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(tower_top, "scale", Vector2(1.0, 1.0), 0.1)

func update_range_indicator():
	range_indicator.scale = Vector2.ONE * (range_distance / 150.0) * 2

func find_new_target():
	var enemies_in_range = range_area.get_overlapping_areas()
	print("Looking for targets. Enemies in range: ", enemies_in_range.size())
	
	for enemy in enemies_in_range:
		print("Checking enemy: ", enemy.name)
		print("  Is in group 'enemies': ", enemy.is_in_group("enemies"))
		print("  Is instance valid: ", is_instance_valid(enemy))
		
		if enemy.is_in_group("enemies") and is_instance_valid(enemy):
			target = enemy
			print("Found new target: ", enemy.name)
			return
	
	print("No valid targets found")
	target = null

func _on_target_entered_range(area: Area2D):
	print("Area entered range: ", area.name)
	print("  Is in group 'enemies': ", area.is_in_group("enemies"))
	
	if area.is_in_group("enemies") and target == null:
		print("Enemy entered range: ", area.name)
		target = area

func _on_target_exited_range(area: Area2D):
	print("Area exited range: ", area.name)
	if area == target:
		print("Target enemy exited range")
		target = null
		find_new_target()
