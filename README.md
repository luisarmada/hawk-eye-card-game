# Welcome to Hawk's Card Gambit!

Hawk's Card Gambit is a game made using Godot 4.3.
Godot uses a language called GDScript which is very similar to Python. It's designed specifically for Godot, making it easy to integrate with the engine's features and workflows.
GDScript features dynamic typing, indent-based structure, and is lightweight and optimized.

## How To Run Game
1. Open this link in browser: https://luera.itch.io/hawks-card-gambit
2. Press 'Run game' (This might open in a pop-up window, make sure to click on the window to get focus)
3. Enjoy! (There are sounds effects, so make sure audio is on!)

## How To Play
- The game should open and ask the user to input a bet. Use the number keys to input a bet (can also contain decimals).
- The bet must be less than balance (you can't bet more than you have!) and a valid integer or float with maximum 2dp.
- Press T to enable/disable JOKERS. Pulling a Joker is an auto-loss, however playing with Jokers enabled adds a multiplier to winnings.
- Afterwards, follow on-screen controls to choose higher, lower, or cash out.
- You can only cash out after the first guess.
- Between higher and lower, the HAWK will favour the option which is more likely.
- You can vote against the hawk for a 2x multiplier to winnings.
- Winnings are based on `(bet + current winnings) * any multipliers`.

## Design Choices

- Most of the code logic can be found in the `deck.gd` and `game_ui.gd` scripts, which can be found in the object folder. These are commented (using `#`) and work together to run the game.
- `deck.gd` is a global script, meaning it is run when the game is start and can be referenced by other scripts. It manages any logic to do with the cards, such as shuffling, dealing and animations.
  - This script uses 'tweens' to animate the cards shuffling. Tweens are an animation-based tool that takes in a property of a node, and interpolates that property's value over time. In this case, I use tweens to interpolate the position and scale of the cards to animate a shuffling maneuver. I chose tweens over manual animation due to their ease of use, and event callbacks.
  - The card shuffling mechanic uses the **Fisher-Yates Shuffle** algorithm to shuffle the cards. The art used for the cards is stored in a *spritesheet*, meaning each card has it's own `frame` property which represents its position in the spritesheet. This also means that each card has a unique ID that it can be referred to. Therefore, putting all these unique ID's into an array is ideal as there are no duplicates, and the Fisher-Yates shuffle can just be called once every time the game is start.
  - The Fisher-Yates algorithm is used as it ensures the game is *fair*, as every possible permutation of the array is equally likely. This also means that the game will not be repetitive as there is no bias. Also, the algorithm does not require any extra storage or memory, and can be performed in a single for-loop. This therefore means it has a time-complexity of O(n), making it efficient.
  - The hawk's AI logic is also present in this script. As of now, the hawk just favours the more likely option without taking into account the cards that have already been played. Therefore, it just favours `higher if card_value <= 7, lower otherwise`. The hawk's logic can definitely be improved in future iterations.
- `game_ui.gd` is a script that manages the user interface. It updates all the text on the screen, as well as the player's balance, bet and winnings when necessary.
  - Winnings are calculated in this script by adding `current_bet` and `current_winnings`, and multiplying the result by `0.08`. This makes the game rewarding, without making it too easy to earn points.
  - An additional multiplier of `1.8` is added if jokers are enabled, and another multiplier of `2` is added if the player bets against the hawk. This produces an extra layer of challenge and makes the game more enjoyable by rewarding the player for taking risks.
- I made sure that the codebase was extremely modular. Code is made into a function if it is used more than once, making the codebase easier to understand, maintain, and scale. Additionally, by making reusable components, it is easier to debug and change minor details in one place without having to check in multiple areas.

## Future Improvements
- A major potential improvement would be the hawk's AI for deciding which option to favour. Currently, the check is purely based off of the current card in the pile. This works quite well for early play, however when the game reaches later stages it becomes quite easy to know if higher or lower is more probable, as most cards have already appeared and a guess can be made quite accurately.
  - I would improve the algorithm by ensuring that the hawk tracks the cards that have already been played. By making probability based decisions, it will improve the correctness of the hawk's AI. Additionally, I could add some weighted randomness for unpredictability, introducing a small chance for the AI to make a 'wrong' decision to make it more fun to play against.
- The GUI is also a place for major improvement. The current display is passable, however the background is just pure black with white text, which just seems like a fancier command line.
  - I would improve this area by adding more theme-related art, such as a casino table background or some green flairs. One reason is because green is associated with calmness and focus, and could be implemented to enhance user experience.
