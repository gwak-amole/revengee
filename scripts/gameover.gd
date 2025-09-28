extends Node2D

@onready var points := $points/Panel/Label

func _ready():
	points.text = str(Globals.points)


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainscreen.tscn")
