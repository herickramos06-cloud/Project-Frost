extends Control

@onready var base = $Base
@onready var stick = $Stick

var radius := 70.0

var touching := false

var center := Vector2.ZERO
