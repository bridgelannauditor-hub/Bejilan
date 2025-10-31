extends Area2D

var speed: float = 400.0
var damage: float = 15.0
var target: Node2D
var direction: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite2D

func setup(projectile_target: Node2D, projectile_damage: float, projectile_speed: float):
	target = projectile_target
	damage = projectile_damage
	speed = projectile_speed
	
	# Calculate initial direction
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

func _physics_process(delta):
	if not target or not is_instance_valid(target):
		queue_free()
		return
	
	# Update direction to track moving target
	direction = (target.global_position - global_position).normalized()
	rotation = direction.angle()
	
	# Move toward target
	position += direction * speed * delta
	
	# Check if hit target or passed it
	if global_position.distance_to(target.global_position) < 10:
		hit_target()

func hit_target():
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Create hit effect
	queue_free()
