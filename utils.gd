extends Node

@export var BASE_CARD_SIZE: Vector2 = Vector2(1500, 2100)
@export var DRAG_START_TOLERANCE_RADIUS: float = 10
@export var anims_enabled: bool = true

## Speed of N means animations travel at a speed of
## N * <number of pixels of screen width> pixels per second
@export var anim_speed: float = 1.0


func safe_divide(a, b):
	var type_a := typeof(a)
	var type_b := typeof(b)

	var divisible_types = [
		TYPE_INT, TYPE_FLOAT,
		TYPE_VECTOR2, TYPE_VECTOR2I,
		TYPE_VECTOR3, TYPE_VECTOR3I,
		TYPE_VECTOR4, TYPE_VECTOR4I,
		TYPE_COLOR,
	]

	# Reject anything that doesn't support "/" at all
	if not (type_a in divisible_types and type_b in divisible_types):
		return _zero_like(a)

	# Vector/vector division only valid between matching vector types
	var a_is_scalar = type_a == TYPE_INT or type_a == TYPE_FLOAT
	var b_is_scalar = type_b == TYPE_INT or type_b == TYPE_FLOAT
	if not a_is_scalar and not b_is_scalar and type_a != type_b:
		return _zero_like(a)

	# Integer vectors can't be divided by a float divisor
	var int_vector_types = [TYPE_VECTOR2I, TYPE_VECTOR3I, TYPE_VECTOR4I]
	if type_a in int_vector_types and type_b == TYPE_FLOAT:
		return _zero_like(a)

	# Catch zero / zero-component divisors
	if _has_zero_component(b):
		return _zero_like(a)

	return a / b


func _has_zero_component(v) -> bool:
	match typeof(v):
		TYPE_INT, TYPE_FLOAT:
			return v == 0
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return v.x == 0 or v.y == 0
		TYPE_VECTOR3, TYPE_VECTOR3I:
			return v.x == 0 or v.y == 0 or v.z == 0
		TYPE_VECTOR4, TYPE_VECTOR4I:
			return v.x == 0 or v.y == 0 or v.z == 0 or v.w == 0
		TYPE_COLOR:
			return v.r == 0 or v.g == 0 or v.b == 0 or v.a == 0
		_:
			return false


func _zero_like(a):
	match typeof(a):
		TYPE_INT: return 0
		TYPE_FLOAT: return 0.0
		TYPE_VECTOR2: return Vector2.ZERO
		TYPE_VECTOR2I: return Vector2i.ZERO
		TYPE_VECTOR3: return Vector3.ZERO
		TYPE_VECTOR3I: return Vector3i.ZERO
		TYPE_VECTOR4: return Vector4.ZERO
		TYPE_VECTOR4I: return Vector4i.ZERO
		TYPE_COLOR: return Color(0, 0, 0, 0)
		_: return 0


func parent_add_child_without_transform(parent: Node2D, child: Node2D) -> Transform2D:
	var global_transform = child.global_transform
	parent.add_child(child)
	child.global_transform = global_transform
	return global_transform


func parent_remove_child_without_transform(parent: Node2D, child: Node2D) -> Transform2D:
	var global_transform = child.global_transform
	parent.remove_child(child)
	child.global_transform = global_transform
	return global_transform


# Returns random int between 0 and i
func _randi(i: int) -> int:
	if i > 0:
		return randi() % i
	return 0


func bezier_arc(
	start: Vector2,
	end: Vector2,
	arc_amount: float,
	t: float,
) -> Vector2:
	var mid_ab: Vector2 = (start + end) / 2
	var dir: Vector2 = end - start
	var perp: Vector2 = Vector2(-dir.y, dir.x).normalized()
	
	if perp.y > 0:
		perp *= -1
	
	var mid: Vector2 = mid_ab + (perp / 2) * arc_amount
	
	return (
		(1.0 - t) * (1.0 - t) * start +
		2.0 * (1.0 - t) * t * mid +
		t * t * end
	)


func bezier_arc_length(start: Vector2, end: Vector2, arc_amount: float) -> \
float:
	var d: float = start.distance_to(end)
	var a: float = abs(arc_amount)

	if d == 0.0:
		return a / 2.0

	if a == 0.0:
		return d

	return 0.5 * (
		sqrt(d * d + a * a)
		+ (d * d / a) * asinh(a / d)
	)


func print_gl_lc_sc_rot(card: Node2D) -> void:
	print("%s:\nG sx sy r %+.2f %+.2f %+.2f    L sx sy r %+.2f %+.2f %+.2f\n" %
	[card, card.global_scale.x, card.global_scale.y, card.global_rotation, card.scale.x, card.scale.y, card.rotation])