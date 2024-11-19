extends Sprite2D


func PlaySoundEffect(index):
	match index:
		0: # Riffle
			$ShuffleSFX.pitch_scale = randf_range(0.9, 1.1)
			$ShuffleSFX.play()
		1: # Card seperation
			$SlideSFX.pitch_scale = randf_range(0.9, 1.0)
			$SlideSFX.play()
