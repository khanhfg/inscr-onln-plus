extends Control

const HVR_COLOURS = [
	Color(0.933333, 0.921569, 0.843137),
	Color.white,
	Color(0.45, 0.45, 0.45)
]

const SIGIL_SLOTS = [
	"Sigils/Row1/S1",
	"Sigils/Row1/S2",
	"Sigils/Row1/S3",
	
	"Sigils/Row2/S1",
	"Sigils/Row2/S2",
	"Sigils/Row2/S3"
]

var card_data = {
					"name": "Greater Smoke",
					"sigils": [
							"Bone King"
					],
					"attack": 1,
					"health": 3,
					"banned": true,
					"rare": true,
					"description": "Ported from Act 1. Act 2 sprite by syntaxevasion."
				}

# Called when the node enters the scene tree for the first time.
func _ready():
#	modulate = HVR_COLOURS[0]
	pass


func draw_from_data(cDat: Dictionary) -> void:
	
	# Card is now face-up, hide the back
	$CardBack.hide()
	
	draw_stats(cDat)
	draw_sigils(cDat)
	draw_costs(cDat)
	draw_conduit(cDat)
	draw_active(cDat)


func draw_stats(cDat: Dictionary) -> void:
	$CardPort.texture = load("res://gfx/pixport/" + cDat.name + ".png")
	$AtkScore.text = str(cDat.attack)
	$HpScore.text = str(cDat.health)

func draw_sigils(cDat: Dictionary) -> void:
	
	var sCount = len(cDat.get("sigils", []))
	
	# Clear, in case it needs to happen again
	for sigSlt in SIGIL_SLOTS:
		get_node(sigSlt).hide()
	
	# Fix spacing	
	$Sigils/Row2.visible = (sCount > 3)
	
	# Special case: Don't draw sigils if an active sigil is present
	if "active" in cDat or sCount == 0:
		return
	
	for sIdx in range(sCount):
		var cNode = get_node(SIGIL_SLOTS[sIdx])
		cNode.texture = load("res://gfx/sigils/%s.png" % cDat.sigils[sIdx])
		cNode.show()


# This could potentially be called multiple times on the same card,
# e.g. when evolving. Therefore costs need to be manually hidden
# when not in use
func draw_costs(cDat: Dictionary) -> void:
	
	var costRoot = get_node("Costs")
	
	for cost in [
		"blood",
		"bone",
		"energy"
	]:
		var costNode = costRoot.get_node(cost)
#		var costs = cDat.get("costs", {})
		
		if not cDat.get(cost + "_cost"):
			costNode.hide()
		else:
			var costValue = cDat.get(cost + "_cost")
			
			costNode.show()
			
			for node in costNode.get_children():
				node.hide()
			
			if costValue < 3:
				costNode.get_node(str(costValue)).show()
				
			else:
				costNode.get_node("TXIcon").show()
				var txtParent = costNode.get_node("Text")
				txtParent.show()
				var txtNodes = txtParent.get_children()
				for txt in txtNodes:
					txt.text = "x" + str(costValue)
				costNode.get_node("Text").rect_min_size.x = 39 + (18 * floor(log(costValue) / log(10)))
	
	if cDat.get("mox_cost"):
		
		var moxNames = [
			"Orange",
			"Blue",
			"Green"
		]
		
		for moxName in moxNames:
			costRoot.get_node("mox").get_child(moxNames.find(moxName)).visible = moxName in cDat.get("mox_cost")

# Conduit sigil
func draw_conduit(cDat: Dictionary) -> void:
	$Sigils/ConduitIndicator.visible = "conduit" in cDat

func draw_active(cDat: Dictionary) -> void:
	if "active" in cDat and cDat.get("sigils"):
		$Active.show()
		$Active/ActiveIcon.texture = load("res://gfx/sigils/" + cDat.sigils[0] + ".png")
	else:
		$Active.hide()

# Hover, click handlers
func _on_CardBtn_button_down() -> void:
	modulate = HVR_COLOURS[2]

func _on_CardBtn_button_up() -> void:
	if modulate == HVR_COLOURS[2]:
		modulate = HVR_COLOURS[1]
	
	# Trigger a press action
	get_parent()._on_Button_pressed()
		

func _on_CardBtn_mouse_entered() -> void:
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]


func _on_CardBtn_mouse_exited() -> void:
	modulate = HVR_COLOURS[0]


func _on_Active2_mouse_entered() -> void:
	if modulate == HVR_COLOURS[0]:
		modulate = HVR_COLOURS[1]

func _on_Active2_mouse_exited() -> void:
	modulate = HVR_COLOURS[0]


func _on_Active_button_down() -> void:
	$Active/ActiveIcon.rect_position = Vector2(6, 16)
	get_parent()._on_ActiveSigil_pressed()
	


func _on_Active_button_up() -> void:
	$Active/ActiveIcon.rect_position = Vector2(6, 6)

