extends "res://Logic/LOGIC.gd"

# force abilities we are specifically immune to
var abilities_immune = []

# whether or not we are immune to every force power except the ones in valid_abilities
var auto_immune = false
var valid_abilities = []
