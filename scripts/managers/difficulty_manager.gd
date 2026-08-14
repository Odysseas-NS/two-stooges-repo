extends Node

var time_survived := 0.0
var difficulty := 1.0

func _process(delta):
	time_survived += delta
	difficulty = 1.0 + time_survived / 30.0
