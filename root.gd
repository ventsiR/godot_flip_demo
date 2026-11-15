class_name Root
extends Node2D

var anim_queue: Array[Array]
var anim_queue_busy: bool = false

const CARD_SCENE := preload("res://card.tscn")
const HAND_SCENE := preload("res://hand.tscn")
const DECK_PILE_SCENE := preload("res://deck_pile.tscn")

@onready var deck_pile: DeckPile = DECK_PILE_SCENE.instantiate()
@onready var card: Card = CARD_SCENE.instantiate()
@onready var hand: Hand = HAND_SCENE.instantiate()


func _ready() -> void:
	add_child(hand)
	hand.build_into(self)

	add_child(deck_pile)
	deck_pile.build_into(self)

	add_child(card)
	card.root = self

	card.temp_tracker = true

	start_turn()


func start_turn() -> void:
	await get_tree().create_timer(1.0).timeout
	await card_to_deck()
	await get_tree().create_timer(1.0).timeout
	await draw_card()


func card_to_deck() -> void:
	deck_pile.data_add_cards([card], true)
	
	await exec_anim_queue()


func draw_card() -> void:
	var drawn_cards = deck_pile.data_draw_random_cards(1)
	if drawn_cards:
		hand.data_add_cards(drawn_cards, true, Utils.anim_speed, 500)
	
	await exec_anim_queue()


func exec_anim_queue() -> void:
	while anim_queue.size() > 0:
		var anim = anim_queue[0]
		
		var card: Card = anim[0]
		var target: Node2D = anim[1]
		var speed: float = anim[2]
		var arc_amount: float = anim[3]
		
		anim_queue_busy = true
		await card.anim_to(target, speed, arc_amount)
		anim_queue_busy = false

		target.queue_free()
		anim_queue.remove_at(0)
