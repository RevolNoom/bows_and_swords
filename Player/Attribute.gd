extends ProgressBar

signal full() 
signal empty()

export var regen = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# TODO: Regen every sec, not every frame
func _process(delta):
	Add(regen * delta)


func CurrentPercentage():
	return value/max_value


func MissingPercentage():
	return 1 - CurrentPercentage()


func Set(amount):
	value = amount

	if value >= max_value:
		value = max_value
		emit_signal("full")
	elif value <= 0:
		value = 0
		emit_signal("empty")


func Add(amount):
	Set(value + amount)


func Reduce(amount):
	Set(value - amount)


func SetRegen(amountPerSec):
	regen = amountPerSec


func AddRegen(amountPerSec):
	regen += amountPerSec


func ReduceRegen(amountPerSec):
	regen -= amountPerSec
