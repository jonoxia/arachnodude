extends KinematicBody2D
signal latch_web

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var velocity = Vector2.ZERO
var latched = false
var latched_object = null
var start_point_offset = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func init_projectile(pos, vel, start_point_offset):
	position = pos
	#print("Initing projectile with vel = " + vel)
	velocity = vel
	self.start_point_offset = start_point_offset

func latch_to_area(area):
	latched = true
	latched_object = area
	emit_signal("latch_web", self)
	velocity = Vector2.ZERO
	if not $ConnectSound.playing:
		$ConnectSound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# how do i detect if i have hit something?
	if not latched:
		var collision_info = move_and_collide(velocity, false)
		# false = not infinite inertia
		if collision_info:
			# send message to player
			if not $ConnectSound.playing:
				$ConnectSound.play()
			latched = true
			latched_object = collision_info.get_collider()
			emit_signal("latch_web", self)
			velocity = Vector2.ZERO
	if latched:
		get_node("CollisionShape2D").disabled = true
		if latched_object.is_class("RigidBody2D") or latched_object.is_class("KinematicBody2D"):
			self.global_position = latched_object.global_position
			# I think if we're gonna do this we have to turn off
			# collision between projectile and rigid body; it gets real weird
	
		
	var my_line = get_node("Line2D")
	var player = get_tree().get_root().get_child(0).get_node("Player") # Does this work in any level?
	my_line.points = []
	var arm
	if self.start_point_offset < 0:
		arm = player.get_node("LeftArmLine")
	else:
		arm = player.get_node("RightArmLine")

	var endpoint = arm.global_position + arm.get_points()[1]
	#var endpoint_x = player.global_position.x + self.start_point_offset
	#var endpoint_y = move_toward(player.global_position.y, self.global_position.y, 5)
	var relative_endpoint = endpoint - self.global_position
	
	my_line.add_point(Vector2(0,0))
	my_line.add_point(relative_endpoint)

