extends CanvasLayer

# Game state variables
var is_game_start: bool = false
var is_shuffling: bool = false
var can_choose_horl: bool = false
var can_reset_game: bool = false
var times_played: int = 0
var jokers_enabled: bool = false

# UI text variables
var bet_string: String = ""
var valid_color = "[color=#00FF00]"
var invalid_color = "[color=#FF0000]"
var nums_after_decimal = 0 # How many numbers are after the decimal - used to limit to 2
var in_decimal = false # True if the bet input is after decimal point
var is_valid_bet = false # True if the bet is a valid number and less than balance

# Player stats variables
var current_balance: float = 1500
var current_bet: float = 0
var current_winnings: float = 0

func _ready():
	Deck.ShuffleAnimationBegin.connect(ShuffleAnimationBegin)
	Deck.ShuffleAnimationFinish.connect(ShuffleAnimationFinish)
	Deck.CardDrawn.connect(CardDrawn)
	UpdateBetString()
	
# Process functions are run every frame
func _process(_delta):
	
	if can_reset_game: # Game Reset logic
		if Input.is_action_just_pressed("QButton"):
			can_reset_game = false
			Deck.ResetCardsToInitial()
			
			is_game_start = false
			times_played += 1
			current_bet = 0
			current_winnings = 0
			bet_string = ""
			nums_after_decimal = 0
			in_decimal = false
			is_valid_bet = false
			UpdateBetString()
	else:
		if not is_game_start:
			# Main Menu Controls
			if Input.is_action_just_pressed("AcceptButton"):
				if is_valid_bet: # Start the game if the bet is valid
					current_balance -= current_bet
					UpdateBalanceString()
					
					Deck.jokers_in_play = jokers_enabled
					
					Deck.ShuffleAnimationStart()
					SetActionText(true, "")
					is_game_start = true
					$PlaceBetSFX.play()
			
			# Input sanitization to avoid more than two decimal point numbers for the bet
			if !in_decimal or (in_decimal and nums_after_decimal < 2):
				for i in range(10):  # Check keys 0 to 9
					if Input.is_action_just_pressed("key" + str(i)):
						bet_string = bet_string + str(i)
						if in_decimal:
							nums_after_decimal += 1
						UpdateBetString()
						$BlipSFX.pitch_scale = randf_range(0.9, 1.1)
						$BlipSFX.play()
			
			# Placing the decimal point
			if !in_decimal and Input.is_action_just_pressed("Decimal"):
				in_decimal = true
				bet_string = bet_string + "."
				nums_after_decimal = 0
				UpdateBetString()
				$BlipSFX.pitch_scale = randf_range(0.9, 1.1)
				$BlipSFX.play()
			
			# Deleting characters from the bet
			if Input.is_action_just_pressed("Delete") and bet_string != "":
				
				var rem_char = bet_string[bet_string.length() - 1]
				if rem_char == ".":
					in_decimal = false
					nums_after_decimal = 0
				elif in_decimal:
					nums_after_decimal -= 1
				
				bet_string = bet_string.substr(0, bet_string.length() - 1)
				UpdateBetString()
				$DeclineSFX.pitch_scale = randf_range(0.9, 1.1)
				$DeclineSFX.play()
			
			# Joker toggle
			if Input.is_action_just_pressed("TButton"):
				jokers_enabled = !jokers_enabled
				UpdateBetString()
				$BlipSFX.pitch_scale = randf_range(0.7, 0.8)
				$BlipSFX.play()
					
				
		elif can_choose_horl: # If not in menu (is in game)
			if Deck.cards_in_play == Deck.num_of_cards: # Cash out if reached end of deck
				CashOut()
			elif Input.is_action_just_pressed("QButton"):
				Deck.bet_higher = false
				DrawCardUpdate()
			elif Input.is_action_just_pressed("EButton"):
				Deck.bet_higher = true
				DrawCardUpdate()
			elif Input.is_action_just_pressed("TButton") and Deck.cards_in_play > 1:
				CashOut()

# Update the action text in the main menu whenever the bet changes
func UpdateBetString():
	if bet_string == "":
		is_valid_bet = false
	else:
		is_valid_bet = bet_string.is_valid_float() && bet_string.to_float() <= current_balance
		if is_valid_bet:
			current_bet = bet_string.to_float()
	
	var joker_enabled_string = "[color=#00FF00]ENABLED[color=white])" if jokers_enabled else "[color=#FF0000]DISABLED[color=white])" 
	
	SetActionText(false, "Welcome to Hawk's Card Gambit!", "","Input a bet: "+ (valid_color if is_valid_bet else invalid_color) + "£" + bet_string, 
					"Press T to toggle JOKERS (Auto Loss, " + joker_enabled_string,"Press ENTER to BEGIN")

# Update player balance text to show bet, winnings and balance
func UpdateBalanceString():
	$PlayerText.text = "[color=white]Balance: £" + format_to_2dp(current_balance) + "\nBet: £" + format_to_2dp(current_bet) + "\n[color=#00FF00]Winnings: £" + format_to_2dp(current_winnings)

# Reset action text whenever a card is drawn
func DrawCardUpdate():
	SetActionText(false, "")
	can_choose_horl = false
	Deck.DrawNextCard()
 
# Cash out - add winnings to balance and display on UI
func CashOut():
	can_choose_horl = false
	
	var winnings = float(format_to_2dp(current_winnings + current_bet))
	var winnings_text = "You won £" + format_to_2dp(current_winnings + current_bet)
	current_balance += float(format_to_2dp(current_winnings + current_bet))
	current_winnings = 0
	current_bet = 0
	UpdateBalanceString()
	
	$JackpotSFX.play()
	
	SetActionText(true, "Cashing Out!")
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Cashing Out!", winnings_text)
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Cashing Out!", winnings_text, "Thanks for playing!")
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Cashing Out!", winnings_text, "Thanks for playing!", "Press Q to return to the Main Menu")
	
	can_reset_game = true

# Shuffling loading text
func ShuffleAnimationBegin():
	is_shuffling = true
	
	while(is_shuffling):
		SetActionText(false, "Shuffling.")
		await get_tree().create_timer(1).timeout
		if not is_shuffling:
			return
		
		SetActionText(false, "Shuffling..")
		await get_tree().create_timer(1).timeout
		if not is_shuffling:
			return
		
		SetActionText(false, "Shuffling...")
		await get_tree().create_timer(1).timeout
		if not is_shuffling:
			return
		

func ShuffleAnimationFinish():
	is_shuffling = false
	SetActionText(false, "")

# Called every time a card is drawn from the pile via signal
func CardDrawn():
	if (Deck.cards_in_play == 1 or Deck.correct_bet) and Deck.current_card_name != "Joker": # If the player is in betting stages
		
		# UI text update based on hawk decisions
		var hawk_favour_text = "Hawk favours: [color=#FF6600]" + ("HIGHER" if Deck.hawk_assumes_higher else "LOWER")
		var press_q_text = "Press Q for LOWER[color=#FF6600] (x2)" if Deck.hawk_assumes_higher else "Press Q for LOWER"
		var press_e_text = "Press E for HIGHER" if Deck.hawk_assumes_higher else "Press E for HIGHER[color=#FF6600] (x2)"
		
		SetActionText(true, Deck.current_card_name)
		
		# Calculate winnings if correct bet
		if Deck.cards_in_play > 1:
			var mult = (Deck.bet_higher and !Deck.hawk_assumes_higher) or (!Deck.bet_higher and Deck.hawk_assumes_higher)
			current_winnings += (current_bet + current_winnings) * 0.08 * (2 if mult else 1) * (1.8 if Deck.jokers_in_play else 1)
		UpdateBalanceString()
		
		await get_tree().create_timer(1).timeout
		SetActionText(true, Deck.current_card_name, hawk_favour_text)
		await get_tree().create_timer(1).timeout
		
		# Show tutorial if first game
		if Deck.cards_in_play > 1:
			SetActionText(true, Deck.current_card_name, hawk_favour_text, press_q_text, press_e_text, "Press T to CASH OUT")
		else:
			if times_played == 0:
				SetActionText(true, Deck.current_card_name, hawk_favour_text, press_q_text, press_e_text, "[u]How to play[/u]:\nThe hawk will favour the most likely outcome.\nVote against the hawk for a multiplier!")
			else:
				SetActionText(true, Deck.current_card_name, hawk_favour_text, press_q_text, press_e_text)
			
		can_choose_horl = true
	else: # Incorrect bet, reset winnings
		SetActionText(true, Deck.current_card_name)
		
		current_bet = 0
		current_winnings = 0
		
		UpdateBalanceString()
		$LoseSFX.play()
		await get_tree().create_timer(1).timeout
		SetActionText(true, Deck.current_card_name, "You Lose!")
		await get_tree().create_timer(1).timeout
		SetActionText(true, Deck.current_card_name, "You Lose!", "Press Q to return to the Main Menu")
		
		can_reset_game = true

# Updating the action text (UI text) based on passed arguments
func SetActionText(playsfx, main_text, subtitle_text = "", actionAtext = "", actionBtext = "", actionCtext = ""):
	if playsfx:
		$UISFX.pitch_scale = randf_range(0.9, 1.1)
		$UISFX.play()
	
	$ActionText.text = ("[center]" + main_text + 
	("" if subtitle_text =="" else "\n[color=white]" + subtitle_text ) +
	"\n\n[color=white]" + actionAtext + "\n[color=white]" + actionBtext + "\n\n[color=white]" + actionCtext)

func format_to_2dp(value: float) -> String:
	var rounded_value = round(value * 100) / 100.0
	var formatted_value = str("%0.2f" % rounded_value)
	
	# Check if it's an integer
	if rounded_value == int(rounded_value):
		return str(int(rounded_value))
	return formatted_value
