extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_GrabbableArea_body_entered")


func _on_GrabbableArea_body_entered(body):
	var player = get_tree().get_root().get_child(0).get_node("Player")

	if not overlaps_body(player):
		if body.name == "Projectile":
			# trigger the projectile method as if it had hit a body
			body.latch_to_area(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
