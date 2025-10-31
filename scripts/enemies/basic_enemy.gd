extends Area2D

@export var speed: float = 100.0
@export var health: float = 100.0
@export var max_health: float = 100.0

var path_follow: PathFollow2D
var is_alive: bool = true

signal enemy_died
signal enemy_reached_end

@onready var health_bar_fill = $HealthBar/Fill

func _ready():
	health = max_health
	update_health_bar()

func _process(delta):
	if not path_follow or not is_alive:
		return
	
	# Move along path
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	
	# Check if reached end of path
	if path_follow.progress_ratio >= 0.99:
		reach_end()

func take_damage(amount: float):
	if not is_alive:
		return
	
	health -= amount
	update_health_bar()
	
	if health <= 0:
		die()

func update_health_bar():
	if health_bar_fill:
		var health_ratio = health / max_health
		health_bar_fill.size.x = 120 * health_ratio
		
		# Change color based on health
		if health_ratio > 0.6:
			health_bar_fill.color = Color.GREEN
		elif health_ratio > 0.3:
			health_bar_fill.color = Color.YELLOW
		else:
			health_bar_fill.color = Color.RED

func die():
	is_alive = false
	enemy_died.emit()
	queue_free()

func reach_end():
	is_alive = false
	enemy_reached_end.emit()
	queue_free()
