extends Node
## AudioManager (Autoload): Quản lý âm thanh SFX và nhạc nền BGM.
## - Nhạc nền Menu / Làng Cổ Windferry: res://assets/audio/immortal_world.mp3 (âm lượng vừa phải êm dịu).
## - Nhạc Chiến Đấu khi vào màn (Màn 1-5): res://assets/audio/heavenly_battle.mp3 (hào hùng, chuyển cảnh crossfade mượt mà).
## - SFX hành động (chém, parry, tuyệt kỹ, hồi máu...) tự sinh WAV nhẹ sẵn sàng chạy ngay.

const BGM_AMBIENT_PATH := "res://assets/audio/immortal_world.mp3"
const BGM_BATTLE_PATH := "res://assets/audio/heavenly_battle.mp3"
const BGM_AMBIENT_DB: float = -12.5 # Âm lượng vừa phải, êm dịu cho nhạc nền Immortal World
const BGM_BATTLE_DB: float = -10.0  # Âm lượng cân bằng khí thế cho nhạc chiến đấu Heavenly

var custom_streams: Dictionary = {} # Ví dụ: {"slash": preload("res://assets/audio/slash.wav")}
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var _bgm_fade_player: AudioStreamPlayer
var _bgm_streams: Dictionary = {}
var _current_bgm_track: String = ""
var _bgm_tween: Tween
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
	_bgm_player.volume_db = BGM_AMBIENT_DB
	add_child(_bgm_player)

	_bgm_fade_player = AudioStreamPlayer.new()
	_bgm_fade_player.volume_db = -40.0
	add_child(_bgm_fade_player)

	_generate_placeholder_sfx()
	_preload_bgm_tracks()
	# Phát ngay nhạc nền Immortal World khi vừa vào game / Menu chính
	play_bgm("ambient", false)


## Nạp 2 bản nhạc nền MP3 chính thức (hỗ trợ cả chạy trực tiếp từ Editor lẫn bản Export)
func _preload_bgm_tracks() -> void:
	var amb := _load_mp3_stream(BGM_AMBIENT_PATH)
	if amb:
		_bgm_streams["ambient"] = amb
	var bat := _load_mp3_stream(BGM_BATTLE_PATH)
	if bat:
		_bgm_streams["battle"] = bat


func _load_mp3_stream(res_path: String) -> AudioStream:
	if ResourceLoader.exists(res_path):
		var loaded := ResourceLoader.load(res_path) as AudioStream
		if loaded != null:
			if loaded is AudioStreamMP3:
				(loaded as AudioStreamMP3).loop = true
			return loaded
	if FileAccess.file_exists(res_path):
		var raw: PackedByteArray = FileAccess.get_file_as_bytes(res_path)
		if raw.size() > 0:
			var mp3 := AudioStreamMP3.new()
			mp3.data = raw
			mp3.loop = true
			return mp3
	return null


## Chuyển nhạc nền mượt mà (Crossfade 0.85s):
## - track_id = "ambient" -> immortal_world.mp3 (Menu, Làng Cổ Windferry, nghỉ ngơi)
## - track_id = "battle"  -> heavenly_battle.mp3 (Bắt đầu vào màn chiến đấu 1-5)
func play_bgm(track_id: String, force_restart: bool = false) -> void:
	if not bgm_enabled:
		return
	var stream: AudioStream = _bgm_streams.get(track_id, null)
	if stream == null:
		# Fallback về hợp âm nền nhẹ nếu thiếu file
		var fallback_key := "bgm_" + track_id
		if not _cached_wavs.has(fallback_key):
			_cached_wavs[fallback_key] = _make_chord_wav(185.0 if track_id == "ambient" else 146.8, 3.2)
		stream = _cached_wavs[fallback_key]

	var target_db: float = BGM_BATTLE_DB if track_id == "battle" else BGM_AMBIENT_DB
	if _current_bgm_track == track_id and _bgm_player.playing and not force_restart:
		# Đã đang phát đúng bản nhạc này -> giữ nguyên không ngắt quãng
		return

	_current_bgm_track = track_id
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()

	# Nếu đang có nhạc cũ phát -> chuyển sang kênh fade out để crossfade mượt mà
	if _bgm_player.playing and _bgm_player.stream != null:
		var old_stream := _bgm_player.stream
		var old_pos := _bgm_player.get_playback_position()
		var old_db := _bgm_player.volume_db
		_bgm_fade_player.stream = old_stream
		_bgm_fade_player.volume_db = old_db
		_bgm_fade_player.play(old_pos)

	_bgm_player.stream = stream
	_bgm_player.volume_db = -36.0
	_bgm_player.play(0.0)

	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	_bgm_tween.tween_property(_bgm_player, "volume_db", target_db, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _bgm_fade_player.playing:
		_bgm_tween.tween_property(_bgm_fade_player, "volume_db", -42.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_bgm_tween.chain().tween_callback(func() -> void: _bgm_fade_player.stop())


## Giữ hàm tương thích cũ -> phát nhạc nền Immortal World
func play_stage_ambience(_theme_name: String) -> void:
	play_bgm("ambient", false)


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
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = pitch_scale
	_sfx_players[0].play()


func stop_bgm() -> void:
	_current_bgm_track = ""
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if _bgm_player:
		_bgm_player.stop()
	if _bgm_fade_player:
		_bgm_fade_player.stop()


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
	wav.format = 1 as AudioStreamWAV.Format
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
	wav.format = 1 as AudioStreamWAV.Format
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = 1 as AudioStreamWAV.LoopMode
	wav.loop_begin = 0
	wav.loop_end = samples
	wav.data = data
	return wav
