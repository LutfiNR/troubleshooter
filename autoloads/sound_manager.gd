extends Node

const SHARED_CREDITS_MUSIC := preload("uid://bfyojtswpuby5")
const IDLE_1_MUSIC := preload("uid://bi1wi3nupbru1")
const IDLE_2_MUSIC := preload("uid://boyisu3l2k7k3")
const MAIN_MENU_MUSIC := preload("uid://dhdjgo7i2tu8a")
const MISSION_1_MUSIC := preload("uid://cac3hktew6w8n")
const MISSION_2_MUSIC := preload("uid://eeb51eomg7rb")
const MISSION_3_MUSIC := preload("uid://blnnpjfbsll7f")

@onready var music_bank: Dictionary = {
	"credits": SHARED_CREDITS_MUSIC,
	"learning_objectif": SHARED_CREDITS_MUSIC,
	"idle1": IDLE_1_MUSIC,
	"idle2": IDLE_2_MUSIC,
	"main_menu": MAIN_MENU_MUSIC,
	"mission1": MISSION_1_MUSIC,
	"mission2": MISSION_2_MUSIC,
	"mission3": MISSION_3_MUSIC,
}

@onready var sfx_bank: Dictionary = {
	"cancel_button_click": preload("uid://dr1j3x44sgymr"),
	"button_click": preload("uid://ccq2x14vtdf1d"),
	"mission_complete": preload("uid://ckia6qr5myo2c"),
	"mission_failed": preload("uid://cvblpg0d3a1q"),
	"plugin_cable": preload("uid://cr3tpg5t7u78v"),
}

const IDLE_MUSIC_KEYS: Array[String] = ["idle1", "idle2"]
const MISSION_MUSIC_KEYS: Array[String] = ["mission1", "mission2", "mission3"]

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var active_music_name: String = ""
var idle_music_index: int = 0
var current_mission_track: String = ""
var current_music_mode: String = "idle"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.chapter_loaded.connect(_on_chapter_loaded)
	GameManager.mission_completed.connect(_on_mission_completed)
	GameManager.mission_loaded.connect(_on_mission_loaded)

	var music_bus_index := AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")

	var sfx_bus_index := AudioServer.get_bus_index("Master")
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_index, "Master")

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	for i in range(8):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SfxPlayer%d" % i
		sfx_player.bus = "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	play_idle_music()


func register_sfx(id: String, stream: AudioStream) -> void:
	sfx_bank[id] = stream


func register_music(id: String, stream: AudioStream) -> void:
	music_bank[id] = stream


func play_sfx(
	id: String,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0,
	force_restart: bool = false,
) -> AudioStreamPlayer:
	if not sfx_bank.has(id):
		push_warning("SoundManager: SFX not found: %s" % id)
		return null

	var player: AudioStreamPlayer = null
	for candidate in sfx_players:
		if not candidate.playing or force_restart:
			player = candidate
			break

	if player == null:
		player = _create_sfx_player()

	player.stream = sfx_bank[id]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	return player


func _on_mission_loaded(_mission: MissionData) -> void:
	play_mission_music()


func _on_mission_completed(_mission_id: String) -> void:
	play_idle_music()


func _on_chapter_loaded(_chapter: ChapterData) -> void:
	play_idle_music()


func _on_music_finished() -> void:
	if current_music_mode == "idle":
		play_idle_music(0.0)
	elif current_music_mode == "mission" and not current_mission_track.is_empty():
		play_music(current_mission_track, 0.0, 0.0)


func play_idle_music(fade_time: float = 0.25) -> void:
	if IDLE_MUSIC_KEYS.is_empty():
		return

	var next_id: String = IDLE_MUSIC_KEYS[idle_music_index]
	idle_music_index = (idle_music_index + 1) % IDLE_MUSIC_KEYS.size()
	current_music_mode = "idle"
	current_mission_track = ""
	play_music(next_id, 0.0, fade_time)


func play_mission_music(fade_time: float = 0.25) -> void:
	if MISSION_MUSIC_KEYS.is_empty():
		return

	var next_id: String = MISSION_MUSIC_KEYS[randi() % MISSION_MUSIC_KEYS.size()]
	current_music_mode = "mission"
	current_mission_track = next_id
	play_music(next_id, 0.0, fade_time)


func play_music(id: String, volume_db: float = 0.0, fade_time: float = 0.25) -> void:
	if not music_bank.has(id):
		push_warning("SoundManager: Music not found: %s" % id)
		return

	if music_player.stream == music_bank[id] and music_player.playing:
		music_player.volume_db = volume_db
		active_music_name = id
		return

	music_player.stream = music_bank[id]
	music_player.volume_db = -80.0
	music_player.play()
	active_music_name = id

	if fade_time > 0.0:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", volume_db, fade_time)
	else:
		music_player.volume_db = volume_db


func stop_music() -> void:
	music_player.stop()
	active_music_name = ""
	current_music_mode = "idle"
	current_mission_track = ""


func stop_all_sfx() -> void:
	for player in sfx_players:
		player.stop()


func set_music_volume(volume_db: float) -> void:
	music_player.volume_db = volume_db


func set_sfx_volume(volume_db: float) -> void:
	for player in sfx_players:
		player.volume_db = volume_db


func pause_music() -> void:
	music_player.stream_paused = true


func resume_music() -> void:
	music_player.stream_paused = false


func _create_sfx_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = "SfxPlayer%d" % sfx_players.size()
	player.bus = "Master"
	add_child(player)
	sfx_players.append(player)
	return player
