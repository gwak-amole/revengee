extends Node

@export var pointspath : NodePath
@export var heartsboxpath : NodePath
@export var swordsboxpath : NodePath
@export var enemieskilledpath : NodePath
@export var level1path : NodePath
@export var level2path : NodePath
@export var level3path : NodePath
@export var optionspath : NodePath
@export var camerapath : NodePath
@export var audiopath : NodePath
@onready var heart_nodes: Array[CanvasItem] = []
@onready var hearts_box := get_node(heartsboxpath)
@onready var sword_nodes: Array[CanvasItem] = []
@onready var swords_box := get_node(swordsboxpath)
@onready var points := get_node(pointspath)
@onready var enemieskilled := get_node(enemieskilledpath)
@onready var level1 := get_node(level1path)
@onready var level2 := get_node(level2path)
@onready var level3 := get_node(level3path)
@onready var options := get_node(optionspath)
@onready var camera := get_node(camerapath)
@onready var audio := get_node(audiopath)

var lives : int
var points_int : int
var times : int
var lives_start = 3
var cooldown : float = 5.0
var power = 1.2
var ammos : int
var ammos_start = 5
var points_frozen = false

func _ready() -> void:
	audio.play()
	_update_enemieskilled()
	level1.show()
	level2.hide()
	level3.hide()
	options.hide()
	Globals.enemies_killed = 0
	heart_nodes.clear()
	if hearts_box:
		for c in hearts_box.get_children():
			if c is CanvasItem:
				heart_nodes.append(c)
	else:
		push_error("Heart UI path not valid node haiyaa")
	sword_nodes.clear()
	if swords_box:
		for c in swords_box.get_children():
			if c is CanvasItem:
				sword_nodes.append(c)
	else:
		push_error("Heart UI path not valid node haiyaa")
	lives = clamp(lives_start, 0, heart_nodes.size())
	_update_hearts()
	ammos = clamp(ammos_start, 0, sword_nodes.size())
	_update_ammo()
	print("[Hearts] nodes:", heart_nodes.size(), " lives:", lives)
	print("[ammo] nodes:", sword_nodes.size(), " ammo:", ammos)
	_loop_points()
	_update_enemieskilled()


func hook_enemy(e: Node) -> void:
	if not e.has_signal("contacted"): return
	if not e.contacted.is_connected(_on_enemy_contacted):
		e.contacted.connect(_on_enemy_contacted)

func _on_enemy_contacted(enemy: Node) -> void:
	points.hide()
	points_int -= (points_int / 10)
	_update_points()
	times -= times/5
	print("CONTACTED")
	#var p = enemy.get("profile") if enemy else null
	#if p == null:
		#if is_instance_valid(enemy):
		# enemy.queue_free()
		#get_tree().paused = false
		#return
	
	_lose_life()
	points.show()
	get_tree().paused = false
	
	if lives <= 0:
		_game_over()

	if is_instance_valid(enemy):
		if get_tree():
			await get_tree().create_timer(2.0).timeout
		# enemy.queue_free()
	

func _increment_lives():
	lives = max(lives + 1, 0)
	_update_hearts()

func _lose_life() -> void:
	lives = max(lives - 1, 0)
	_update_hearts()
	print("points frozen")
	points_int -= (points_int / 10)
	_update_points()
	_gain_ammo()
	times -= times/5

func _update_hearts() -> void:
	var shown : int = clamp(lives, 0, heart_nodes.size())
	for i in  range(heart_nodes.size()):
		heart_nodes[i].visible = (i < shown)
	print("HEarts update -> lives:", lives, " shown", shown)
	
func _lose_ammo() -> void:
	print("losign ammo -----")
	ammos = max(ammos - 1, 0)
	_update_ammo()

func _gain_ammo() -> void:
	ammos += 1
	_update_ammo()
	points_int += (points_int / 10)
	_update_points()

func _update_ammo() -> void:
	print(sword_nodes.size(), "SWORDSNODES SIZE")
	var shown : int = clamp(ammos, 0, sword_nodes.size())
	for i in range(sword_nodes.size()):
		sword_nodes[i].visible = (i < shown)
	print("AMMO update -> ammos:", ammos, " shown", shown)
	if shown == 0:
		Globals.ammo_exists = false
	if shown > 0:
		Globals.ammo_exists = true

func _game_over() -> void:
	print("game over!!")
	Globals.points = points_int
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func _update_points() -> void:
	points.text = str(points_int)
	
func _increment_points() -> void:
	if points_frozen == false:
		times += 1
		points_int += int(15 * pow(power, times))
		_update_points()
	else:
		pass

func _loop_points() -> void:
	await get_tree().create_timer(cooldown).timeout
	print("annyeong")
	while true:
		while get_tree().paused: 
			await get_tree().create_timer(0.1, true).timeout
		await _increment_points()
		await get_tree().create_timer(cooldown).timeout
		print("5 secs passed")

func _loop_check_enemies() -> void:
	while true:
		var enemy_count = Globals.enemies_killed
		if Globals.enemies_killed != enemy_count:
			enemy_count += 1
			_update_enemieskilled()

func _update_enemieskilled() -> void:
	enemieskilled.text = str("Enemies killed: ", Globals.enemies_killed)
	if level2.visible == false:
		if Globals.enemies_killed == 5:
			options.show()
			print("showing options")
			get_tree().paused = true
			level2.show()
			points_int += 250
			level1.hide()
	if level3.visible == false:
		if Globals.enemies_killed == 10:
			options.show()
			print("showing options")
			get_tree().paused = true
			level2.hide()
			points_int += 500
			level3.show()


func _on_button_pressed() -> void:
	print("button received")
	heart_nodes.pop_back()
	get_tree().paused = false
	options.hide()


func _on_button_2_pressed() -> void:
	sword_nodes.pop_back()
	get_tree().paused = false
	options.hide()


func _on_button_3_pressed() -> void:
	camera.max_scroll_speed = 300.0
	camera.speed *= 1.5
	get_tree().paused = false
	options.hide()


func _on_button_4_pressed() -> void:
	if level2.visible:
		points_int -= 250
	if level3.visible:
		points_int -= 500
	points_int /= 2
	points_frozen = true
	_update_points()
	get_tree().paused = false
	options.hide()
	await get_tree().create_timer(4.0).timeout
	points_frozen = false
	print("points unfrozen")

func _on_heart_contacted() -> void:
	print("connected to controller")
	_increment_lives()
