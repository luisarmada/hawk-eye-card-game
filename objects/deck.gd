extends Node2D

var flipped_card_obj = preload("res://objects/flipped_card.tscn")

var num_of_cards: int = 52
var split_distance: float = 130.0
var card_split_time: float = 0.4
var card_throw_speed: float = 0.09
var card_array = []
 
var deck_y_offset = -190.0

func _ready():
	
	ShuffleAnimationStart()
	
func _process(_delta):
	if(Input.is_action_just_pressed("DEBUG")):
		CardDrawAnimationStart()

# Riffle animation
func ShuffleAnimationStart():
	
	# Instantiate flipped card objects for left and right halves
	var fc_inst_left = flipped_card_obj.instantiate()
	get_tree().get_root().call_deferred("add_child", fc_inst_left)
	fc_inst_left.position = position
	fc_inst_left.scale = scale
	card_array.append(fc_inst_left)
	
	var fc_inst_right = flipped_card_obj.instantiate()
	get_tree().get_root().call_deferred("add_child", fc_inst_right)
	fc_inst_right.position = position
	fc_inst_right.scale = scale
	card_array.append(fc_inst_right)
	
	await get_tree().create_timer(0.7).timeout
	# Animate the two cards splitting to represent the whole deck being split
	

	var card_split_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	card_split_tween.tween_property(fc_inst_left, "position", Vector2(-split_distance, position.y), card_split_time)
	card_split_tween.parallel().tween_property(fc_inst_left, "scale", Vector2(scale.y / 1.7, scale.y), card_split_time)
	fc_inst_left.PlaySoundEffect(0)
	
	card_split_tween.parallel().tween_property(fc_inst_right, "position", Vector2(split_distance, position.y), card_split_time)
	card_split_tween.parallel().tween_property(fc_inst_right, "scale", Vector2(scale.y / 1.7, scale.y), card_split_time)
	card_split_tween.play()
	fc_inst_right.PlaySoundEffect(0)
	
	card_split_tween.tween_callback(Callable(self, "ShuffleAnimationRecurse").bind(num_of_cards)).set_delay(0.25)
	
# Card mixing animation
func ShuffleAnimationRecurse(card_counter):
	
	if card_counter <= 0:
		await get_tree().create_timer(0.45).timeout
		var shuffle_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	
		for i in 2:
			shuffle_tween.tween_property(card_array[i], "position", Vector2(0 + randf_range(-2.0, 2.0), position.y + randf_range(-2.0, 2.0)), card_split_time)
			shuffle_tween.tween_property(card_array[i], "rotation_degrees", randf_range(-7.0, 7.0), card_split_time)
			shuffle_tween.tween_property(card_array[i], "scale", scale, card_split_time)
			card_array[i].PlaySoundEffect(0)
	
		shuffle_tween.play()
		
		shuffle_tween.tween_callback(Callable(self,"ShuffleAnimationEnd")).set_delay(0.45)
		return

	var shuffle_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	
	var fc_card_inst = flipped_card_obj.instantiate()
	get_tree().get_root().call_deferred("add_child", fc_card_inst)
	fc_card_inst.z_index = -1 # Spawn behind the card
	fc_card_inst.scale = scale
	card_array.append(fc_card_inst)
	
	var card_peek_error: float = 22.0
	
	if card_counter % 2 == 0: #  Left
		fc_card_inst.position = Vector2(-(split_distance - card_peek_error), position.y)
	else:
		fc_card_inst.position = Vector2((split_distance - card_peek_error), position.y)
	
	
	shuffle_tween.tween_property(fc_card_inst, "position", Vector2(0 + randf_range(-2.0, 2.0), position.y + randf_range(-2.0, 2.0)), card_throw_speed)
	shuffle_tween.tween_property(fc_card_inst, "rotation_degrees", randf_range(-7.0, 7.0), card_throw_speed)
	shuffle_tween.play()
	fc_card_inst.call_deferred("PlaySoundEffect", 1)
	
	shuffle_tween.tween_callback(Callable(self, "ShuffleAnimationRecurse").bind(card_counter - 1)).set_delay(card_throw_speed)

func ShuffleAnimationEnd():
	var shuffle_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	
	for i in card_array.size():
		card_array[i].z_index = i # Card 0 would be at the bottom of the deck
		shuffle_tween.tween_property(card_array[i], "rotation_degrees", 0.0, card_split_time*2)
		shuffle_tween.tween_property(card_array[i], "position", Vector2(0, position.y + deck_y_offset + (0.2 * i)), card_split_time*2)
		
		if i == 0:
			card_array[i].PlaySoundEffect(1)
	
	shuffle_tween.play()
	
func CardDrawAnimationStart():
	
	if card_array.is_empty():
		return
	
	var card_draw_index = card_array.size() - 1
	var card_to_draw = card_array.pop_back()
	
	var pull_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	pull_tween.tween_property(card_to_draw, "position", Vector2(0, -0.2 * card_draw_index), card_split_time)
	pull_tween.play()
	
	pull_tween.tween_callback(Callable(self, "CardDrawAnimationEnd").bind(card_to_draw))
	
	var flip_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	flip_tween.tween_property(card_to_draw, "scale", Vector2(scale.x, 0), card_split_time / 2)
	flip_tween.play()
	flip_tween.tween_callback(Callable(self, "CardFlipAnimation").bind(card_to_draw))
	
	card_to_draw.PlaySoundEffect(0)
	
func CardDrawAnimationEnd(card_to_draw):
	card_to_draw.z_index = -card_to_draw.z_index

func CardFlipAnimation(card_to_draw):
	var flip_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	flip_tween.tween_property(card_to_draw, "scale", Vector2(scale.x, scale.y), card_split_time / 2)
	flip_tween.play()
	
	card_to_draw.frame = randi_range(0, 55)
	
