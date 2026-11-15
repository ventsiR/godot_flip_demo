class_name DeckPile
extends Node2D

var root: Root

@onready var transformer_node: Node2D = %TransformerNode
@onready var card_pile_bottom: Sprite2D = %DeckPileBottom
@onready var card_container: Node2D = %CardContainer

@export var cards_offset: Vector2 = Vector2(0, 0.5)
@export var max_addnl_size_ratio: Vector2 = Vector2(0, 1.0 / 7.0)

## Stores each unique Card instance with a Time.get_ticks_usec of when it was
## added.
var cards: Dictionary[Card, int] = {}

var num_cards: int :
	set(value) :
		num_cards = value

var is_face_up: bool = false

func build_into(p_root: Root) -> void:
	root = p_root
	
	scale = Vector2(0.09, 0.09)
	
	position = Vector2(1697.5, 966.5)
	transformer_node.modulate = Color(1, 1, 1, 1)


## Internal method. Does not update physical object as "adding" a card usually
## would. Intended use is within DeckPile by other
## methods.
## 
## Note: Care should be taken to only add card(s) if they don't already
## have an existing pile.
func _data_add_card(p_card: Card) -> Card:
	if cards.has(p_card):
		return null
	
	cards[p_card] = Time.get_ticks_usec()
	p_card.pile = self
	return p_card


## Note: Care should be taken to only add card(s) if they don't already
## have an existing pile.
func data_add_card(p_card: Card, has_anim: bool = false) -> Card:
	
	var added_card: Card = _data_add_card(p_card)
	if added_card:
				
		add_cards([added_card], has_anim)
	
	return added_card


## Note: Care should be taken to only add card(s) if they don't already
## have an existing pile.
func data_add_cards(
	p_cards: Array[Card],
	has_anim: bool = false,
	anim_speed: float = Utils.anim_speed,
	arc_amount: float = 0.0,
) -> Array[Card]:
	var added_cards: Array[Card]
	
	for p_card in p_cards:
		var added_card = _data_add_card(p_card)
		if added_card:
			added_cards.append(added_card)
	
	if not added_cards.is_empty():
				
		add_cards(added_cards, has_anim, anim_speed, arc_amount)
	
	return added_cards


## Internal method. Does not update physical object as "removing" a card usually
## would. Intended use is within DeckPile by other
## methods.
func _data_remove_card(p_card: Card) -> Card:
	if not cards.has(p_card):
		return null
	
	cards.erase(p_card)
	
	p_card.pile = null
	
	return p_card


func data_remove_card(p_card: Card) -> Card:
	var removed_card: Card = _data_remove_card(p_card)
	
	if removed_card:
				remove_cards([removed_card])
	
	return removed_card


func data_remove_cards(p_cards: Array[Card]) -> Array[Card]:
	var removed_cards: Array[Card]
	
	for p_card in p_cards:
		var removed_card = _data_remove_card(p_card)
		if removed_card:
			removed_cards.append(removed_card)
	
	if not removed_cards.is_empty():
				remove_cards(removed_cards)
	
	return removed_cards


func data_remove_all() -> Array[Card]:
	var removed_cards: Array[Card]
	
	for card in cards.duplicate():
		removed_cards.append(_data_remove_card(card))
	
	if not removed_cards.is_empty():
				
		remove_cards(removed_cards)
	
	return removed_cards


## Note: "Drawing" is only different to removing a card in that if pile is
## deck and it is empty, we first try to shuffle discard into draw before
## attempting to draw again.
func data_draw_random_cards(n: int = 1) -> Array[Card]:
	var drawn_cards: Array[Card]
	
	for _i in range(n):
		
		if not cards:
			return drawn_cards
		
		var card: Card = cards.keys()[Utils._randi(cards.size())]
		_data_remove_card(card)
		drawn_cards.append(card)
	
	if not drawn_cards.is_empty():
		
		remove_cards(drawn_cards)
	
	return drawn_cards













































func add_cards(
	p_cards: Array[Card],
	has_anim: bool = false,
	anim_speed: float = Utils.anim_speed,
	arc_amount: float = 0.0,
) -> void:
	var anim_speed_per_card: float
	
	if has_anim:
		anim_speed_per_card = anim_speed * float(p_cards.size())
	
	var curr_pos = Vector2.ZERO
	var curr_z_index = 1
	
	for card: Card in cards.keys():
		if card.temp_tracker:
			print("start adding card to pile")
		
		var target: Node2D = Node2D.new()

		card_container.add_child(target)

		target.position = curr_pos
		target.rotation = 0.0
		target.scale = Vector2.ONE
		Utils.print_gl_lc_sc_rot(card)
		target.scale.x = 1 if is_face_up else -1
		Utils.print_gl_lc_sc_rot(card)
		target.skew = 0.0
		target.z_index = curr_z_index


		if card in p_cards:
			var card_parent = card.get_parent()
			if card_parent != card_container:
				if card_parent:
					Utils.parent_remove_child_without_transform(
						card_parent, card)
				Utils.parent_add_child_without_transform(card_container, card)
		
		Utils.print_gl_lc_sc_rot(card)
		Utils.print_gl_lc_sc_rot(card)
		
		if card in p_cards and has_anim:
			root.anim_queue.append(
			[card, target, anim_speed_per_card, arc_amount])
		
		Utils.print_gl_lc_sc_rot(card)
		Utils.print_gl_lc_sc_rot(card)


		curr_pos.x = clamp(curr_pos.x + cards_offset.x,
			-max_addnl_size_ratio.x * scale.x *\
			Utils.BASE_CARD_SIZE.x,
			(1 + max_addnl_size_ratio.x) * scale.x *\
			Utils.BASE_CARD_SIZE.x,
		)
		curr_pos.y = clamp(curr_pos.y + cards_offset.y,
			-max_addnl_size_ratio.y * scale.y *\
			Utils.BASE_CARD_SIZE.y,
			(1 + max_addnl_size_ratio.y) * scale.y *\
			Utils.BASE_CARD_SIZE.y,
		)
		curr_z_index += 1

		if card.temp_tracker:
			print("finish adding card to pile")


func remove_cards(p_cards: Array[Card]) -> void:
	for card in p_cards:
		if card.temp_tracker:
			print("start removing from pile")
			Utils.print_gl_lc_sc_rot(card)

		if card.get_parent() == card_container:
			var xform: Transform2D = Utils.parent_remove_child_without_transform(card_container, card)
			if card.temp_tracker:
				print("Transform2D:\n%s\n" % [xform])

		if card.temp_tracker:
			print("finish removing from pile")
			Utils.print_gl_lc_sc_rot(card)
	
	var curr_pos = Vector2.ZERO
	var curr_z_index = 1
	
	for card: Card in cards.keys():
		card.position = curr_pos
		card.z_index = curr_z_index
		
		curr_pos.x = clamp(curr_pos.x + cards_offset.x,
			-max_addnl_size_ratio.x * scale.x *\
			Utils.BASE_CARD_SIZE.x,
			(1 + max_addnl_size_ratio.x) * scale.x *\
			Utils.BASE_CARD_SIZE.x,
		)
		curr_pos.y = clamp(curr_pos.y + cards_offset.y,
			-max_addnl_size_ratio.y * scale.y *\
			Utils.BASE_CARD_SIZE.y,
			(1 + max_addnl_size_ratio.y) * scale.y *\
			Utils.BASE_CARD_SIZE.y,
		)
		curr_z_index += 1
