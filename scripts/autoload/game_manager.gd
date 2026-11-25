extends Node
## GameManager (Autoload): Quản lý vòng lặp màn chơi, điểm số, thời gian, xếp hạng S/A/B/C,
## hiệu ứng Hit-Stop và cấu hình InputMap tự động cho bàn phím (WASD + J/K/L) và tay cầm.

signal stats_updated(score: int, gold: int, wave_idx: int, total_waves: int)
signal stage_cleared(result_data: Dictionary)
signal endless_run_ended(result_data: Dictionary)
signal player_died
signal boss_spawned(boss_node: Node)

const TOTAL_STAGES := 5

var current_stage_id: int = 1
var current_score: int = 0
var stage_elapsed_time: float = 0.0
var is_stage_active: bool = false
var is_endless_mode: bool = false
var endless_floor: int = 0
var endless_gold_earned: int = 0
var current_wave: int = 0
var total_waves: int = 0
var damage_taken_in_stage: float = 0.0
var _hit_stop_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()


func _process(delta: float) -> void:
	if is_stage_active and not get_tree().paused:
		stage_elapsed_time += delta


## Bắt đầu một màn chơi thường (1-5)
func start_stage(stage_id: int, num_waves: int) -> void:
	is_endless_mode = false
	endless_floor = 0
	endless_gold_earned = 0
	current_stage_id = clampi(stage_id, 1, TOTAL_STAGES)
	current_score = 0
	stage_elapsed_time = 0.0
	damage_taken_in_stage = 0.0
	current_wave = 1
	total_waves = num_waves
	is_stage_active = true
	get_tree().paused = false
	stats_updated.emit(current_score, SaveManager.gold, current_wave, total_waves)


## Bắt đầu chế độ THÁP VÔ TẬN — CỬU THIÊN THÍ LUYỆN THÁP!
func start_endless_tower() -> void:
	is_endless_mode = true
	endless_floor = 1
	endless_gold_earned = 0
	current_score = 0
	stage_elapsed_time = 0.0
	damage_taken_in_stage = 0.0
	current_wave = 1
	total_waves = 999
	is_stage_active = true
	get_tree().paused = false
	stats_updated.emit(current_score, SaveManager.gold, endless_floor, 0)


func set_endless_floor(floor_num: int) -> void:
	endless_floor = floor_num
	current_wave = floor_num
	stats_updated.emit(current_score, SaveManager.gold, endless_floor, 0)


## Cập nhật đợt quái hiện tại
func set_wave(wave_idx: int, max_waves: int) -> void:
	current_wave = wave_idx
	total_waves = max_waves
	stats_updated.emit(current_score, SaveManager.gold, current_wave, total_waves)


## Cộng điểm khi tiêu diệt quái hoặc ăn vật phẩm
func add_score(points: int) -> void:
	current_score += points
	stats_updated.emit(current_score, SaveManager.gold, current_wave, total_waves)


## Hoàn thành màn chơi và tính hạng S / A / B / C dựa trên điểm, thời gian và lượng máu mất
func complete_current_stage(target_time: float = 95.0) -> Dictionary:
	is_stage_active = false
	var time_bonus := maxi(0, int((target_time - stage_elapsed_time) * 15.0))
	var no_damage_bonus := 500 if damage_taken_in_stage <= 5.0 else maxi(0, int(300.0 - damage_taken_in_stage * 2.0))
	var final_score := current_score + time_bonus + no_damage_bonus

	var rank := "C"
	if final_score >= 1600 and stage_elapsed_time <= target_time:
		rank = "S"
	elif final_score >= 1150:
		rank = "A"
	elif final_score >= 700:
		rank = "B"

	var gold_reward := 35 + current_stage_id * 20 + (30 if rank == "S" else (15 if rank == "A" else 0))
	SaveManager.add_gold(gold_reward)
	SaveManager.record_stage_clear(current_stage_id, final_score, stage_elapsed_time, rank, TOTAL_STAGES)
	AudioManager.play_sfx("victory")

	var result := {
		"stage_id": current_stage_id,
		"score": final_score,
		"time": stage_elapsed_time,
		"rank": rank,
		"gold_reward": gold_reward,
		"has_next_stage": current_stage_id < TOTAL_STAGES,
	}
	stage_cleared.emit(result)
	return result


## Xử lý khi người chơi hết máu (Nếu đang leo Tháp Vô Tận -> Hiện Bảng Phong Thần Tháp Vô Tận!)
func notify_player_died() -> void:
	if not is_stage_active:
		return
	is_stage_active = false
	if is_endless_mode:
		var cleared_floors: int = maxi(0, endless_floor - 1)
		var is_new_best: bool = SaveManager.record_endless_floor(cleared_floors, current_score)
		var res := {
			"floor_reached": endless_floor,
			"floors_cleared": cleared_floors,
			"best_floor": SaveManager.best_endless_floor,
			"is_new_record": is_new_best,
			"score": current_score,
			"time": stage_elapsed_time,
			"gold_earned": endless_gold_earned,
		}
		endless_run_ended.emit(res)
		return
	player_died.emit()


## Hiệu ứng Hit-stop: khựng thời gian rất ngắn khi chém trúng để tạo cảm giác lực đánh mạnh
func trigger_hit_stop(duration_sec: float = 0.055, time_scale: float = 0.08) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration_sec, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


## Thiết lập phím bấm tự động (Bàn phím WASD + J/K/L + Phím mũi tên + Tay cầm)
func _setup_input_map() -> void:
	_bind_action_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_action_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_action_keys("move_up", [KEY_W, KEY_UP])
	_bind_action_keys("move_down", [KEY_S, KEY_DOWN])
	_bind_action_keys("attack", [KEY_J, KEY_Z, KEY_SPACE])
	_bind_action_keys("special", [KEY_K, KEY_X])
	_bind_action_keys("ultimate", [KEY_U, KEY_R])
	_bind_action_keys("dash", [KEY_L, KEY_C])
	_bind_action_keys("parry", [KEY_SHIFT, KEY_Q])
	_bind_action_mouse("parry", MOUSE_BUTTON_RIGHT)
	_bind_action_keys("pet_skill", [KEY_F, KEY_V])
	_bind_action_keys("interact", [KEY_E, KEY_ENTER])
	_bind_action_keys("pause", [KEY_ESCAPE, KEY_P])

	# Tay cầm (Gamepad)
	_bind_action_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_action_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_action_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_bind_action_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_bind_action_joy_button("attack", JOY_BUTTON_X)
	_bind_action_joy_button("special", JOY_BUTTON_Y)
	_bind_action_joy_button("ultimate", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_action_joy_button("dash", JOY_BUTTON_A)
	_bind_action_joy_button("parry", JOY_BUTTON_LEFT_SHOULDER)
	_bind_action_joy_button("interact", JOY_BUTTON_B)
	_bind_action_joy_button("pause", JOY_BUTTON_START)


func _bind_action_mouse(action: String, btn: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)


func _bind_action_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _bind_action_joy_button(action: String, btn: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)


func _bind_action_joy_axis(action: String, axis: JoyAxis, axis_val: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_val
	InputMap.action_add_event(action, ev)
