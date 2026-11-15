class_name Hand
extends Node2D

var root: Root

## Stores each unique Card instance with a Time.get_ticks_usec of when it was
## added.
var cards: Dictionary[Card, int] = {}

var num_cards: int :
	set(value) :
		num_cards = value

var is_face_up: bool = false

@export var card_scale: float = 0.1
@export var max_width: float = 670.0
## Cards' centerpoints in the hand are laid on a circle.
## Higher radius will make cards in hand look flatter.
@export var circle_radius: float = 3 * 210

# sets max card rotation to a value to guarantee max hand width is maintained
@onready var max_card_rotation: float = asin(max_width / (2.0 * circle_radius))
# the highest rotation by whcih 2 adjcent cards in hand can differ
@onready var max_card_rotation_delta: float = max_card_rotation / 3




func build_into(p_root: Root) -> void:
	root = p_root
	
	position = Vector2(960, 980)
	scale = Vector2(0.1, 0.1)


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
































func _calc_hand_properies(hand_size) -> Array:
	var card_rotation_delta = 0.0
	
	if hand_size >= 2:
		card_rotation_delta = min(
			(2 * max_card_rotation) / (hand_size - 1),
			max_card_rotation_delta
		)
	
	var mid_index = (hand_size - 1) / 2.0
	
	return [card_rotation_delta, mid_index]


func _calc_targets(hand_size) -> Array[Node2D]:
	var targets: Array[Node2D] = []
	
	if hand_size == 0:
		return []
	
	var hand_properties = _calc_hand_properies(hand_size)
	var card_rotation_delta = hand_properties[0]
	var mid_index = hand_properties[1]
	
	for i in range(hand_size):
		var target: Node2D = _ith_card_target(
			i,
			card_rotation_delta,
			mid_index,
		)
		
		targets.append(target)
	
	return targets


func _ith_card_target(
	i: int,
	card_rotation_delta:float,
	mid_index: float,
) -> Node2D:
	var target: Node2D = Node2D.new()
	add_child(target)
	
	target.z_index = i
	
	var card_rotation = (i - mid_index) * card_rotation_delta
	target.rotation = card_rotation
	
	var circle_center: Vector2 = Vector2(0, circle_radius)
	target.global_position += circle_center + Vector2(
		circle_radius * sin(card_rotation), -circle_radius * cos(card_rotation)
	)
	
	target.scale = Vector2.ONE
	
	target.skew = 0
	
	return target


func _update_hand(
	added_cards: Array[Card] = [],
	has_anim: bool = false,
	anim_speed: float = Utils.anim_speed,
	arc_amount: float = 0.0,
) -> void:
	var cards: Array[Card] = cards.keys()
	
	var hand_size: int = cards.size()
	
	var targets: Array[Node2D] = _calc_targets(hand_size)
	
	var anim_speed_per_card: float = anim_speed * added_cards.size()
	
	for i in range(hand_size):
		var card: Card = cards[i]
		var target: Node2D = targets[i]

		Utils.print_gl_lc_sc_rot(card)
		
		if card in added_cards and has_anim and Utils.anims_enabled:
			root.anim_queue.append(
			[card, target, anim_speed_per_card, arc_amount])
		else:
			card.position = target.position
			card.rotation = target.rotation
			card.scale = target.scale
			card.skew = target.skew
			card.z_index = target.z_index
		
		Utils.print_gl_lc_sc_rot(card)


func add_cards(
	p_cards: Array[Card],
	has_anim: bool = false,
	anim_speed: float = Utils.anim_speed,
	arc_amount: float = 0.0,
) -> void:
	for card in p_cards:
		if card.temp_tracker:
			print("start adding card to hand")
		print("IM HERE!")
		Utils.print_gl_lc_sc_rot(card)

		var parent = card.get_parent()
		if parent != self:
			if parent:
				Utils.parent_remove_child_without_transform(parent, card)
			Utils.parent_add_child_without_transform(self, card)

		if card.temp_tracker:
			print("finish adding card to hand")
	
	_update_hand(p_cards, has_anim, anim_speed, arc_amount)


func remove_cards(p_cards: Array[Card]) -> void:
	for card in p_cards:
		card.z_index = 0
		
		if card is Card and card.get_parent() == self:
			Utils.parent_remove_child_without_transform(self, card)
	
	_update_hand()
