extends Node2D

var combat_root: Node = null
var owner_faction: String = ""
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 2.0
var radius: float = 8.0
var damage_packet: Dictionary = {}
var tint: Color = Color.WHITE

func setup(root: Node, faction_id: String, start_position: Vector2, velocity_vector: Vector2, projectile_radius: float, packet: Dictionary, color_value: Color) -> void:
	combat_root = root
	owner_faction = faction_id
	global_position = start_position
	velocity = velocity_vector
	radius = projectile_radius
	damage_packet = packet
	tint = color_value

func _process(delta: float) -> void:
	if combat_root and combat_root.has_method("is_game_paused") and combat_root.is_game_paused():
		queue_redraw()
		return
	lifetime -= delta
	global_position += velocity * delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()
		return
	if combat_root:
		combat_root.resolve_projectile(self)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, tint)
	draw_circle(Vector2.ZERO, radius * 0.45, Color.WHITE)

