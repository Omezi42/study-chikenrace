extends Control

func play_animations() -> Array[Tween]:
	if has_meta("play_animations"):
		var callable = get_meta("play_animations")
		if callable is Callable:
			var result = callable.call()
			if result is Array:
				# We need to cast it since GDScript typing on lambdas returning Array[Tween] is sometimes returned as untyped Array
				var tweens: Array[Tween] = []
				for r in result:
					if r is Tween:
						tweens.append(r)
				return tweens
	return []
