extends Node
## AudioManager (Autoload): Quản lý âm thanh SFX và nhạc nền BGM.
## Sử dụng AudioStreamGenerator / WAV tự sinh để game chạy có tiếng ngay mà không cần file âm thanh ngoài.
## Khi có file .ogg / .wav thật trong res://assets/audio/, chỉ cần gán vào dictionary custom_streams.

var custom_streams: Dictionary = {} # Ví dụ: {"slash": preload("res://assets/audio/slash.wav")}
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var _cached_wavs: Dictionary = {}
var sfx_enabled: bool = true
var bgm_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_sfx_players.append(p)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -14.0
	add_child(_bgm_player)

	_generate_placeholder_sfx()


## Phát hiệu ứng âm thanh theo tên: "slash", "special", "hit", "hurt", "dash", "pickup", "gate", "victory", "boss_roar"
func play_sfx(sfx_name: String, pitch_scale: float = 1.0) -> void:
	if not sfx_enabled:
		return
	var stream: AudioStream = custom_streams.get(sfx_name, _cached_wavs.get(sfx_name, null))
	if stream == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch_scale * randf_range(0.95, 1.05)
			p.play()
			return
	# Nếu tất cả kênh đều bận thì dùng kênh đầu tiên
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = pitch_scale
	_sfx_players[0].play()


## Phát âm báo theo chủ đề màn chơi
func play_stage_ambience(theme_name: String) -> void:
	if not bgm_enabled:
		return
	var key := "bgm_" + theme_name
	if not _cached_wavs.has(key):
		var base_freq := 220.0 if theme_name == "golden_hour" else (146.8 if theme_name == "midnight" else (185.0 if theme_name == "blue_night" else 165.0))
		_cached_wavs[key] = _make_chord_wav(base_freq, 3.2)
	_bgm_player.stream = _cached_wavs[key]
	_bgm_player.play()


func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()


func _generate_placeholder_sfx() -> void:
	_cached_wavs["slash"] = _make_synth_wav(520.0, 180.0, 0.11, 0.35)
	_cached_wavs["special"] = _make_synth_wav(280.0, 880.0, 0.28, 0.25)
	_cached_wavs["hit"] = _make_synth_wav(190.0, 75.0, 0.10, 0.45)
	_cached_wavs["hurt"] = _make_synth_wav(160.0, 60.0, 0.18, 0.50)
	_cached_wavs["dash"] = _make_synth_wav(340.0, 620.0, 0.10, 0.20)
	_cached_wavs["pickup"] = _make_synth_wav(580.0, 960.0, 0.12, 0.05)
	_cached_wavs["gate"] = _make_synth_wav(330.0, 660.0, 0.35, 0.10)
	_cached_wavs["victory"] = _make_synth_wav(440.0, 880.0, 0.45, 0.05)
	_cached_wavs["boss_roar"] = _make_synth_wav(130.0, 55.0, 0.45, 0.55)


func _make_synth_wav(freq_start: float, freq_end: float, duration: float, noise_mix: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var samples := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0

	for i in range(samples):
		var t := float(i) / float(samples)
		var env := (1.0 - t) * (1.0 - t)
		var freq := lerpf(freq_start, freq_end, t)
		phase += freq / float(mix_rate)
		var tone := sin(phase * TAU)
		var noise := randf_range(-1.0, 1.0)
		var val := (tone * (1.0 - noise_mix) + noise * noise_mix) * env * 0.45
		var pcm := clampi(int(val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, pcm)

	var wav := AudioStreamWAV.new()
	wav.format = 1 as AudioStreamWAV.Format # 1 = FORMAT_16_BIT (tương thích mọi phiên bản Godot 4.x)
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav


func _make_chord_wav(root_freq: float, duration: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var samples := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(mix_rate)
		var fade := sin(clampf(t / duration, 0.0, 1.0) * PI)
		var s := (
			sin(t * root_freq * TAU) * 0.45
			+ sin(t * root_freq * 1.2 * TAU) * 0.30
			+ sin(t * root_freq * 1.5 * TAU) * 0.25
		) * fade * 0.25
		var pcm := clampi(int(s * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, pcm)

	var wav := AudioStreamWAV.new()
	wav.format = 1 as AudioStreamWAV.Format # 1 = FORMAT_16_BIT
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = 1 as AudioStreamWAV.LoopMode # 1 = LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	wav.data = data
	return wav
