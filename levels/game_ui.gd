extends CanvasLayer

var is_shuffling: bool = false
var can_choose_horl: bool = false

func _ready():
	Deck.ShuffleAnimationBegin.connect(ShuffleAnimationBegin)
	Deck.ShuffleAnimationFinish.connect(ShuffleAnimationFinish)
	Deck.CardDrawn.connect(CardDrawn)
	SetActionText("")
	
func _process(_delta):
	
	if Input.is_action_just_pressed("DEBUG"):
		if can_choose_horl:
			SetActionText("")
			can_choose_horl = false
			Deck.DrawNextCard()

func ShuffleAnimationBegin():
	is_shuffling = true
	while(is_shuffling):
		SetActionText("Shuffling.")
		await get_tree().create_timer(1).timeout
		if not is_shuffling:
			return
		
		SetActionText("Shuffling..")
		await get_tree().create_timer(1).timeout
		if not is_shuffling:
			return
		
		SetActionText("Shuffling...")
		await get_tree().create_timer(1).timeout
		if not is_shuffling:
			return
		

func ShuffleAnimationFinish():
	is_shuffling = false
	SetActionText("")

func CardDrawn():
	SetActionText("Jack of Spades")
	
	await get_tree().create_timer(1).timeout
	
	if Deck.cards_in_play > 1:
		SetActionText("Jack of Spades", "Press Q for LOWER[color=#FF6600] (+30%)", "Press E for HIGHER", "Press T to CASH OUT")
	else:
		SetActionText("Jack of Spades", "Press Q for LOWER", "Press E for HIGHER")
	
	can_choose_horl = true

func SetActionText(main_text, actionAtext = "", actionBtext = "", actionCtext = ""):
	$ActionText.text = "[center]" + main_text + "\n\n[color=white]" + actionAtext + "\n[color=white]" + actionBtext + "\n\n[color=white]" + actionCtext
