extends Panel

var line_prefab = preload("res://packed/UI/RulesetLine.tscn")

var visible_rulesets = []

# UI
func _on_RSFF_pressed():
	$FromFile.popup_centered()

func ARGIT():
	randomize()
	
#	if randi() % 10 == 0 and GameOptions.options.misplays < 2 and not GameOptions.mega_misplay: # TODO: Change this when adding more
	if GameOptions.options.misplays < 3 and not GameOptions.past_first:
		
		var p = randi() % 10
		
		if p == 03:
			get_tree().change_scene("res://ARG/Scenes/Void.tscn")

func _ready():
	
	# Disable ARG check for now
	# ARGIT()
	
	var d = Directory.new()
	d.make_dir(CardInfo.rulesets_path)
	
	if GameOptions.options.default_ruleset and not GameOptions.past_first:
		
		var filename = CardInfo.rulesets_path + GameOptions.options.default_ruleset + ".json"
		
		if d.file_exists(filename):
		
			var file = File.new()
			file.open(filename, File.READ)
			var cnt = file.get_as_text()
			file.close()
			
			use_ruleset(parse_json(cnt))
			
			return
	
	$VersionLabel.text = CardInfo.VERSION
	
	$Status.show()
	fetch_featured_rulesets()
	fetch_saved_rulesets()
	
	if CardInfo.rs_to_apply != null:
		add_saved_ruleset_entry_dat(CardInfo.rs_to_apply)
		CardInfo.rs_to_apply = null
		use_ruleset(CardInfo.rs_to_apply)

func errorBox(message: String):
	$Error/PanelContainer/VBoxContainer/Label.text = message
	$Error.show()

func _on_FromFile_file_selected(path):
	add_ruleset_from_file(path)

func _on_URLDownloadBtn_pressed():
	add_ruleset_from_url($FromURL/PanelContainer/VBoxContainer/LineEdit.text)
	$FromURL.hide()
	
func _on_JSONLoadBtn_pressed():
	add_ruleset_from_json($FromJSON/PanelContainer/VBoxContainer/TextEdit.text)
	$FromJSON.hide()

# Ruleset Management
func use_ruleset(dat: Dictionary):
	CardInfo.rules_path = CardInfo.rulesets_path + dat.ruleset + ".json"
	CardInfo.read_game_info()
	
	GameOptions.past_first = true
	
	get_tree().change_scene("res://NewMain.tscn")


func edit_ruleset(dat: Dictionary):
	CardInfo.rules_path = CardInfo.rulesets_path + dat.ruleset + ".json"
	CardInfo.read_game_info()
	
	GameOptions.past_first = true
	
	get_tree().change_scene("res://packed/RulesetEditor.tscn")

func delete_ruleset(lineObject: Control, rsName: String):
	
	# Delete ruleset file
	var d = Directory.new()
	d.remove(CardInfo.rulesets_path + rsName + ".json")
	
	if rsName in visible_rulesets:
		visible_rulesets.erase(rsName)
		
	lineObject.queue_free()

func default_ruleset(toggled: bool, lineObject: Control, rsName: String):
	
	if toggled:
		
		GameOptions.options.default_ruleset = rsName
		
		for rs in $SavedRulesets/VBoxContainer/ScrollContainer/SavedRsCont.get_children():
			if rs != lineObject:
				rs.get_node("HBoxContainer/RSButtons2/Default").pressed = false

	else:
		GameOptions.options.default_ruleset = ""
		
	GameOptions.save_options()
		
func fetch_saved_rulesets():
	var d = Directory.new()
	
	d.open(CardInfo.rulesets_path)
	
	d.list_dir_begin()
	
	while true:
		var file = d.get_next()
		if file == "":
			break
		
		if not ".json" in file:
			continue
		
		print("Adding from file ", file)
		add_ruleset_from_file(CardInfo.rulesets_path + file)
	
	d.list_dir_end()

func fetch_featured_rulesets():
	$FeaturedFetcher.request("https://raw.githubusercontent.com/107zxz/inscr-onln-ruleset/main/featured.json")

func _on_FeaturedFetcher_request_completed(_result, response_code, _headers, body):
	
	if response_code != 200:
		errorBox("Failed fetching featured\nResponse code " + str(response_code))
		return
	
	var featured = parse_json(body.get_string_from_utf8())
	
	$Status.hide()
	
	# Jake
	$Jake.show()
	$Jakebubble.show()
	$Jakebubble/Jakemsg.text = featured.jake
	
	for rs_dat in featured.rulesets:
		add_featured_ruleset_from_dat(rs_dat)

# Add rulesets
func add_featured_ruleset_from_dat(dat: Dictionary):
	
	var nl = line_prefab.instance()
	$FeaturedRulesets/VBoxContainer/ScrollContainer/FeatRsCont.add_child(nl)
	nl.get_node("HBoxContainer/RSName").text = dat.name + ("\n\n" + dat.description if "description" in dat else "")
	
	if "portrait" in dat:
		nl.get_node("HBoxContainer/RSPort").texture = load("res://gfx/" + dat.portrait + ".png")
	
	# Thing
	var rsdl = nl.get_node("HBoxContainer/RSDL")
	rsdl.show()
	rsdl.connect("pressed", self, "add_ruleset_from_url", [dat.url])
	
func add_ruleset_from_url(url: String):
	print("Adding ruleset from url: ", url)
	$Status.show()
	$Status/PanelContainer/HBoxContainer/Label.text = "Downloading Ruleset..."
	$RSDownloader.request(url)

func _on_RSDownloader_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		errorBox("Failed downloading ruleset\nResponse code " + str(response_code))
		return
	
	$Status.hide()
	
	var jString = body.get_string_from_utf8()
	
	var jDat = parse_json(jString)
	
	download_card_portraits(jDat)
	download_sigil_icons(jDat)
	
	add_ruleset_from_json(jString)

func add_ruleset_from_file(filename: String):
	var file = File.new()
	file.open(filename, File.READ)
	var cnt = file.get_as_text()
	file.close()
	add_ruleset_from_json(cnt)

func add_ruleset_from_json(json: String):
	
	var ruleset = parse_json(json)
	
	var fd = File.new()
	fd.open(CardInfo.rulesets_path + ruleset.ruleset + ".json", File.WRITE)
	fd.store_string(json)
	fd.close()
	
	add_saved_ruleset_entry_dat(ruleset)

func add_saved_ruleset_entry_dat(dat):
	
	# Don't allow dupes
	if dat.ruleset in visible_rulesets:
		return
	
	visible_rulesets.append(dat.ruleset)
	
	var nl = line_prefab.instance()
	$SavedRulesets/VBoxContainer/ScrollContainer/SavedRsCont.add_child(nl)
	nl.get_node("HBoxContainer/RSName").text = dat.ruleset + ("\n\n" + dat.description if "description" in dat else "")
	
	if "portrait" in dat:
		nl.get_node("HBoxContainer/RSPort").texture = load("res://gfx/" + dat.portrait + ".png")
	
	# Thing
	var ub = nl.get_node("HBoxContainer/RSButtons/RSUse")
	var eb = nl.get_node("HBoxContainer/RSButtons/RSEdit")
	var db = nl.get_node("HBoxContainer/RSButtons2/RSDelete")
	var defb = nl.get_node("HBoxContainer/RSButtons2/Default")
	
	ub.show()
	ub.connect("pressed", self, "use_ruleset", [dat])
	eb.show()
	eb.connect("pressed", self, "edit_ruleset", [dat])
	db.show()
	db.connect("pressed", self, "delete_ruleset", [nl, dat.ruleset])
	defb.show()
	defb.connect("toggled", self, "default_ruleset", [nl, dat.ruleset])

	# Default
	if GameOptions.options.default_ruleset == dat.ruleset:
		defb.pressed = true


func download_card_portraits(dat):
	var d = Directory.new()

	if not d.dir_exists(CardInfo.custom_portrait_path):
		d.make_dir(CardInfo.custom_portrait_path)
	
	if not d.dir_exists(CardInfo.portrait_override_path):
		d.make_dir(CardInfo.portrait_override_path)
	
	for card in dat.cards:
		if "pixport_url" in card:
			
			var fp = CardInfo.custom_portrait_path + dat.ruleset + "_" + card.name + ".png"
			
			if d.file_exists(fp):
				continue
			
			$ImageRequest.download_file = fp
			$ImageRequest.request(card.pixport_url)
			
			yield($ImageRequest, "request_completed")
	
func download_sigil_icons(dat):
	var d = Directory.new()

	if not d.dir_exists(CardInfo.custom_icon_path):
		d.make_dir(CardInfo.custom_icon_path)
	
	if not d.dir_exists(CardInfo.icon_override_path):
		d.make_dir(CardInfo.icon_override_path)
	
	if "sigil_urls" in dat:
		for sigil in dat.sigil_urls:
			var fp = CardInfo.custom_icon_path + dat.ruleset + "_" + sigil + ".png"
			
			if d.file_exists(fp):
				continue
			
			$ImageRequest.download_file = fp
			$ImageRequest.request(dat.sigil_urls[sigil])
			
			yield($ImageRequest, "request_completed")


func open_rsdir():
	print("Opening rulesets dir?")
	OS.shell_open("file://" + OS.get_user_data_dir() + "/rulesets/")