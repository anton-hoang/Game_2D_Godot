class_name CameraRig3D
extends Node3D
## Camera 3D phong cách HD-2D Octopath Traveler:
## - Góc nghiêng 33 độ, FOV nhỏ (28 độ) để tạo hiệu ứng diorama / tilt-shift.
## - Di chuyển mượt theo Player bằng lerp.
## - Rung nhẹ (screen shake) khi chém trúng quái hoặc bị thương.

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0.0, 11.5, 17.5)
@export var pitch_degrees: float = -33.0
@export var camera_fov: float = 28.0
@export var smooth_speed: float = 7.5
@export var limit_x: Vector2 = Vector2(-15.5, 15.5)
@export var limit_z: Vector2 = Vector2(-14.5, 8.5)

var target: Node3D
var camera: Camera3D
var _shake_intensity: float = 0.0
var _shake_time: float = 0.0


func _ready() -> void:
	if not target_path.is_empty():
		target = get_node_or_null(target_path)

	camera = get_node_or_null("Camera3D")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	camera.fov = camera_fov
	camera.near = 0.2
	camera.far = 150.0
	camera.position = follow_offset
	camera.rotation_degrees = Vector3(pitch_degrees, 0.0, 0.0)

	# Gắn Depth of Field (Tilt-Shift) trực tiếp vào CameraAttributesPractical
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 24.0
	attrs.dof_blur_far_transition = 8.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 11.5
	attrs.dof_blur_near_transition = 4.0
	attrs.dof_blur_amount = 0.11
	camera.attributes = attrs


func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var desired := target.global_position
		desired.x = clampf(desired.x, limit_x.x, limit_x.y)
		desired.z = clampf(desired.z, limit_z.x, limit_z.y)
		desired.y = target.global_position.y * 0.4
		global_position = global_position.lerp(desired, clampf(smooth_speed * delta, 0.0, 1.0))

	if _shake_time > 0.0:
		_shake_time -= delta
		var offset := Vector3(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity),
			0.0
		)
		camera.position = follow_offset + offset
	else:
		camera.position = camera.position.lerp(follow_offset, clampf(15.0 * delta, 0.0, 1.0))


## Gọi hàm này khi đánh trúng quái hoặc nhận sát thương để rung camera
func shake(intensity: float = 0.16, duration: float = 0.12) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_time = maxf(_shake_time, duration)


## Bật/tắt hiệu ứng Tilt-Shift Depth of Field (phím G)
func toggle_dof() -> bool:
	var attrs := camera.attributes as CameraAttributesPractical
	if attrs == null:
		return false
	attrs.dof_blur_far_enabled = not attrs.dof_blur_far_enabled
	attrs.dof_blur_near_enabled = attrs.dof_blur_far_enabled
	return attrs.dof_blur_far_enabled
