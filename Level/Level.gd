extends Node3D
class_name Level


var doors = []
var collectables = []
var level_script
var ai_manager

var camera : Camera3D
var environment : WorldEnvironment
var sun : DirectionalLight3D

var death_height : float
