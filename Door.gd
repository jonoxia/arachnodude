extends Area2D

var num_getter_regex
var next_level_name
onready var my_text = $RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Door ready")
	connect("body_entered", self, "_on_Door_body_entered")
	num_getter_regex = RegEx.new()
	num_getter_regex.compile("(\\d+)")
	
	var current_level_name = get_tree().get_root().get_child(0).name
	if current_level_name == "Tutorial Level":
		next_level_name = "Level 0"
	else:
		var result = num_getter_regex.search(current_level_name)
		if result:
			var level_number = int(result.get_string())
			var next_level_number = level_number + 1
			next_level_name = "Level %s" % str(next_level_number)


func _on_Door_body_entered(body):
	var player = get_tree().get_root().get_child(0).get_node("Player")
	var cat = get_tree().get_root().get_child(0).get_node("Cat")
	# TODO: change this to "all the cats"
	# maybe put a countdown over the door showing how many cats remaining
	if overlaps_body(player) and overlaps_body(cat):
		cat.purr()
		win_level()

func win_level():
	var current_level_name = get_tree().get_root().get_child(0).name
	print("Going from %s to %s" % [current_level_name, next_level_name])
	
	my_text.text = "YOU DID IT!"
	my_text.visible = true
	my_text.set("custom_colors/default_color", Color(0,0,0))
	
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.connect("timeout", self, "_on_timer_timeout")
	timer.start()
	
	# the godot 4 verison would be like: await get_tree().create_timer(1.0).timeout
	
func _on_timer_timeout():
	get_tree().change_scene("res://%s.tscn" % next_level_name)

