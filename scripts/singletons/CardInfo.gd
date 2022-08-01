extends Node

const VERSION = "0.1.0 DEV"

var all_data = {}
var ruleset = "unnamed/cached ruleset"
var all_sigils = []
var all_cards = []
var working_sigils = []
var deck_path = OS.get_user_data_dir() + "/decks/"
var rules_path = OS.get_user_data_dir() + "/gameInfo.json"

func _enter_tree():
	read_game_info()

func from_game_info_json(content_as_object):
	all_data = content_as_object
	
	all_sigils = all_data["sigils"]
	all_cards = all_data["cards"]
	working_sigils = all_data["working_sigils"]
	
	if "ruleset" in all_data:
		ruleset = all_data.ruleset

func read_game_info():
	
	# Does a downloaded ruleset exist?
	var dir = Directory.new()
	var file = File.new()
	
	if dir.file_exists(rules_path):
		file.open(rules_path, File.READ)
		print(rules_path)
	else:
		print("Downloaded rules not found! Using saved as fallback (this is normal for first use after install)")
		file.open("res://data/gameInfo.json", File.READ)
		
	var file_content = file.get_as_text()
	var content_as_object = parse_json(file_content)
	from_game_info_json(content_as_object)

func from_name(cName):
	for card in all_cards:
		if card.name == cName:
			return card

func idx_from_name(cName):
	var idx = 0

	for card in all_cards:
		if card.name == cName:
			return idx
		idx += 1
