extends CharacterBody2D
signal contacted(enemy: CharacterBody2D)
@export var dir: Vector2 = Vector2.LEFT
@export var profile: EnemyProfile
@export var tutorialpath : NodePath
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $enemy_hitbox
@onready var healthbar = $HealthBar


var _anim_idle: StringName = &"idle"
var _anim_contact: StringName = &"contact"
var speed: float = 80.0
var slowed : bool = false
var total_hp : int = 40

enum State { MOVE, CONTACTED }
var state: State = State.MOVE

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	healthbar.init_health(total_hp)
	if profile:
		if profile.sprite_frames:
			anim.sprite_frames = profile.sprite_frames
		if profile.anim_idle != "":
			_anim_idle = profile.anim_idle
		if profile.anim_contact != "":
			_anim_contact = profile.anim_contact

	if anim.sprite_frames and anim.sprite_frames.has_animation(_anim_idle):
		anim.play(_anim_idle)

	var cb := Callable(self, "_on_enemy_hitbox_area_entered")
	if not hitbox.area_entered.is_connected(cb):
		hitbox.area_entered.connect(cb)

func _process(delta) -> void:
	pass

func _physics_process(delta: float) -> void:
	if state != State.MOVE: return
	if get_tree().paused == true:
		velocity = Vector2.ZERO
	else:
		var actual_speed: float
		if profile:
			actual_speed = profile.speed
		else:
			actual_speed = speed
		
		if slowed:
			actual_speed *= 0.05
		
		velocity = dir * actual_speed
	move_and_slide()

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	print("contacted")
	if state != State.MOVE: return
	if area.name != "player_hitbox": return
	state = State.CONTACTED
	hitbox.monitoring = false
	if anim.sprite_frames and anim.sprite_frames.has_animation(_anim_contact):
		anim.play("hit")
		print("there is the animatoin for contact")
	print("[ENEMY] contact.")
	emit_signal("contacted", self)
	$AudioStreamPlayer.play()
	revert_animation()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func take_damage(hp: int) -> void:
	anim.play(_anim_contact)
	print(total_hp)
	total_hp -= hp
	print(total_hp)
	if total_hp <= 0:
		anim.play(_anim_contact)
		Globals.enemies_killed += 1
		queue_free()
	healthbar.health = total_hp

func revert_animation() -> void:
	if get_tree():
		await get_tree().create_timer(3.0).timeout
		anim.play(_anim_idle)
