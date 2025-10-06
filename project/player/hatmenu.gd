extends Control

@onready var player = $".."
@onready var cam_2_arm = $SubViewportContainer/SubViewport/cam2_arm

var _1_active = false
var _2_active = false
var _3_active = false
var _4_active = false
var active = 0

@onready var crow = $"../visual_root/crow"

@onready var _1 = $"buttons/1"
@onready var _1_button = $"buttons/1/1button"
@onready var _1_label = $"buttons/1/1label"

@onready var _2 = $"buttons/2"
@onready var _2_button = $"buttons/2/2button"
@onready var _2_label = $"buttons/2/2label"

@onready var _3 = $"buttons/3"
@onready var _3_button = $"buttons/3/3button"
@onready var _3_label = $"buttons/3/3label"

@onready var _4 = $"buttons/4"
@onready var _4_button = $"buttons/4/4button"
@onready var _4_label = $"buttons/4/4label"

@onready var moneylabel = $"../ui/money/money"
@onready var syncdata = $"../syncdata"

@onready var poor = $poor
@onready var buy = $buy


func _ready():
	visible = false

var width = 920
func _process(delta):
	var mouse_position =  get_viewport().get_mouse_position()
	cam_2_arm.rotation.y = PI*(mouse_position.x - width/2)/width+PI/2
	cam_2_arm.rotation.x = PI*(mouse_position.y - width/2)/width/4

func reset_colours():
	_1.color = Color("#73bed3")
	_2.color = Color("#73bed3")
	_3.color = Color("#73bed3")
	_4.color = Color("#73bed3")

func _on_1button_pressed():
	var cost = 2
	if !_1_active:
		if player.money < cost:
			poor.play()
			return
		else:
			player.money -= cost
			moneylabel.text = str(player.money)
			_1_active = true
			_1_label.visible = false
	reset_colours()
	if active == 1:
		crow.toggle_hat(0)
		active = 0
	else:
		active = 1
		_1.color = Color("#a4dddb")
		crow.toggle_hat(1)
	buy.play()
	player.rpc("sync_hat",active)


func _on_2button_pressed():
	var cost = 4
	if !_2_active:
		if player.money < cost:
			poor.play()
			return
		else:
			player.money -= cost
			moneylabel.text = str(player.money)
			_2_active = true
			_2_label.visible = false
	reset_colours()
	if active == 2:
		crow.toggle_hat(0)
		active = 0
	else:
		active = 2
		_2.color = Color("#a4dddb")
		crow.toggle_hat(2)
	buy.play()
	player.rpc("sync_hat",active)


func _on_3button_pressed():
	var cost = 3
	if !_3_active:
		if player.money < cost:
			poor.play()
			return
		else:
			player.money -= cost
			moneylabel.text = str(player.money)
			_3_active = true
			_3_label.visible = false
	reset_colours()
	if active == 3:
		crow.toggle_hat(0)
		active = 0
	else:
		active = 3
		_3.color = Color("#a4dddb")
		crow.toggle_hat(3)
	buy.play()
	player.rpc("sync_hat",active)


func _on_4button_pressed():
	var cost = 5
	if !_4_active:
		if player.money < cost:
			poor.play()
			return
		else:
			player.money -= cost
			moneylabel.text = str(player.money)
			_4_active = true
			_4_label.visible = false
	reset_colours()
	if active == 4:
		crow.toggle_hat(0)
		active = 0
	else:
		active = 4
		_4.color = Color("#a4dddb")
		crow.toggle_hat(4)
	buy.play()
	player.rpc("sync_hat",active)
