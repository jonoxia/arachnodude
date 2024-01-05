extends KinematicBody2D

var velocity = Vector2.ZERO
var direction = 1 # 1 for right and -1 for left
onready var ledge_check_left = $LeftRayCast
onready var ledge_check_right = $RightRayCast
onready var my_sprite = $AnimatedSprite

var is_latched = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = get_tree().get_root().get_child(0).get_node("Player")
	# Listen for the player to latch me
	player.connect("latch_object", self, "_get_latched")
	player.connect("unlatch_object", self, "_get_unlatched")
	if not $SadMeow.playing:
		$SadMeow.play()

func _physics_process(delta):
	
	velocity.y += delta*100
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_floor() and not self.is_latched:
		if is_on_wall():
			direction *= -1
		elif not ledge_check_left.is_colliding():
			direction = 1
		elif not ledge_check_right.is_colliding():
			direction = -1
			

		velocity.x = move_toward(velocity.x, 50*direction, 20)
	
	#if not is_on_floor() and not self.is_latched:
	#	# gravity only when not webbed
	#	velocity.y += 4

	
	if self.is_latched:
		my_sprite.play("yellow_dragged")
	elif velocity.x < 0:
		my_sprite.play("yellow_walk_left")
	else:
		my_sprite.play("yellow_walk_right")
	
func _get_latched(latched_object):
	if latched_object == self:
		if not $AngryMeow.playing:
			$AngryMeow.play()
		self.is_latched = true
		#self.get_node("CollisionShape2D").disabled = true
		# Try disabling collision with walls but not disabling collision with player,
		# see how that is.

func _get_unlatched(latched_object):
	if latched_object == self:
		self.is_latched = false
		#self.get_node("CollisionShape2D").disabled = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func purr():
	if not $Purr.playing:
		$Purr.play()
