extends CanvasLayer

var is_game_start: bool = false
var is_shuffling: bool = false
var can_choose_horl: bool = false

var can_reset_game: bool = false
var times_played: int = 0

func _ready():
	Deck.ShuffleAnimationBegin.connect(ShuffleAnimationBegin)
	Deck.ShuffleAnimationFinish.connect(ShuffleAnimationFinish)
	Deck.CardDrawn.connect(CardDrawn)
	SetActionText(false, "Welcome to Hawk's Card Gambit!", "","Input a bet: £______", "Press T to allow JOKERS (Auto Loss)","Press ENTER to BEGIN")
	
func _process(_delta):
	
	if can_reset_game:
		if Input.is_action_just_pressed("QButton"):
			can_reset_game = false
			Deck.ResetCardsToInitial()
			SetActionText(false, "Welcome to Hawk's Card Gambit!", "","Input a bet: £______", "Press T to allow JOKERS (Auto Loss)","Press ENTER to BEGIN")
			is_game_start = false
			times_played += 1
	else:
		if not is_game_start:
			if Input.is_action_just_pressed("AcceptButton"):
				Deck.ShuffleAnimationStart()
				SetActionText(true, "")
				is_game_start = true
		elif can_choose_horl:
			if Deck.cards_in_play == Deck.num_of_cards:
				CashOut()
			elif Input.is_action_just_pressed("QButton"):
				DrawCardUpdate()
			elif Input.is_action_just_pressed("EButton"):
				DrawCardUpdate()
			elif Input.is_action_just_pressed("TButton") and Deck.cards_in_play > 1:
				CashOut()

func DrawCardUpdate():
	SetActionText(false, "")
	can_choose_horl = false
	Deck.DrawNextCard()

func CashOut():
	can_choose_horl = false
		
	SetActionText(true, "Cashing Out!")
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Cashing Out!", "You won £100.")
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Cashing Out!", "You won £100.", "Thanks for playing!")
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Cashing Out!", "You won £100.", "Thanks for playing!", "Press Q to return to the Main Menu")
	
	can_reset_game = true

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

func CardDrawn():
	SetActionText(true, "Jack of Spades")
	
	await get_tree().create_timer(1).timeout
	SetActionText(true, "Jack of Spades", "Hawk favours: [color=#FF6600]HIGHER")
	await get_tree().create_timer(1).timeout
	
	if Deck.cards_in_play > 1:
		SetActionText(true, "Jack of Spades", "Hawk favours: [color=#FF6600]HIGHER","Press Q for LOWER[color=#FF6600] (x2)", "Press E for HIGHER", "Press T to CASH OUT")
	else:
		if times_played == 0:
			SetActionText(true, "Jack of Spades", "Hawk favours: [color=#FF6600]HIGHER","Press Q for LOWER[color=#FF6600] (x2)", "Press E for HIGHER", "[u]How to play[/u]:\nThe hawk will favour the most likely outcome.\nVote against the hawk for a multiplier!")
		else:
			SetActionText(true, "Jack of Spades", "Hawk favours: [color=#FF6600]HIGHER","Press Q for LOWER[color=#FF6600] (x2)", "Press E for HIGHER")
		
	can_choose_horl = true

func SetActionText(playsfx, main_text, subtitle_text = "", actionAtext = "", actionBtext = "", actionCtext = ""):
	if playsfx:
		$UISFX.pitch_scale = randf_range(0.9, 1.1)
		$UISFX.play()
	
	$ActionText.text = ("[center]" + main_text + 
	("" if subtitle_text =="" else "\n[color=white]" + subtitle_text ) +
	"\n\n[color=white]" + actionAtext + "\n[color=white]" + actionBtext + "\n\n[color=white]" + actionCtext)
