extends Node2D

@export var heart_scene: PackedScene
@export var controller_path: NodePath
@export var characters_path: NodePath
@export var mainchara_path: NodePath
@export var camerapath : NodePath
@export var start_spawn_every: float = 1.2
@export var min_spawn_every:= 0.3
@export var max_on_screen: int = 1
@export var half_life_seconds := 45.0
@export var new_time_elapsed := elapsed

@export var lanes_y: PackedFloat32Array = [-150.0, -75.0, 0.0, 75.0, 150.0]
@export var y_spawn_left: float = 200
@export var y_spawn_right: float = 350
@export var spawn_margin_x: float = 20.0

@onready var controller := get_node(controller_path)
@onready var characters := get_node_or_null(characters_path)
@onready var camera := get_node_or_null(camerapath)
@onready var mainchara := get_node(mainchara_path)
@onready var timer: Timer = $Timer
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var fever_active := false
var old_speed : float = 0
var old_maincharaspeed : float = 0
var puddle_cooldown := false
var subway_in := false

func _ready() -> void:
	print("exists")
	if heart_scene == null or characters == null:
		push_error("Spawner miswired: set enemy_scene and characters_path in Inspector.")
		return
	rng.randomize()
	timer.one_shot = false
	timer.wait_time = start_spawn_every
	if not timer.timeout.is_connected(_on_spawn_tick):
		timer.timeout.connect(_on_spawn_tick)
	timer.start()
	

func _process(delta):
	elapsed += delta

func _on_spawn_tick() -> void:
	if characters.get_child_count() >= max_on_screen:
		return
	_spawn_one()
	var k := pow(0.5, elapsed / max(half_life_seconds, 0.001))
	var next := min_spawn_every + (start_spawn_every - min_spawn_every) * k
	if new_time_elapsed > 1:
		new_time_elapsed = elapsed - floor(elapsed)
	if new_time_elapsed >= 1:
		max_on_screen += 1
		if spawn_margin_x >= 0.3:
			spawn_margin_x -= 0.2
		new_time_elapsed -= 1
	timer.wait_time = next
	timer.start()

func _spawn_one() -> void:
	print("spawning)")
	var e := heart_scene.instantiate()
	characters.add_child(e)
	
	var ctrl := get_node(controller_path)
	e.heart_contacted.connect(Callable(ctrl, "_on_heart_contacted"))
	
	if controller and controller.has_method("hook_enemy"):
		controller.hook_enemy(e)
	
	var cam := get_viewport().get_camera_2d()
	var view := get_viewport_rect().size
	var side := cam.global_position.x + (view.x * 0.5)
	var spawn_lanes = lanes_y
	var y: float = spawn_lanes[rng.randi_range(0, spawn_lanes.size() - 1)]
	var x: float = side - spawn_margin_x
	e.global_position = Vector2(x, y)
	print("spawned @", e.global_position)
