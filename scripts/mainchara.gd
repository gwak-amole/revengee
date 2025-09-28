extends CharacterBody2D

@export var growth_per_sec: float = 0.0085
@export var edge_padding: float = 130
@export var controllerpath : NodePath
@onready var cooldown_timer := $melee_box/Timer
@onready var melee_box := $melee_box
@onready var controller := get_node(controllerpath)
@onready var cam: Camera2D = get_viewport().get_camera_2d()

var enemy_contact_range = false
var health = 3
var player_alive = true
var start_speed := 200
@export var speed : float
@export var slowdown_factor : float = 1
var max_speed := 350
var elapsed := 0.0
var can_attack = true
var attacking_rn = false
var current_dir = "none"
var used_enemies_at_5 = false
var used_enemies_at_10 = false

func _ready():
	speed = start_speed
	$AnimatedSprite2D.play("idleside")

func _physics_process(delta: float) -> void:
	player_movement(delta)
	_clamp_to_camera()

func _process(delta: float) -> void:
	elapsed += delta
	speed = start_speed * pow(1.0 + growth_per_sec, elapsed)
	if speed > max_speed:
		speed = max_speed
	if Input.is_action_pressed("ui_accept") and can_attack:
		if Globals.ammo_exists == false:
			return
		print("attacking")
		attacking_rn = true
		$AnimatedSprite2D.play("hit")
		can_attack = false
		controller._lose_ammo()
		cooldown_timer.start()
		print(melee_box.is_colliding())
		if melee_box.is_colliding():
			print("MELEE IS HITTING")
			var i = melee_box.get_collider()
			if i.is_in_group("Enemies"):
				i.take_damage(20)
		controller._update_enemieskilled()
		await get_tree().create_timer(0.3).timeout
		attacking_rn = false
		await get_tree().create_timer(0.2).timeout
		can_attack = true
		print("can attack again")
	
func player_movement(delta):
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		velocity.x = speed * slowdown_factor
		current_dir = "right"
		play_anim(1)
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -speed * slowdown_factor
		current_dir = "left"
		play_anim(1)
	elif Input.is_action_pressed("ui_down"):
		velocity.y = speed * slowdown_factor
		current_dir = "down"
		play_anim(1)
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -speed * slowdown_factor
		current_dir = "up"
		play_anim(1)
	else:
		velocity = Vector2.ZERO
		play_anim(0)
		
	move_and_slide()
	
func play_anim(animation):
	var dir = current_dir
	var anim = $AnimatedSprite2D
	
	if dir == "right":
		melee_box.target_position = Vector2(60, 0)
		anim.flip_h = false
		if attacking_rn:
			pass
		else:
			if animation == 1:
				anim.play("walkingside")
			elif animation == 0:
				anim.play("idleside")
	elif dir == "left":
		melee_box.target_position = Vector2(-60, 0)
		anim.flip_h = true
		if attacking_rn:
			pass
		else:
			if animation == 1:
				anim.play("walkingside")
			elif animation == 0:
				anim.play("idleside")
	elif dir == "down":
		anim.flip_v = true
		melee_box.target_position = Vector2(0, 60)
		if attacking_rn:
			pass
		else:
			if animation == 1:
				anim.play("walkingforward")
			elif animation == 0:
				anim.play("idle")
	elif dir == "up":
		melee_box.target_position = Vector2(0, -60)
		anim.flip_v = false
		if attacking_rn:
			pass
		else:
			if animation == 1:
				anim.play("walkingforward")
			elif animation == 0:
				anim.play("idle")


func _on_player_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_contact_range = true


func _on_player_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_contact_range = false

func _clamp_to_camera() -> void:
	if cam == null:
		cam = get_viewport().get_camera_2d()
		if cam == null: 
			return
	var vp_size: Vector2 = get_viewport_rect().size
	var world_size: Vector2 = vp_size / cam.zoom
	var half := world_size * 0.5
	var center := cam.global_position
	var top_left := center - half
	var bottom_right := center + half

	global_position.y = clamp(global_position.y, top_left.y, bottom_right.y - 20)
	global_position.x = clamp(global_position.x, top_left.x + edge_padding, bottom_right.x - edge_padding)
