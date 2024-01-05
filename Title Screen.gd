extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Tutorial_Button_pressed():
	get_tree().change_scene("res://Tutorial Level.tscn")
	


func _on_First_Level_Button_pressed():
	get_tree().change_scene("res://Level 4.tscn")
