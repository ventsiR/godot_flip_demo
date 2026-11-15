class_name Card
extends Node2D

var temp_tracker: bool = false

var CARD_BACK_TEXTURE := preload("res://resources/card_back.png")

var root: Root

@export var anim_speed : float = Utils.anim_speed

@onready var card_back: Sprite2D = $CardBack
@onready var card_front: Sprite2D = $CardFront

var tween: Tween

var pile: Node2D

var is_face_up: bool


func build_into(p_root: Root, p_pile: Node2D) -> void:
	root = p_root
	
	pile = p_pile


func _ready() -> void:
	set_process(false)
	set_notify_local_transform(true)
	
	_set_visual_properties()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_enforce_orientation()


func _set_card() -> void:
	_set_visual_properties()


func _set_visual_properties() -> void:
	card_back.texture = CARD_BACK_TEXTURE
	
	card_back.scale = Vector2(-1, 1)


func _enforce_orientation() -> void:
	if scale.x * scale.y >= 0:
		is_face_up = true
		
		card_back.visible = false
		card_front.visible = true
	else:
		is_face_up = false
		
		card_back.visible = true
		card_front.visible = false


## Animates card to a `target` using a tween.
##
## Ensure `p_target` and the variable you're running anim_to() on have the same
## parent.
##
## Ensure all 5 listed properties of `target` are set, otherwise default values
## set by `Node2D.new()` are used, which you probably don't want.
## 
## @param `target`: `global_position`, `global_rotaiton`, `global_scale`,
## `global_skew` and `z_index` from the target are used as the destination for
## the tween.
##
## @param `speed` determines duration of the tween.
##
## @param `arc_amount` determine height of added arc between start and end
## position.
## Setting it to 0 will result in a path that is a straight line. Positive
## `arc_amount` adds an arc in the 'up' direction, i.e. negative-y, negative
## `arc_amount` adds an arc in the 'down' direction, i.e. positive-y.
func anim_to(
	p_target: Node2D,
	speed: float = anim_speed,
	arc_amount: float = 0,
) -> void:
	var target: Node2D = p_target.duplicate()
	
	var anim_distance: float
	
	anim_distance = Utils.bezier_arc_length(global_position, target.global_position,
	arc_amount)

	var anim_duration: float = Utils.safe_divide(
	anim_distance, speed * get_viewport_rect().size.x)
	
	anim_duration = clamp(anim_duration, 0.2, 1)
	
	var anim = create_tween()
	
	anim.set_parallel(true)
	anim.set_trans(Tween.TRANS_CUBIC)
	anim.set_ease(Tween.EASE_OUT)

	if position != target.position:
		if arc_amount == 0:
			anim.tween_property(self, "position", target.position,
				anim_duration)
		else:
			var start_position := position
			var end_position := target.position
			
			anim.tween_method(
				func(t):
					position = Utils.bezier_arc(
					start_position, end_position, arc_amount, t),
					0.0, 1.0, anim_duration)
	if rotation != target.rotation:
		anim.tween_property(self, "rotation", target.rotation,
			anim_duration)
	if scale != target.scale:
		anim.tween_property(self, "scale", target.scale,
			anim_duration)
	if skew != target.skew:
		anim.tween_property(self, "skew", target.skew,
			anim_duration)
	if z_index != target.z_index:
		anim.tween_property(self, "z_index", target.z_index,
			anim_duration)
	
	await anim.finished
