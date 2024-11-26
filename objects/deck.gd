extends Node2D

# This script manages the deck itself, handing out cards and the hawk logic

# Reference to flipped card object, used to create instances
var flipped_card_obj = preload("res://objects/flipped_card.tscn")

# SIGNALS - used to interface with other classes
signal ShuffleAnimationBegin()
signal ShuffleAnimationFinish()
signal CardDrawn()

# Initialisation variables
var cards_in_play: int = 0
var num_of_cards: int = 52
var jokers_in_play: bool = false 
var split_distance: float = 120.0 # Distance between cards on riffle split
var card_split_time: float = 0.4 # Decides shuffling animation lengths
var card_throw_speed: float = 0.09 # How fast the cards are shuffled during riffle
var card_array = [] # contains ALL card instances
 
var deck_y_offset = -190.0 # y-offset of the deck from the middle of screen

# Game variables
var shuffled_card_indices = [] # Contains a shuffled array of card values
var current_card_index = 0
var current_card_name = ""
var current_card_value = -1
var prev_card_value = -1
var bet_higher: bool = false # True if the player bet higher
var correct_bet: bool = true # True if the player chose higher or lower correctly
var hawk_assumes_higher: bool = false # True if hawk favours higher

func _ready():
	scale = Vector2(2.2, 2.2)
	InitialCardSetup()

func InitialCardSetup():
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
	
	# Initialise shuffled card deck
	for i in 56: # iterate through cards
		if i == 27 or i == 13: # Skip extra jokers (there are 4 in art, so skip 2)
			continue
		shuffled_card_indices.append(i) 

# Fisher Yates shuffle works by iterating through an array and swapping elements at random from the unprocessed subarray
func FisherYatesShuffle():
	for i in range(shuffled_card_indices.size() - 1, 0, -1):
		var j = randi() % (i + 1) # Random index
		
		# Swap cards
		var temp = shuffled_card_indices[i]
		shuffled_card_indices[i] = shuffled_card_indices[j]
		shuffled_card_indices[j] = temp

# Reset variables for game reset
func ResetCardsToInitial():
	for i in card_array:
		i.queue_free()
	
	card_array = []
	
	current_card_value = -1
	prev_card_value = -1
	current_card_index = 0
	
	InitialCardSetup()

# Riffle animation
func ShuffleAnimationStart():
	
	# Shuffle the cards
	FisherYatesShuffle() 
	num_of_cards = 54 if jokers_in_play else 52
	
	await get_tree().create_timer(0.7).timeout
	
	# Animate the two cards splitting to represent the whole deck being split
	var fc_inst_left = card_array[0]
	var fc_inst_right = card_array[1]

	var card_split_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	card_split_tween.tween_property(fc_inst_left, "position", Vector2(-split_distance, position.y), card_split_time)
	card_split_tween.parallel().tween_property(fc_inst_left, "scale", Vector2(scale.y / 1.7, scale.y), card_split_time)
	fc_inst_left.PlaySoundEffect(0)
	
	card_split_tween.parallel().tween_property(fc_inst_right, "position", Vector2(split_distance, position.y), card_split_time)
	card_split_tween.parallel().tween_property(fc_inst_right, "scale", Vector2(scale.y / 1.7, scale.y), card_split_time)
	card_split_tween.play()
	fc_inst_right.PlaySoundEffect(0)
	
	# Call the riffle animation recursively until all cards are animated
	card_split_tween.tween_callback(Callable(self, "ShuffleAnimationRecurse").bind(num_of_cards)).set_delay(0.25)
	
	Deck.ShuffleAnimationBegin.emit()
	cards_in_play = 0
	
# Card mixing (riffle) animation
func ShuffleAnimationRecurse(card_counter):
	
	if card_counter <= 0: # If finished, pull the outer two cards in and call the ending animation
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

	# Otherwise, instantiate cards and animate them being thrown into the middle to depict a riffle shuffle
	var shuffle_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	
	var fc_card_inst = flipped_card_obj.instantiate()
	get_tree().get_root().call_deferred("add_child", fc_card_inst)
	fc_card_inst.z_index = -1 # Spawn behind the card
	fc_card_inst.scale = scale
	card_array.append(fc_card_inst)
	
	var card_peek_error: float = 22.0 # Needed to avoid peek as left and right cards are scaled
	
	if card_counter % 2 == 0: #  Left
		fc_card_inst.position = Vector2(-(split_distance - card_peek_error), position.y)
	else:
		fc_card_inst.position = Vector2((split_distance - card_peek_error), position.y)
	
	shuffle_tween.tween_property(fc_card_inst, "position", Vector2(0 + randf_range(-2.0, 2.0), position.y + randf_range(-2.0, 2.0)), card_throw_speed)
	shuffle_tween.tween_property(fc_card_inst, "rotation_degrees", randf_range(-7.0, 7.0), card_throw_speed)
	shuffle_tween.play()
	fc_card_inst.call_deferred("PlaySoundEffect", 1)
	
	shuffle_tween.tween_callback(Callable(self, "ShuffleAnimationRecurse").bind(card_counter - 1)).set_delay(card_throw_speed)
	
# Pull all the cards back together and setup for play
func ShuffleAnimationEnd():
	var shuffle_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_parallel(true)
	
	for i in card_array.size():
		card_array[i].z_index = i # Card 0 would be at the bottom of the deck
		shuffle_tween.tween_property(card_array[i], "rotation_degrees", 0.0, card_split_time*2)
		shuffle_tween.tween_property(card_array[i], "position", Vector2(0, position.y + deck_y_offset + (0.2 * i)), card_split_time*2)
		
		if i == 0:
			card_array[i].PlaySoundEffect(1)
	
	shuffle_tween.play()
	Deck.ShuffleAnimationFinish.emit()
	
	await get_tree().create_timer(card_split_time * 4).timeout
	DrawNextCard() # Draw the first card
	
func DrawNextCard():
	
	if card_array.is_empty():
		return
	
	var card_draw_index = card_array.size() - cards_in_play - 1
	cards_in_play += 1
	var card_to_draw = card_array[card_draw_index]
	
	var pull_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	pull_tween.tween_property(card_to_draw, "position", Vector2(0, -0.2 * card_draw_index), card_split_time)
	pull_tween.play()
	
	pull_tween.tween_callback(Callable(self, "CardDrawAnimationEnd").bind(card_to_draw))
	
	var flip_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	flip_tween.tween_property(card_to_draw, "scale", Vector2(scale.x, 0), card_split_time / 2)
	flip_tween.play()
	flip_tween.tween_callback(Callable(self, "CardFlipAnimation").bind(card_to_draw))
	
	card_to_draw.PlaySoundEffect(0)

# Called in the middle of drawing the card from the deck to the pile
func CardDrawAnimationEnd(card_to_draw):
	# Need to flip z_index as we are taking from the bottom of the deck and putting on the top of the pile
	card_to_draw.z_index = -card_to_draw.z_index 

# Play after drawing the card from the deck to the pile
func CardFlipAnimation(card_to_draw):
	# Animate the card flipping from the deck to the pile
	var flip_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	flip_tween.tween_property(card_to_draw, "scale", Vector2(scale.x, scale.y), card_split_time / 2)
	flip_tween.play()
	
	var card_index = shuffled_card_indices[current_card_index]
	while !jokers_in_play and ((card_index + 1) % 14) == 0: # If jokers are not in play, and card index is a joker, skip
		current_card_index += 1
		card_index = shuffled_card_indices[current_card_index]
	
	card_to_draw.frame = card_index
	card_to_draw.card_value = ((card_index + 1) % 14) # Determine card value from index
	prev_card_value = current_card_value
	current_card_value = card_to_draw.card_value
	var suit = card_index / 14 # 14 cards in each suit
	var suit_name = ""
	var card_value_name = ""
	
	# Determine card name from suit and card values
	match suit:
		0:
			suit_name = "Hearts"
		1:
			suit_name = "Spades"
		2:
			suit_name = "Diamonds"
		3:
			suit_name = "Clubs"
	
	match current_card_value:
		1:
			card_value_name = "Ace"
		11:
			card_value_name = "Jack"
		12:
			card_value_name = "Queen"
		13:
			card_value_name = "King"
		0:
			card_value_name = "Joker"
		_:
			card_value_name = str(current_card_value)
	
	if card_value_name == "Joker":
		current_card_name = card_value_name
	else:
		current_card_name = card_value_name + " of " + suit_name
	
	current_card_index += 1
	
	# Hawk will assume higher if the current card value is less than or equal to 7.
	# Could potentially improve hawk's esimates by looking at cards already played and getting a statistic
	hawk_assumes_higher = current_card_value <= 7
	
	# Determine if player chose the correct higher or lower
	if current_card_value == 0: # Joker, auto loss
		correct_bet = false
	if current_card_value == prev_card_value: # Same card value, correct
		correct_bet = true
	elif current_card_value > prev_card_value:
		correct_bet = bet_higher
	else:
		correct_bet = !bet_higher
	
	await get_tree().create_timer(card_split_time).timeout
	
	Deck.CardDrawn.emit()
	
