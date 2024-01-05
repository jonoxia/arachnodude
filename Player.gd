extends KinematicBody2D
signal latch_object
signal unlatch_object

var velocity = Vector2.ZERO
#onready var target_lock = get_node("TargetingLockSprite")
onready var _animated_sprite = $AnimatedSprite
onready var _right_arm = $RightArmLine
onready var _left_arm = $LeftArmLine
onready var _wall_check_left = $LeftRayCast
onready var _wall_check_right = $RightRayCast
var min_web_dist = 35

var left_projectile = null
var right_projectile = null

var left_latched_object = null
var right_latched_object = null

var LEFT = 1
var RIGHT = 2

var is_on_floor_countdown = 0

var current_facing = RIGHT
var current_web_direction = Vector2.ZERO
# Called when the node enters the scene tree for the first time.
var thunk_sound_countdown = 100
var thunk_sound_can_play = false


func _ready():
	
	pass # Replace with function body.

func _physics_process(delta):
	
	var input = Vector2.ZERO;
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input.x < 0:
		current_facing = RIGHT
	elif input.x > 0:
		current_facing = LEFT # everything is backwards for some reason?
	
	if left_projectile == null and Input.is_mouse_button_pressed(BUTTON_LEFT):
		launch_projectile(LEFT)
	elif not Input.is_mouse_button_pressed(BUTTON_LEFT):
		cancel_projectile(LEFT)
		aim_projectile()
		
	if right_projectile == null and Input.is_mouse_button_pressed(BUTTON_RIGHT):
		launch_projectile(RIGHT)
	elif not Input.is_mouse_button_pressed(BUTTON_RIGHT):
		cancel_projectile(RIGHT)
		aim_projectile()
	
	if is_on_floor():
		is_on_floor_countdown = 5
	elif is_on_floor_countdown > 0:
		is_on_floor_countdown -= 1

	if is_on_wall() or is_on_ceiling() or is_on_floor():
		thunk_sound_countdown = 15
		if thunk_sound_can_play:
			if not $ThunkSound.playing:
				$ThunkSound.play()
				thunk_sound_can_play = false
		if input.x == 0 and input.y == 0:
			apply_ground_friction()
		else:
			apply_ground_acceleration(input.x, input.y)
	#if Input.is_action_just_pressed("ui_up") and is_on_wall():
	#	velocity.y = -120
	else:
		if input.x == 0:
			#apply_air_friction()
			pass
		else:
			apply_air_acceleration(input.x, 0)
		apply_gravity()
		if thunk_sound_countdown > 0:
			thunk_sound_countdown -=1
			if thunk_sound_countdown == 0:
				thunk_sound_can_play = true
		
	$RichTextLabel.text = str(thunk_sound_can_play) + "/" + str(thunk_sound_countdown)
	
	
	apply_web_pull(left_latched_object, left_projectile)
	apply_web_pull(right_latched_object, right_projectile)

	velocity = move_and_slide(velocity, Vector2.UP, false, 4, PI/4, false)
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_class("RigidBody2D"):
			# could be ".is_in_group()"
			collision.collider.apply_central_impulse(-collision.normal * 50)
			
	# Choose animation frames to use:
	decide_animation()
	# choose arm sprites based on web direction:
	#_left_arm.play( decide_left_arm())
	#_right_arm.play( decide_right_arm())
	decide_left_arm()
	decide_right_arm()
	
func decide_left_arm():
	return decide_an_arm(_left_arm, left_latched_object, left_projectile, current_web_direction, -1)
	
func decide_right_arm():
	return decide_an_arm(_right_arm, right_latched_object, right_projectile, current_web_direction, 1)
	
func decide_an_arm(arm_sprite, latched_object, projectile, curr_web_dir, x_offset):
	var dir
	# Note: don't use latched_object to decide where your arm is pointing, because
	# if you latch the tilemap its global_position is always (0,0)
	if projectile != null:
		dir = self.global_position.direction_to(projectile.global_position)
	else:
		# Special case: curr_web_dir if it is on my side of the body, otherwise down.
		if x_offset < 0 and curr_web_dir.x < 0:
			dir = curr_web_dir
		elif x_offset > 0 and curr_web_dir.x > 0:
			dir = curr_web_dir
		elif x_offset < 0 and (right_latched_object != null or right_projectile != null):
			dir = curr_web_dir
		elif x_offset > 0 and (left_latched_object != null or left_projectile != null):	
			dir = curr_web_dir
		else:
			# Other special case: if the OTHER arm is latched to something (i.e. only
			# this arm is free to turn) point it at curr_web_dir, not down.
			dir = Vector2(0, 1)
		
	
		
	if is_on_wall() or is_on_ceiling():
		arm_sprite.visible = false
	else:
		arm_sprite.visible= true
		
	arm_sprite.points = []
	var shoulder_point = Vector2.ZERO
	arm_sprite.add_point(shoulder_point)
	var hand_point = shoulder_point + dir * 15
	arm_sprite.add_point(hand_point)
	
	var arm_outline = arm_sprite.get_child(0)
	arm_outline.points = []
	arm_outline.add_point(shoulder_point)
	arm_outline.add_point( shoulder_point + dir * 16)
	
func decide_animation():
	var is_on_left_wall = is_on_wall() and _wall_check_right.is_colliding()
	var is_on_right_wall = is_on_wall() and _wall_check_left.is_colliding()
	# Note the above 2 lines are intentionally swapped: everythng's backwards for some
	# reason and this corrects it.
	if is_on_left_wall and abs(velocity.y) > 5:
		# TODO: can i distinguish when is_on_wall() is true because i'm touching
		# another KinematicBody2D (i.e. a cat) and not do the climbing animation in
		# that case?  i don't want to climb the cat
		_animated_sprite.play("climb left")
	elif is_on_left_wall:
		_animated_sprite.play("idle climb left")
	elif is_on_right_wall and abs(velocity.y) > 5:
		_animated_sprite.play("climb right")
	elif is_on_right_wall:
		_animated_sprite.play("idle climb right")
	elif is_on_ceiling() and current_facing == LEFT:
		_animated_sprite.play("ceiling left")
	elif is_on_ceiling() and current_facing == RIGHT:
		_animated_sprite.play("ceiling right")
	elif is_on_floor_countdown > 0 and abs(velocity.x) < 10:
		# TODO is_on_floor() seems to rapidly oscillate unless i'm holding down.
		# is there a "sufficiently near floor" setting?
		_animated_sprite.play("stand down")
	elif is_on_floor_countdown > 0 and current_facing == LEFT:
		_animated_sprite.play("walk left")
	elif is_on_floor_countdown > 0 and current_facing == RIGHT:
		_animated_sprite.play("walk right")
	elif is_on_wall() and current_facing == LEFT:
		_animated_sprite.play("climb left")
	elif is_on_wall() and current_facing == RIGHT:
		_animated_sprite.play("climb right")
	elif current_facing == LEFT:
		_animated_sprite.play("jump left")
	elif current_facing == RIGHT:
		_animated_sprite.play("jump right")
	
func apply_gravity():
	velocity.y += 4
	if is_on_floor():
		velocity.y = 0
		# This was supposed to stop the flickering of is_on_floor, but it does not
	
func apply_ground_friction():
	velocity.x = move_toward(velocity.x, 0, 10)
	velocity.y = move_toward(velocity.y, 0, 10)
	
func apply_ground_acceleration(amountx, amounty):
	velocity.x = move_toward(velocity.x, 50*amountx, 20)
	velocity.y = move_toward(velocity.y, 50*amounty, 20)		

func apply_air_friction():
	velocity.x = move_toward(velocity.x, 0, 4)
	#velocity.y = move_toward(velocity.y, 0, 4)
	
func apply_air_acceleration(amountx, amounty):
	velocity.x = move_toward(velocity.x, 100*amountx, 5)
	#velocity.y = move_toward(velocity.y, 100*amounty, 10)		

func apply_web_pull(latched_object, projectile):
	# We have a choice here between pulling to left projectile position
	# and pulling to latched object position. For an object that's like
	# "large wall chunk" we want projectile position for accuracy.
	# For RigidBody2Ds we want latched object position because it will be changing
	
	if latched_object != null:
		var pull_d
		var force_on_me
		
		if latched_object.is_class("RigidBody2D") or latched_object.is_class("KinematicBody2D"):
			pull_d = self.global_position.direction_to(latched_object.global_position)
			# OK if we're using global position of the latched object to calculate direction
			# then why does it seem to matter a lot where exactly the projectile hits the 
			# rigid body???
			
			# How come sometimes it seems to push instead of pulling?
			force_on_me = 4 * pull_d
			var force_on_it = -8 * pull_d
			# TODO it doesn't seem to be able to overcome ground friction? but if it's
			# already in motion i can grab it easily?
			if self.global_position.distance_to(latched_object.global_position) > 20:
				if latched_object.is_class("RigidBody2D"):
					latched_object.apply_central_impulse(force_on_it)
				else:
					latched_object.velocity += force_on_it
			# TODO should i be applying this impulse just once or every frame?
			# TODO: implement "F=ma"
			# TODO: it appears 
		else:
			pull_d = self.global_position.direction_to(projectile.global_position)
			force_on_me = 10 * pull_d

		velocity.x += force_on_me.x
		velocity.y += force_on_me.y

func handle_latch(projectile):
	
	if projectile == self.left_projectile:
		left_latched_object = projectile.latched_object
		
	if projectile == self.right_projectile:
		right_latched_object = projectile.latched_object

	emit_signal("latch_object", projectile.latched_object)
	#if left_projectile != null:
	#	left_projectile._latch_spring(self)
	
	#if reeling_in_left == false and left_latched_object.is_class("RigidBody2D"):
	#	var pull_d = self.global_position.direction_to(left_latched_object.global_position)
	#	var force_on_it = -5 * pull_d
	#	if self.global_position.distance_to(left_latched_object.global_position) > 20:
	#		left_latched_object.apply_central_impulse(force_on_it)

func aim_projectile():
	var mouse_pos = get_local_mouse_position()
	current_web_direction = Vector2.ZERO.direction_to(mouse_pos)
	#target_lock.position = current_web_direction * min_web_dist
	
func launch_projectile(which_hand):
	var projectile_scene = load("res://Projectile.tscn")
	if not $ThwipSound.playing:
		$ThwipSound.play()
	
	var new_projectile = projectile_scene.instance()
	var proj_vel = current_web_direction * 10
	var debugstr = "Initing projectile with pos.x = {posx}, pos.y = {posy}, vel.x={velx}, vel.y={vely}"
	#print(debugstr.format( {"posx": target_lock.position.x,
	#						"posy":  target_lock.position.y,
	#						"velx": proj_vel.x,
	#						"vely": proj_vel.y}))
	var start_point_offset
	if which_hand == LEFT:
		start_point_offset = -5
	if which_hand == RIGHT:
		start_point_offset = 5
	new_projectile.init_projectile(self.global_position, proj_vel, start_point_offset)
	var world = get_parent()
	world.add_child(new_projectile)
	new_projectile.connect("latch_web",self,"handle_latch")
	if which_hand == LEFT:
		left_projectile = new_projectile
	elif which_hand == RIGHT:
		right_projectile = new_projectile
	# And only allow 2 of them to exist at a time?
	#current_web_dist += 20
	#current_web_dist = min(current_web_dist, max_web_dist)
	
func cancel_projectile(which_hand):
	var world = get_parent()
	if which_hand == LEFT:
		if left_projectile != null:
			# could do this on a release button event too
			#left_projectile.unlatch_spring()
			world.remove_child(left_projectile)
			left_projectile.free()
			left_projectile = null
		if left_latched_object != null:
			emit_signal("unlatch_object", left_latched_object)
			left_latched_object = null
	elif which_hand == RIGHT:
		if right_projectile != null:
			# could do this on a release button event too
			#left_projectile.unlatch_spring()
			world.remove_child(right_projectile)
			right_projectile.free()
			right_projectile = null
		if right_latched_object != null:
			emit_signal("unlatch_object", left_latched_object)
			right_latched_object = null




# TODO LIST:
# (Done) - draw web line as coming from player's hand
# (Done) - animate player walk and climb cycles
# (Done) - don't let player and cat fly by standing on each other
# (Done) - try allowing cat to pass through player
# (Done) - try allowing hooked cat to pass through platforms
#      - OK this leads to cat getting stuck under or inside the floor
# (Done) - don't go into climb animation when touching cat
# (Done) - cat sometimes gets weirdly stuck when it bumps a wall? should be turning around?
# - cat spritesheet animation frames slightly misaligned?
# - make some better levels
# - make a title screen art
# (Done) - my arms don't always connect to my body
# (Exported to HTML5 just fine) - try export features and figure out how to share this
# (Done)- try implementing slopes (might improve level design)
# (Done)- try implementing pass-through platforms (ditto)
# (Done) - try implementing things that can be hooked but don't block plaer movement (trees?)
# - climb animation with one arm touching wall and the other free to move, use this when
#     hanging onto a wall and shooting web  (let both arms anchor on the side away from wall)
# (Done) - climb idle animation
# - crawl across ceiling animation
# - cat rematerializes when you let go of it and it can rematerialize inside a solid surface this wway
#     i think i want cat to go AROUND CORNERS not through walls.

# - restart level if you or the cat fall off the level or get stuck somehow
# (Done) - add background image
#    - parallax scroll the background image?
# (Done) - choose left or right climb animation based on which side the wall is on	

# - Sushu suggestion: once you web a cat, it moves through walls until it contacts you,
# then stops next to you, even if you let go first.

# - Cat have speech balloons that say "Help me!" or "Purrr" or whatever
# - Start the level by having a "MEOW" speech balloon come from off the edge of
# the screen in the direction of the cat so you know where to go
# - Cat have more behavior such as stopping to lick its paws or meow or whatever
# - Player shows jumping and not clibing animation when at the top of a wall
# - Victory sound effect that plays when you get to the door
# (Done) - Cat velocity doesn't re-normalize after it goes back to walking mode
# (Done) - Slopes make levels much more forgiving BUT a cat won't stay on a platofrm with
# sloped edges.
# - new tutorial level: start with cat rescue (from tree?)
# - should be able to web a one-way platform from below???
