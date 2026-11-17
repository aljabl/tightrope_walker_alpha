extends Node3D
## Single-player Godot scene for the four-tower tightrope course.

const Rules := preload("res://scripts/tightrope_rules.gd")
const HudScene := preload("res://scripts/game_hud.gd")
const BirdScene := preload("res://assets/actg/swamphen/australasian_swamphen.glb")
const FlagScene := preload("res://assets/quaternius/flag/flag.glb")
const VignetteShader := preload("res://shaders/vignette.gdshader")
const NightSkyShader := preload("res://shaders/night_sky.gdshader")
const BIRD_FLY_ANIMATION := "australasian_swamphen_fly"
const INTRO_DURATION := 9.2
const INTRO_SKIP_DURATION := 0.65
const INTRO_START_POSITION := Vector3(18.0, 64.0, -250.0)
const INTRO_START_LOOK := Vector3(0.0, 52.0, -270.0)
const FEET_Y := 45.0
const STREET_SURFACE_Y := -12.0
const RESPAWN_FEET_Y := STREET_SURFACE_Y + 0.8
const FALL_GRAVITY := 26.0
const ROPE_Y := 44.87
const STATIC_SAG := 0.25
const LOAD_SAG := 1.5
const ROPE_SEGMENTS := 26
const ROPE_RADIUS := 0.045
const BALANCE_POLE_RADIUS := 0.055
const ROPE_COLOR := Color("b5a38b")
const HOT_COLOR := Color("ff5c46")
const ROPE_BASE_EMISSION := 0.4
const ROPE_HOT_EMISSION := 1.0
const POLE_WAIST_Y := 1.9
const POLE_FRONT_Z := -0.45
const POLE_HAND_SPACING := 0.65
const BIRD_HOVER_HEIGHT := 3.5
const BIRD_NIGHT_EMISSION := Color("c7d4ff")
const BIRD_NIGHT_GLOW := 0.6
const BIRD_MARKER_HEIGHT := 0.7
const CENTER_BIRD_MARKER_COLOR := Color("ffca62")
const FLANKER_MARKER_COLOR := Color("fff4e4")
const BIRD_TIMER_GAP_PIXELS := 5.0
const GUST_TIMER_GAP_PIXELS := 8.0
const GUST_TIMER_WIDTH := 100.0
const SNOW_GUST_GRAVITY := 28.0
const SNOW_BURST_DURATION := 0.8
const WINDOW_GLOW_ENERGY := 3.8
const LIT_WINDOW_CHANCE := 0.62
const DARK_WINDOW_COLOR := Color("4b5c86ff")
const STREETLAMP_GLOW_ENERGY := 5.5
const HEADLIGHT_GLOW_ENERGY := 6.0
const TAILLIGHT_GLOW_ENERGY := 4.8
const BEACON_BUILDING_INDICES := [3, 8, 14, 19]
const RED_BEACON_PERIOD := 1.5
const RED_BEACON_FLASH_DURATION := 0.24
const SKY_TOP_COLORS := ["2377c9", "674790", "08091b"]
const SKY_MID_COLORS := ["65b5ee", "e87ca4", "0d1030"]
const SKY_HORIZON_COLORS := ["c9ecff", "ffad62", "12122c"]
const SUN_ELEVATIONS := [20.0, 7.0, -12.0, -12.0]
const MOON_ELEVATIONS := [-3.0, -3.0, 6.0, 24.0]
const AMBIENT_COLORS := ["b8d9ff", "ffc1a8", "5c5c9c"]
const KEY_LIGHT_COLORS := ["fff0d1", "ffb577", "b5bbff"]
const KEY_LIGHT_ENERGIES := [1.1, 0.72, 0.2]
const AMBIENT_ENERGIES := [0.65, 0.43, 0.10]
const DARKNESS_ALPHAS := [0.0, 0.04, 0.22]
const FOG_DENSITIES := [0.28, 0.65, 1.0]
const FOG_DEPTH_BEGINS := [120.0, 80.0, 45.0]
const FOG_DEPTH_ENDS := [700.0, 570.0, 400.0]
const FOG_HEIGHT_DENSITIES := [0.012, 0.025, 0.04]
const LIT_SOURCE_GLOW_FACTORS := [0.04, 0.35, 1.0]
const STAGE_SKY_BLEND_SPEED := 0.8
const ROOF_SPIKE_COLOR := Color("7c829e")
const SNOW_LAYER_THICKNESS := 0.22
const GROUND_SNOW_THICKNESS := 0.08
const STREET_WIDTH := 52.0
const SIDEWALK_WIDTH := 9.0
const SIDEWALK_CENTER_X := (STREET_WIDTH + SIDEWALK_WIDTH) * 0.5
const SIDEWALK_SURFACE_Y := STREET_SURFACE_Y + 0.5 + GROUND_SNOW_THICKNESS
const TRAFFIC_LANE_X := 13.0
const CITY_GROUND_FAR_Z := -1140.0
const CITY_GROUND_NEAR_Z := 300.0
const CITY_GROUND_WIDTH := 500.0
const CITY_GROUND_LENGTH := CITY_GROUND_NEAR_Z - CITY_GROUND_FAR_Z
const CITY_GROUND_CENTER_Z := (CITY_GROUND_NEAR_Z + CITY_GROUND_FAR_Z) * 0.5
const TRAFFIC_START_Z := -680.0
const TRAFFIC_END_Z := 50.0
const TRAFFIC_SPAWN_Z := [
	-635.0, -617.0, -568.0, -539.0, -493.0, -477.0,
	-407.0, -390.0, -347.0, -312.0, -269.0, -243.0,
	-198.0, -160.0, -119.0, -91.0, -41.0, -18.0,
]
var rules: TightropeRules
var hud: GameHUD
var camera: Camera3D
var walker: Node3D
var walker_model: Node3D
var walker_animation: AnimationPlayer
var walker_skeleton: Skeleton3D
var kenney_decor_count := 0
var pole: MeshInstance3D
var ropes: Array = []
var birds: Array[Node3D] = []
var gust_flag: Node3D
var snow: CPUParticles3D
var gust_snow: CPUParticles3D
var traffic_lights: Array[Node3D] = []
var _static_light_halos: Array[Dictionary] = []
var _red_beacons: Array[Dictionary] = []
var _emissive_materials: Array[Dictionary] = []
var _halo_materials: Array[Dictionary] = []
var _local_lights: Array[Dictionary] = []
var _lit_source_glow_factor := 1.0
var _red_beacon_elapsed := 0.0
var _sky_stage := 0.0
var _last_atmosphere_stage := -1.0
var _last_atmosphere_z := INF
var _sky_material: ShaderMaterial
var _world_environment: Environment
var _key_light: DirectionalLight3D
var _moon_glow: DirectionalLight3D
var _darkness: ColorRect
var _halo_material: StandardMaterial3D
var _halo_quad: QuadMesh
var _snow_gust_active := false
var _bird_snow_remaining := 0.0
var _bird_snow_direction := 0
var _bird_snow_burst_pending := false
var visual_z := Rules.step_z(1, 0)
var step_from := Rules.step_z(1, 0)
var step_to := Rules.step_z(1, 0)
var step_elapsed := 0.0
var step_duration := 0.0
var step_result := ""
var last_step_foot := ""
var has_taken_first_step := false
var fall_elapsed := 0.0
var fall_start_position := Vector3.ZERO
var fall_started := false
var fall_ready_to_respawn := false
var intro_elapsed := 0.0
var intro_skip_elapsed := 0.0
var intro_skip_from_position := Vector3.ZERO
var intro_skip_from_look := Vector3.ZERO
var outro_elapsed := 0.0
var mode := "intro"
var paused := false
var best_time := INF
var camera_position := Vector3.ZERO
var camera_look := Vector3.ZERO
var camera_wind_sway := 0.0
var camera_bird_gust_remaining := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_install_input_actions()
	rules = Rules.new()
	visual_z = Rules.step_z(1, 0)
	_build_world()
	_update_ropes()
	_update_atmosphere(0.0)
	_update_walker(0.0)
	camera_position = INTRO_START_POSITION
	camera_look = INTRO_START_LOOK
	camera.position = camera_position
	camera.look_at(camera_look)
	hud = HudScene.new()
	hud.layer = 3
	add_child(hud)
	hud.replay_requested.connect(_restart)
	hud.stargaze_requested.connect(_stargaze)
	hud.pause_requested.connect(_toggle_pause)
	hud.show_title()


func _process(delta: float) -> void:
	var dt := minf(delta, 0.1)
	if Input.is_action_just_pressed("pause_run"):
		_toggle_pause()
	if Input.is_action_just_pressed("restart_run"):
		_restart()
	if paused:
		return
	_update_red_beacons(delta)
	if mode == "intro":
		intro_elapsed += dt
		# The title screen waits for the player. The camera pan finishes on its
		# own and holds; Space (or a step key after two seconds) starts the run.
		if Input.is_action_just_pressed("skip_intro") or (_step_pressed() and intro_elapsed >= 2.0):
			_start_intro_skip()
		elif intro_elapsed >= INTRO_DURATION and not hud.is_title_visible():
			_finish_intro()
	elif mode == "intro_skip":
		intro_skip_elapsed += dt
	elif mode == "outro":
		outro_elapsed += dt
		if _step_pressed() and outro_elapsed >= 2.0 or outro_elapsed >= 13.0:
			mode = "stargaze"
			hud.show_caption("The stars kept their promise.")
	elif mode == "walking":
		if Input.is_action_just_pressed("step_left"):
			_step("left")
		elif Input.is_action_just_pressed("step_right"):
			_step("right")
		elif Input.is_action_just_pressed("step"):
			_step()
		if Input.is_action_just_pressed("release"):
			_release()
		if rules.state == "walking":
			for event in rules.update(dt, _lean_input(), _gust_response_input()):
				match event["type"]:
					"birds_pass": hud.show_toast("PASS", 1.0)
					"bird_gust": _queue_bird_snow_burst(int(event["dir"]))
					"gust_pass": hud.show_toast("PASS", 1.0)
					"fall":
						_start_fall()
						step_duration = 0.0
						hud.show_toast("FAIL" if event["reason"] == "snap" else "MISS", 1.0)
						if walker_animation != null:
							walker_animation.stop()
		if rules.state == "falling":
			if not fall_started:
				_start_fall()
			if fall_ready_to_respawn or (fall_elapsed > 0.0 and Input.is_action_just_pressed("skip_fall")):
				rules.respawn()
				visual_z = Rules.step_z(rules.tower, 0)
				fall_elapsed = 0.0
				fall_started = false
				fall_ready_to_respawn = false
				_play_walker_animation("idle")
				_show_tower_title()
			else:
				fall_elapsed += dt
	_update_step(dt)
	_update_atmosphere(dt)
	_update_traffic(dt)
	_update_walker(dt)
	_update_birds()
	_update_ropes()
	_update_camera(dt)
	_update_gust_visual()
	_update_reaction_timer()
	snow.position = camera.position + Vector3(0.0, 16.0, -18.0)
	_update_snowfall(dt)
	_update_hud()


func _update_red_beacons(dt: float) -> void:
	_red_beacon_elapsed = fmod(_red_beacon_elapsed + dt, RED_BEACON_PERIOD)
	for beacon in _red_beacons:
		var flashing: bool = fmod(_red_beacon_elapsed + beacon["phase"], RED_BEACON_PERIOD) < RED_BEACON_FLASH_DURATION
		var bulb: MeshInstance3D = beacon["bulb"]
		if bulb.visible == flashing:
			continue
		var light: OmniLight3D = beacon["light"]
		var halo: MeshInstance3D = beacon["halo"]
		var snow_glow: MeshInstance3D = beacon["snow_glow"]
		var cap_glow: MeshInstance3D = beacon["cap_glow"]
		bulb.visible = flashing
		light.visible = flashing
		halo.visible = flashing
		snow_glow.visible = flashing
		cap_glow.visible = flashing


func _step(foot: String = "") -> void:
	if mode != "walking" or paused or step_duration > 0.0 or rules.state != "walking":
		return
	var result := rules.try_step()
	if result == "blocked" or result == "cooldown":
		return
	if not has_taken_first_step:
		has_taken_first_step = true
	if foot.is_empty():
		foot = "right" if last_step_foot == "left" else "left"
	last_step_foot = foot
	step_from = visual_z
	step_to = Rules.step_z(rules.tower, rules.step)
	if result == "won":
		step_to = Rules.step_z(Rules.TOWER_COUNT, Rules.STEPS_PER_TOWER)
	var step_distance := absf(step_to - step_from)
	step_duration = 1.2 if step_distance > 15.0 else (0.6 if step_distance > 8.0 else 0.4)
	step_elapsed = 0.0
	step_result = result
	_play_walker_animation("walk")
	if walker_animation != null and walker_animation.has_animation("walk"):
		var walk := walker_animation.get_animation("walk")
		walker_animation.seek(walk.length * (0.5 if foot == "right" else 0.0), true)


func _release() -> void:
	if mode == "walking" and not paused and rules.release() == "released":
		hud.show_toast("PASS", 1.0)


func _start_intro_skip() -> void:
	hud.hide_title()
	intro_skip_elapsed = 0.0
	intro_skip_from_position = camera_position
	intro_skip_from_look = camera_look
	mode = "intro_skip"


func _finish_intro() -> void:
	hud.hide_title()
	mode = "walking"
	_show_tower_title()


func _restart() -> void:
	hud.hide_title()
	paused = false
	mode = "walking"
	rules = Rules.new()
	visual_z = Rules.step_z(1, 0)
	last_step_foot = ""
	has_taken_first_step = false
	_play_walker_animation("idle")
	step_duration = 0.0
	fall_elapsed = 0.0
	fall_started = false
	fall_ready_to_respawn = false
	camera_wind_sway = 0.0
	camera_bird_gust_remaining = 0.0
	hud.set_paused(false)
	hud.hide_win()
	hud.hide_toast()
	hud.hide_countdown_bar()
	hud.hide_wire_countdown_bar()
	gust_flag.hide()
	gust_snow.emitting = false
	gust_snow.hide()
	_snow_gust_active = false
	_bird_snow_remaining = 0.0
	_bird_snow_direction = 0
	_bird_snow_burst_pending = false
	_sky_stage = 0.0
	_update_atmosphere(0.0)
	hud.show_caption("")
	_show_tower_title()


func _start_fall() -> void:
	fall_elapsed = 0.0
	fall_start_position = walker.position
	fall_started = true
	fall_ready_to_respawn = false


func _stargaze() -> void:
	if rules.state != "won":
		return
	mode = "outro"
	outro_elapsed = 0.0
	hud.hide_win()
	hud.show_caption("You made it. Four towers, three crossings, no looking back.")


func _toggle_pause() -> void:
	if mode != "walking" or rules.state == "falling":
		return
	paused = not paused
	hud.set_paused(paused)
	_update_hud()


func _lean_input() -> float:
	return Input.get_axis("lean_left", "lean_right")


func _gust_response_input() -> int:
	if Input.is_action_just_pressed("lean_left"):
		return -1
	if Input.is_action_just_pressed("lean_right"):
		return 1
	return 0


func _step_pressed() -> bool:
	return Input.is_action_just_pressed("step_left") or Input.is_action_just_pressed("step_right") or Input.is_action_just_pressed("step")


func _update_step(dt: float) -> void:
	if step_duration <= 0.0:
		return
	step_elapsed += dt
	var progress := clampf(step_elapsed / step_duration, 0.0, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	visual_z = lerpf(step_from, step_to, eased)
	if progress >= 1.0:
		step_duration = 0.0
		_play_walker_animation("idle")
		if rules.step == 1 and not rules.on_rope:
			rules.reach_rope()
		if step_result == "tower":
			rules.reach_tower()
			_show_tower_title()
		elif step_result == "won":
			best_time = minf(best_time, rules.finish_time)
			hud.show_win(rules.finish_time, rules.falls, best_time)


func _update_walker(dt: float) -> void:
	if walker_animation != null:
		walker_animation.advance(dt)
	var rope := Rules.rope_at(visual_z)
	var feet := Vector3(0.0, FEET_Y, visual_z)
	if not rope.is_empty() and rules.state != "falling":
		var s: float = rope["progress"]
		var tower_number := int(rope["tower"])
		var sag := STATIC_SAG * 4.0 * s * (1.0 - s)
		var load_sag := _load_rope_sag(tower_number) * 4.0 * s * (1.0 - s) * (1.0 - 0.55 * rules.tension)
		feet.y -= (sag + load_sag) * _rope_sag_factor(rope, tower_number)
		feet.x = rules.tilt * 0.35
	if rules.state == "falling":
		if not fall_started:
			_start_fall()
		var falling_y := fall_start_position.y - 0.5 * FALL_GRAVITY * fall_elapsed * fall_elapsed
		feet.y = maxf(RESPAWN_FEET_Y, falling_y)
		feet.x = fall_start_position.x + rules.fall_dir * fall_elapsed * 3.0
		if falling_y <= RESPAWN_FEET_Y:
			fall_ready_to_respawn = true
	walker.position = feet
	walker.rotation.z = -rules.tilt * deg_to_rad(30.0)
	pole.rotation.z = PI * 0.5 + rules.tilt * deg_to_rad(12.0)
	_pose_walker_hands()


func _pose_walker_hands() -> void:
	if walker_skeleton == null:
		return
	for side in [-1.0, 1.0]:
		var shoulder_name := "LeftShoulder" if side < 0.0 else "RightShoulder"
		var hand_name := "LeftHand" if side < 0.0 else "RightHand"
		var shoulder_index := walker_skeleton.find_bone(shoulder_name)
		var hand_index := walker_skeleton.find_bone(hand_name)
		if shoulder_index < 0 or hand_index < 0:
			continue
		var shoulder_pose := walker_skeleton.get_bone_global_pose(shoulder_index)
		var hand_position := walker_skeleton.get_bone_global_pose(hand_index).origin
		var grip_world := pole.to_global(Vector3(0.0, -side * POLE_HAND_SPACING, 0.0))
		var grip_local := walker_skeleton.to_local(grip_world)
		var current_direction := (hand_position - shoulder_pose.origin).normalized()
		var grip_direction := (grip_local - shoulder_pose.origin).normalized()
		shoulder_pose.basis = Basis(Quaternion(current_direction, grip_direction)) * shoulder_pose.basis
		walker_skeleton.set_bone_global_pose(shoulder_index, shoulder_pose)


func _update_birds() -> void:
	var active := rules.birds_enabled() and (rules.bird_phase == "approach" or rules.bird_phase == "warn") and rules.state == "walking"
	for index in birds.size():
		var bird := birds[index]
		bird.visible = active
		if active:
			var hover_position := walker.position + Vector3((index - 1) * 2.8, BIRD_HOVER_HEIGHT, -5.0)
			if rules.bird_phase == "approach":
				var entry_position := hover_position + camera.global_transform.basis.x * (rules.bird_entry_side * 24.0) + camera.global_transform.basis.y * 13.0
				var progress := 1.0 - clampf(rules.bird_timer / Rules.BIRD_APPROACH, 0.0, 1.0)
				bird.position = entry_position.lerp(hover_position, smoothstep(0.0, 1.0, progress))
				bird.rotation.y = PI * 0.5 * rules.bird_entry_side
			else:
				bird.position = hover_position
				bird.rotation.y = -PI * 0.5 * rules.bird_dirs[index]


## The swamphen model is dark plumage. Give every surface a pale emission that the
## atmosphere scales with darkness (off in daylight, full at night) so the birds
## stay readable against the night sky without changing the minigame.
func _brighten_bird_for_night(bird: Node3D) -> void:
	for found in bird.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := found as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			material.emission_enabled = true
			material.emission = BIRD_NIGHT_EMISSION
			material.emission_energy_multiplier = BIRD_NIGHT_GLOW * _lit_source_glow_factor
			mesh_instance.set_surface_override_material(surface, material)
			_emissive_materials.append({"material": material, "energy": BIRD_NIGHT_GLOW})


## A flat arrowhead above each bird pointing the way the bird faces (local -Z), so
## the direction reads by shape, not only by the model's pose or colour. The centre
## bird's marker is larger and gold; the flankers' are smaller and cream.
func _bird_direction_marker(is_center: bool) -> MeshInstance3D:
	var size := 0.42 if is_center else 0.3
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.0, -size * 1.3),
		Vector3(0.0, size * 0.5, 0.0),
		Vector3(0.0, -size * 0.5, 0.0),
	])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var marker := MeshInstance3D.new()
	marker.name = "Direction Marker"
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = CENTER_BIRD_MARKER_COLOR if is_center else FLANKER_MARKER_COLOR
	marker.material_override = material
	marker.position = Vector3(0.0, BIRD_MARKER_HEIGHT, 0.0)
	return marker


func _update_gust_visual() -> void:
	gust_flag.hide()
	if mode != "walking":
		return
	hud.show_caption("")
	if rules.state != "walking" or not rules.on_rope:
		return
	if rules.wind_phase == "cue" or rules.wind_phase == "react":
		gust_flag.position.x = float(rules.wind_flag_side) * 4.5
		gust_flag.show()


func _update_reaction_timer() -> void:
	if rules.state != "walking":
		hud.hide_countdown_bar()
		hud.hide_wire_countdown_bar()
		return
	if rules.on_rope and rules.tension_enabled() and rules.tension >= Rules.TENSION_COUNTDOWN_START:
		hud.show_wire_countdown_bar((1.0 - rules.tension) / (1.0 - Rules.TENSION_COUNTDOWN_START))
	else:
		hud.hide_wire_countdown_bar()
	if rules.birds_enabled() and rules.bird_phase == "warn":
		var center_position := birds[1].global_position
		if camera.is_position_behind(center_position):
			hud.hide_countdown_bar()
			return
		var screen_position := camera.unproject_position(center_position)
		if not get_viewport().get_visible_rect().has_point(screen_position):
			hud.hide_countdown_bar()
			return
		var left_position := camera.unproject_position(birds[0].global_position)
		var right_position := camera.unproject_position(birds[2].global_position)
		var timer_position := Vector2((left_position.x + right_position.x) * 0.5, screen_position.y + BIRD_TIMER_GAP_PIXELS)
		var timer_width := absf(right_position.x - left_position.x) * 0.5
		hud.show_countdown_bar(timer_position, timer_width, rules.bird_timer / Rules.BIRD_WARN)
	elif rules.on_rope and rules.wind_phase == "react":
		var flag_position := gust_flag.global_position
		if camera.is_position_behind(flag_position):
			hud.hide_countdown_bar()
			return
		var screen_position := camera.unproject_position(flag_position)
		hud.show_countdown_bar(screen_position + Vector2(0.0, GUST_TIMER_GAP_PIXELS), GUST_TIMER_WIDTH, rules.wind_timer / Rules.WIND_RESPONSE_TIME)
	else:
		hud.hide_countdown_bar()


func _queue_bird_snow_burst(direction: int) -> void:
	_bird_snow_direction = signi(direction)
	_bird_snow_remaining = SNOW_BURST_DURATION
	_bird_snow_burst_pending = true
	camera_bird_gust_remaining = Rules.BIRD_GUST_DURATION


func _update_snowfall(dt: float = 0.0) -> void:
	var gust_strength := 0.0
	var wind_blow_active := mode == "walking" and rules.state == "walking" and rules.on_rope and rules.wind_phase == "blow"
	var burst_direction := rules.wind_dir
	if _bird_snow_remaining > 0.0:
		burst_direction = _bird_snow_direction
		gust_strength = 1.0
	elif wind_blow_active:
		gust_strength = 0.4 + 0.6 * rules.wind_ramp
	snow.direction = Vector3(float(burst_direction) * 2.0 * gust_strength, -1.0, 0.0).normalized()
	snow.gravity = Vector3(float(burst_direction) * SNOW_GUST_GRAVITY * gust_strength, -2.0, 0.0)
	gust_snow.position = camera.position - camera.global_transform.basis.z * 8.0 + camera.global_transform.basis.y
	gust_snow.direction = Vector3(float(burst_direction), -0.15, 0.0).normalized()
	gust_snow.gravity = Vector3(float(burst_direction) * 6.0, -2.0, 0.0)
	if _bird_snow_burst_pending or (wind_blow_active and not _snow_gust_active):
		gust_snow.show()
		gust_snow.emitting = true
		gust_snow.restart()
	_bird_snow_burst_pending = false
	_snow_gust_active = wind_blow_active
	_bird_snow_remaining = maxf(0.0, _bird_snow_remaining - dt)


func _update_ropes() -> void:
	var current := Rules.rope_at(visual_z)
	for index in range(Rules.TOWER_COUNT):
		var segments: Array = ropes[index]
		var previous := _roof_anchor_point(index + 1)
		for part in range(ROPE_SEGMENTS + 1):
			var s := float(part) / ROPE_SEGMENTS
			var next := _rope_point(index + 1, s, current)
			var segment: MeshInstance3D = segments[part]
			var direction := next - previous
			segment.position = (next + previous) * 0.5
			segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
			var cylinder: CylinderMesh = segment.mesh
			cylinder.height = direction.length() + 0.06
			var material: StandardMaterial3D = segment.material_override
			var heat: float = rules.tension * rules.tension if index + 1 == rules.tower else 0.0
			material.albedo_color = ROPE_COLOR.lerp(HOT_COLOR, heat)
			material.emission = material.albedo_color
			material.emission_energy_multiplier = lerpf(ROPE_BASE_EMISSION, ROPE_HOT_EMISSION, heat) * _lit_source_glow_factor
			previous = next


func _roof_anchor_point(tower_number: int) -> Vector3:
	return Vector3(0.0, ROPE_Y, Rules.tower_z(tower_number) - Rules.ROPE_ROOF_ANCHOR_OFFSET)


func _rope_point(tower_number: int, s: float, current: Dictionary) -> Vector3:
	var z := Rules.tower_z(tower_number) - Rules.ROPE_START_OFFSET - s * Rules.ROPE_LENGTH
	var sag_factor := _rope_sag_factor(current, tower_number)
	var y := ROPE_Y - STATIC_SAG * 4.0 * s * (1.0 - s) * sag_factor
	var x := 0.0
	if not current.is_empty() and tower_number == current["tower"]:
		var load: float = current["progress"]
		var triangle := s / load if s <= load and load > 0.0 else ((1.0 - s) / (1.0 - load) if s > load and load < 1.0 else 0.0)
		y -= _load_rope_sag(tower_number) * 4.0 * load * (1.0 - load) * triangle * (1.0 - 0.55 * rules.tension) * sag_factor
		x += rules.tilt * 0.35 * triangle
	return Vector3(x, y, z)


func _load_rope_sag(_tower_number: int) -> float:
	return LOAD_SAG


func _rope_sag_factor(current: Dictionary, tower_number: int) -> float:
	if current.is_empty() or int(current["tower"]) != tower_number:
		return 0.0
	var progress: float = current["progress"]
	return smoothstep(0.0, 0.08, progress) * smoothstep(0.0, 0.08, 1.0 - progress)


func _update_camera(dt: float) -> void:
	var focus := walker.position
	var desired_position := focus + Vector3(7.0, 5.5, 15.0)
	var desired_look := focus + Vector3(0.0, 1.0, -12.0)
	if mode == "intro":
		var progress := clampf(intro_elapsed / INTRO_DURATION, 0.0, 1.0)
		desired_position = INTRO_START_POSITION.lerp(desired_position, progress)
		desired_look = INTRO_START_LOOK.lerp(desired_look, progress)
	elif mode == "intro_skip":
		var progress := clampf(intro_skip_elapsed / INTRO_SKIP_DURATION, 0.0, 1.0)
		var eased := smoothstep(0.0, 1.0, progress)
		camera_position = intro_skip_from_position.lerp(desired_position, eased)
		camera_look = intro_skip_from_look.lerp(desired_look, eased)
		camera.position = camera_position
		camera.look_at(camera_look)
		if progress >= 1.0:
			_finish_intro()
		return
	elif mode == "outro" or mode == "stargaze":
		var progress := clampf(outro_elapsed / 13.0, 0.0, 1.0)
		desired_position = focus.lerp(Vector3(0.0, 78.0, -260.0), progress)
		desired_look = focus.lerp(Vector3(0.0, 110.0, -300.0), progress)
	var amount := 1.0 - exp(-dt * 3.5)
	camera_position = camera_position.lerp(desired_position, amount)
	camera_look = camera_look.lerp(desired_look, amount)
	var gust_direction := 0.0
	var gust_strength := 0.0
	var gust_remaining := 0.0
	if mode == "walking" and rules.on_rope:
		if camera_bird_gust_remaining > 0.0:
			gust_direction = float(_bird_snow_direction)
			gust_strength = 1.0
			gust_remaining = camera_bird_gust_remaining
		elif rules.state == "walking" and rules.wind_phase == "blow":
			gust_direction = float(rules.wind_dir)
			gust_strength = rules.wind_ramp
			gust_remaining = rules.wind_timer
	var active_gust := gust_direction != 0.0 and gust_remaining > 0.0
	if active_gust:
		var wind_target := gust_direction * gust_strength * (0.7 + 0.3 * sin(rules.time * 5.0))
		camera_wind_sway = lerpf(camera_wind_sway, wind_target, 1.0 - exp(-dt * 8.0))
	else:
		camera_wind_sway = 0.0
	var displayed_sway := camera_wind_sway * minf(1.0, gust_remaining / 0.12) if active_gust else 0.0
	camera_bird_gust_remaining = maxf(0.0, camera_bird_gust_remaining - dt)
	camera.position = camera_position + Vector3(displayed_sway * 0.20, 0.0, 0.0)
	camera.look_at(camera_look)
	camera.rotate_object_local(Vector3.FORWARD, deg_to_rad(displayed_sway * 1.8))


func _update_hud() -> void:
	var cue := "Keep the pole level"
	if rules.state == "falling":
		cue = "Falling"
	elif rules.on_rope:
		if rules.birds_enabled() and rules.bird_phase == "warn":
			cue = "Center bird: Q / P  %.1fs" % rules.bird_timer
		elif rules.birds_enabled() and rules.bird_gust_timer > 0.0:
			cue = "Bird gust!"
		elif rules.wind_phase == "cue" or rules.wind_phase == "react":
			cue = "Watch for the flag"
		elif rules.birds_enabled() and rules.bird_phase == "approach":
			cue = ""
		else:
			match rules.stage_kind():
				"Wind": cue = "Watch for the flag"
				"Birds": cue = "Watch for the birds"
				"Tension": cue = "Tension: %.0f%%" % [rules.tension * 100.0]
	hud.show_status(rules.tower, rules.step, Rules.STEPS_PER_TOWER, rules.stage_kind(), rules.tilt, cue, rules.tension, rules.time)
	var space_action := ""
	if mode == "walking" and not paused:
		if rules.state == "falling" and fall_elapsed > 0.0:
			space_action = "SPACE: respawn"
		elif rules.state == "walking" and rules.on_rope and rules.tension_enabled() and rules.time - rules.last_release_at >= Rules.RELEASE_COOLDOWN:
			space_action = "SPACE: release wire tension"
	hud.show_space_control(space_action)


func _show_tower_title() -> void:
	hud.show_toast("TOWER %d: %s" % [rules.tower, rules.stage_kind()], 2.5, 34)


func _stage_color(colors: Array, stage: float) -> Color:
	var first := clampi(floori(stage), 0, Rules.TOWER_COUNT - 1)
	var second := mini(first + 1, Rules.TOWER_COUNT - 1)
	return Color(String(colors[first])).lerp(Color(String(colors[second])), stage - float(first))


func _stage_value(values: Array, stage: float) -> float:
	var last := values.size() - 1
	var first := clampi(floori(stage), 0, last)
	var second := mini(first + 1, last)
	return lerpf(float(values[first]), float(values[second]), stage - float(first))


func _update_atmosphere(dt: float) -> void:
	var target_stage := float(rules.tower - 1)
	_sky_stage = move_toward(_sky_stage, target_stage, dt * STAGE_SKY_BLEND_SPEED)
	if is_equal_approx(_sky_stage, _last_atmosphere_stage) and is_equal_approx(visual_z, _last_atmosphere_z):
		return
	_last_atmosphere_stage = _sky_stage
	_last_atmosphere_z = visual_z
	var course_progress := clampf((Rules.step_z(1, 0) - visual_z) / Rules.TOWER_SPACING, 0.0, float(Rules.TOWER_COUNT))
	var sun_elevation := _stage_value(SUN_ELEVATIONS, course_progress)
	var moon_elevation := _stage_value(MOON_ELEVATIONS, course_progress)
	var sun_direction := Vector3(0.35, sin(deg_to_rad(sun_elevation)), -1.0).normalized()
	var moon_direction := Vector3(-0.35, sin(deg_to_rad(moon_elevation)), -1.0).normalized()
	var sun_strength := 1.0 - smoothstep(1.4, 1.9, _sky_stage)
	var moon_strength := smoothstep(1.5, 2.0, _sky_stage) * 0.56
	var horizon := _stage_color(SKY_HORIZON_COLORS, _sky_stage)
	_sky_material.set_shader_parameter("sky_top_color", _stage_color(SKY_TOP_COLORS, _sky_stage))
	_sky_material.set_shader_parameter("sky_mid_color", _stage_color(SKY_MID_COLORS, _sky_stage))
	_sky_material.set_shader_parameter("horizon_color", horizon)
	_sky_material.set_shader_parameter("sun_color", Color("fff2cb").lerp(Color("ffca83"), smoothstep(0.75, 1.25, course_progress)))
	_sky_material.set_shader_parameter("sun_direction", sun_direction)
	_sky_material.set_shader_parameter("sun_strength", sun_strength)
	_sky_material.set_shader_parameter("moon_direction", moon_direction)
	_sky_material.set_shader_parameter("moon_strength", moon_strength)
	_world_environment.ambient_light_color = _stage_color(AMBIENT_COLORS, _sky_stage)
	_world_environment.ambient_light_energy = _stage_value(AMBIENT_ENERGIES, _sky_stage)
	_world_environment.fog_light_color = horizon
	_world_environment.fog_density = _stage_value(FOG_DENSITIES, _sky_stage)
	_world_environment.fog_depth_begin = _stage_value(FOG_DEPTH_BEGINS, _sky_stage)
	_world_environment.fog_depth_end = _stage_value(FOG_DEPTH_ENDS, _sky_stage)
	_world_environment.fog_height_density = _stage_value(FOG_HEIGHT_DENSITIES, _sky_stage)
	var glow_factor := _stage_value(LIT_SOURCE_GLOW_FACTORS, _sky_stage)
	if not is_equal_approx(glow_factor, _lit_source_glow_factor):
		_lit_source_glow_factor = glow_factor
		_world_environment.glow_intensity = 0.85 * glow_factor
		_halo_material.albedo_color = Color(1.0, 1.0, 1.0, glow_factor)
		for entry in _emissive_materials:
			var material: StandardMaterial3D = entry["material"]
			material.emission_energy_multiplier = float(entry["energy"]) * glow_factor
		for entry in _halo_materials:
			var material: StandardMaterial3D = entry["material"]
			var color: Color = entry["color"]
			material.albedo_color = Color(color.r, color.g, color.b, color.a * glow_factor)
		for entry in _local_lights:
			var light: OmniLight3D = entry["light"]
			light.light_energy = float(entry["energy"]) * glow_factor
	_key_light.light_color = _stage_color(KEY_LIGHT_COLORS, _sky_stage)
	_key_light.light_energy = _stage_value(KEY_LIGHT_ENERGIES, _sky_stage)
	_key_light.look_at(_key_light.global_position - sun_direction.lerp(moon_direction, smoothstep(1.3, 2.0, _sky_stage)).normalized(), Vector3.UP)
	_moon_glow.light_energy = moon_strength
	_moon_glow.look_at(_moon_glow.global_position - moon_direction, Vector3.UP)
	_darkness.color = Color(0.01, 0.015, 0.04, _stage_value(DARKNESS_ALPHAS, _sky_stage))


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "Time of Day Environment"
	var resource := Environment.new()
	_world_environment = resource
	var horizon_color := Color("12122c")
	var sky_material := ShaderMaterial.new()
	_sky_material = sky_material
	sky_material.shader = NightSkyShader
	sky_material.set_shader_parameter("sky_top_color", Color("08091b"))
	sky_material.set_shader_parameter("horizon_color", horizon_color)
	var night_sky := Sky.new()
	night_sky.sky_material = sky_material
	night_sky.process_mode = Sky.PROCESS_MODE_REALTIME
	resource.background_mode = Environment.BG_SKY
	resource.sky = night_sky
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("5c5c9c")
	resource.ambient_light_energy = 0.10
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	resource.tonemap_exposure = .85
	resource.glow_enabled = true
	resource.glow_intensity = 0.85
	resource.glow_strength = .82
	resource.glow_bloom = 0.0
	resource.glow_hdr_threshold = 1.2
	resource.glow_hdr_scale = 0.7
	resource.ssao_enabled = true
	resource.ssao_radius = 1.5
	resource.ssao_intensity = 1.15
	resource.ssao_power = 1.7
	resource.ssao_detail = 0.7
	resource.adjustment_enabled = true
	resource.adjustment_brightness = 0.99
	resource.adjustment_contrast = 1.04
	resource.adjustment_saturation = 1.06
	resource.fog_enabled = true
	resource.fog_mode = Environment.FOG_MODE_DEPTH
	resource.fog_light_color = horizon_color
	resource.fog_density = 1.0
	resource.fog_depth_begin = 45.0
	resource.fog_depth_end = 260.0
	resource.fog_height = -3.0
	resource.fog_height_density = 0.04
	resource.fog_sky_affect = 0.005
	environment.environment = resource
	add_child(environment)
	var night_layer := CanvasLayer.new()
	night_layer.name = "Night Tint"
	night_layer.layer = 1
	var darkness := ColorRect.new()
	_darkness = darkness
	darkness.name = "Full Screen Darkness"
	darkness.set_anchors_preset(Control.PRESET_FULL_RECT)
	darkness.color = Color(0.01, 0.015, 0.04, 0.22)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_layer.add_child(darkness)
	add_child(night_layer)
	var vignette_layer := CanvasLayer.new()
	vignette_layer.name = "Vignette"
	vignette_layer.layer = 2
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = VignetteShader
	vignette.material = vignette_material
	vignette_layer.add_child(vignette)
	add_child(vignette_layer)
	var light := DirectionalLight3D.new()
	_key_light = light
	light.name = "Time of Day Contact Shadows"
	light.rotation_degrees = Vector3(-35.0, -20.0, 0.0)
	light.light_color = Color("b5bbff")
	light.light_energy = .2
	light.shadow_enabled = true
	light.shadow_bias = 0.02
	light.shadow_normal_bias = 0.5
	light.light_angular_distance = 0.3
	light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(light)
	_halo_material = _make_halo_material()
	_halo_quad = QuadMesh.new()
	_halo_quad.size = Vector2.ONE
	var moon_glow := DirectionalLight3D.new()
	_moon_glow = moon_glow
	moon_glow.name = "Moon Glow"
	moon_glow.rotation_degrees = Vector3(-8.0, 215.0, 0.0)
	moon_glow.light_color = Color("eed4dcff")
	moon_glow.light_energy = 0.56
	moon_glow.light_angular_distance = 1.8
	moon_glow.sky_mode = DirectionalLight3D.SKY_MODE_SKY_ONLY
	add_child(moon_glow)
	sky_material.set_shader_parameter("moon_direction", moon_glow.global_transform.basis.z.normalized())
	sky_material.set_shader_parameter("moon_color", moon_glow.light_color)
	sky_material.set_shader_parameter("moon_strength", moon_glow.light_energy)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 68.0
	add_child(camera)
	gust_flag = FlagScene.instantiate() as Node3D
	gust_flag.name = "Gust Warning Flag"
	gust_flag.scale = Vector3.ONE * 0.7
	gust_flag.position = Vector3(4.5, -0.8, -9.0)
	gust_flag.visible = false
	camera.add_child(gust_flag)
	var flag_mesh := gust_flag.find_child("Flag", true, false) as MeshInstance3D
	if flag_mesh != null:
		flag_mesh.set_surface_override_material(0, _material(Color("7c829e")))
		flag_mesh.set_surface_override_material(1, _material(Color("ff6a58")))
	_build_rooftop_skyscrapers()
	_build_cityscape()
	_build_city_ground()
	_build_street_lights()
	_build_static_light_halos()
	_build_traffic()
	for number in range(1, Rules.TOWER_COUNT + 1):
		var pieces: Array = []
		var roof_anchor := _roof_anchor_point(number)
		var edge_anchor := _rope_point(number, 0.0, {})
		var roof_mount := _city_box(self, roof_anchor - Vector3(0.0, 0.2, 0.0), Vector3(0.45, 0.4, 0.45), Color("a5bfd5"))
		roof_mount.name = "Roof Rope Anchor %d" % number
		_add_local_light(self, "Rope Anchor Light %d" % number, roof_anchor + Vector3(0.0, 0.55, 0.0), Color("ffd49a"), 0.75, 3.5)
		var edge_mount := _city_box(self, edge_anchor - Vector3(0.0, 0.2, 0.0), Vector3(0.45, 0.4, 0.45), Color("a5bfd5"))
		edge_mount.name = "Edge Rope Anchor %d" % number
		for segment_number in range(ROPE_SEGMENTS + 1):
			var segment := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = ROPE_RADIUS
			mesh.bottom_radius = ROPE_RADIUS
			mesh.height = 2.0
			segment.mesh = mesh
			segment.material_override = _material(ROPE_COLOR, false, ROPE_BASE_EMISSION)
			add_child(segment)
			pieces.append(segment)
		ropes.append(pieces)
	walker = Node3D.new()
	add_child(walker)
	_build_walker_visual()
	_add_local_light(walker, "Stuntman Warm Light", Vector3(0.0, 2.2, 0.6), Color("ffc38e"), 0.8, 4.0)
	_place_kenney_decor()
	pole = MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = BALANCE_POLE_RADIUS
	pole_mesh.bottom_radius = BALANCE_POLE_RADIUS
	pole_mesh.height = 13.0
	pole.mesh = pole_mesh
	var pole_material := _material(Color("c8d0d8"))
	pole_material.metallic = 1.0
	pole_material.roughness = 0.3
	pole.material_override = pole_material
	pole.rotation.z = PI * 0.5
	pole.position = Vector3(0.0, POLE_WAIST_Y, POLE_FRONT_Z)
	walker.add_child(pole)
	for bird_number in 3:
		var bird := BirdScene.instantiate() as Node3D
		bird.name = "Center Bird" if bird_number == 1 else ("Left Flanker" if bird_number == 0 else "Right Flanker")
		bird.scale = Vector3.ONE * (2.4 if bird_number == 1 else 1.9)
		bird.visible = false
		add_child(bird)
		var bird_animation := bird.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if bird_animation != null and bird_animation.has_animation(BIRD_FLY_ANIMATION):
			bird_animation.get_animation(BIRD_FLY_ANIMATION).loop_mode = Animation.LOOP_LINEAR
			bird_animation.play(BIRD_FLY_ANIMATION)
		_brighten_bird_for_night(bird)
		bird.add_child(_bird_direction_marker(bird_number == 1))
		birds.append(bird)
	snow = CPUParticles3D.new()
	snow.amount = 300
	snow.lifetime = 8.0
	snow.preprocess = snow.lifetime
	snow.emitting = true
	snow.local_coords = false
	snow.position = INTRO_START_POSITION + Vector3(0.0, 16.0, -18.0)
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(22.0, 2.0, 24.0)
	snow.direction = Vector3.DOWN
	snow.gravity = Vector3(0.0, -2.0, 0.0)
	snow.initial_velocity_min = 2.0
	snow.initial_velocity_max = 4.0
	var flake := SphereMesh.new()
	flake.radius = 0.07
	flake.height = 0.14
	snow.mesh = flake
	add_child(snow)
	gust_snow = CPUParticles3D.new()
	gust_snow.name = "Gust Snow"
	gust_snow.amount = 180
	gust_snow.lifetime = SNOW_BURST_DURATION
	gust_snow.one_shot = true
	gust_snow.explosiveness = 1.0
	gust_snow.local_coords = false
	gust_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	gust_snow.emission_box_extents = Vector3(8.0, 5.0, 7.0)
	gust_snow.initial_velocity_min = 12.0
	gust_snow.initial_velocity_max = 17.0
	gust_snow.mesh = flake
	gust_snow.emitting = false
	add_child(gust_snow)
	gust_snow.hide()
	for star_number in 120:
		var star := MeshInstance3D.new()
		var star_mesh := SphereMesh.new()
		star_mesh.radius = 0.13
		star_mesh.height = 0.26
		star.mesh = star_mesh
		star.material_override = _material(Color("fff4d8"), true, 1.8)
		star.position = Vector3(_rng.randf_range(-180.0, 180.0), _rng.randf_range(68.0, 130.0), _rng.randf_range(-340.0, 60.0))
		add_child(star)


func _build_walker_visual() -> void:
	var path := "res://assets/grab3d/elderly-man-rigged.glb"
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene != null:
			walker_model = scene.instantiate() as Node3D
			if walker_model != null:
				walker.add_child(walker_model)
				walker_model.rotation.y = PI
				walker_model.scale = Vector3.ONE * 1.7
				walker_animation = walker_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
				walker_skeleton = walker_model.find_child("Skeleton3D", true, false) as Skeleton3D
				if walker_animation != null:
					walker_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
					if walker_animation.has_animation("walk"):
						walker_animation.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
				_play_walker_animation("idle")
				return
	# Keep a visible walker if an asset is missing from a development checkout.
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.65
	capsule.height = 3.0
	body.mesh = capsule
	body.material_override = _material(Color("ffca62"))
	body.position.y = 1.5
	walker.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	head.mesh = sphere
	head.material_override = _material(Color("ffe2bd"))
	head.position.y = 3.2
	walker.add_child(head)


func _play_walker_animation(animation_name: StringName) -> void:
	if walker_animation == null:
		return
	if animation_name == &"idle":
		walker_animation.stop()
	elif walker_animation.has_animation(animation_name):
		walker_animation.play(animation_name)


func _place_kenney_decor() -> void:
	var decorations := Node3D.new()
	decorations.name = "Kenney Holiday Decorations"
	add_child(decorations)
	_add_kenney_model(decorations, "bench", Vector3(-3.8, FEET_Y - 0.7, Rules.tower_z(5) - 4.0), 1.7)
	for x in [-2.8, 2.8]:
		_add_kenney_model(decorations, "present-a-cube", Vector3(x, FEET_Y - 0.7, Rules.tower_z(5) - 5.5), 1.3)


func _add_kenney_model(parent: Node3D, model_name: String, at: Vector3, model_scale: float) -> void:
	var path := "res://assets/kenney/holiday_kit/%s.glb" % model_name
	if not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	if scene == null:
		return
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return
	instance.position = at
	instance.scale = Vector3.ONE * model_scale
	parent.add_child(instance)
	kenney_decor_count += 1


func _build_rooftop_skyscrapers() -> void:
	var towers := Node3D.new()
	towers.name = "Rooftop Skyscrapers"
	add_child(towers)
	var facade_colors := [Color("303149"), Color("292d46"), Color("36364d"), Color("252942"), Color("303149")]
	var glass_colors := [Color("ffa256ff"), Color("fcc961ff"), Color("f2a45aff"), Color("ffb356ff")]
	var window_rng := RandomNumberGenerator.new()
	window_rng.seed = 84021
	var roof_y := FEET_Y - 0.5
	var roof_thickness := 0.4
	var facade_height := roof_y + 12.0 - roof_thickness * 0.5
	for number in range(1, Rules.TOWER_COUNT + 2):
		var tower := Node3D.new()
		tower.name = "Skyscraper %d" % number
		tower.position.z = Rules.tower_z(number) - 4.0
		towers.add_child(tower)
		var facade: Color = facade_colors[number - 1]
		var trim := facade.lightened(0.25)
		var body := _city_box(tower, Vector3(0.0, -12.0 + facade_height * 0.5, 0.0), Vector3(17.0, facade_height, 20.0), facade)
		body.name = "Facade"
		var roof := _city_box(tower, Vector3(0.0, roof_y - roof_thickness * 0.5, 0.0), Vector3(19.0, roof_thickness, 24.0), Color("55586c"))
		roof.name = "Walkable Roof"
		var roof_snow := _snow_cap(tower, Vector3(0.0, roof_y, 0.0), Vector2(18.8, 23.8), Color("e1ebf2"), number)
		roof_snow.name = "Roof Snow"
		for side in [-1.0, 1.0]:
			var side_rail := _city_box(tower, Vector3(side * 9.2, roof_y + 0.45, 0.0), Vector3(0.5, 1.3, 24.0), trim)
			side_rail.name = "Side Rail"
			var rail_size := (side_rail.mesh as BoxMesh).size
			var rail_top := side_rail.position.y + rail_size.y * 0.5
			var rail_snow := _snow_cap(tower, Vector3(side_rail.position.x, rail_top, 0.0), Vector2(rail_size.x + 0.06, 23.8), Color("e1ebf2"), number * 10 + int(side), 0.12, 0.025, 0.08)
			rail_snow.name = "Side Rail Snow"
			_city_box(tower, Vector3(side * 8.55, 15.0, 0.0), Vector3(0.25, 49.0, 0.35), trim)
			for column in 3:
				_city_box(tower, Vector3(side * 8.56, 16.0, (float(column) - 1.0) * 6.0), Vector3(0.16, 45.0, 0.16), trim)
			_city_box(tower, Vector3(side * 6.0, roof_y + 0.75, 1.0), Vector3(2.4, 1.5, 2.8), Color("41485c"))
		for floor_number in 11:
			var y := -7.0 + floor_number * 4.5
			if floor_number % 3 == 0:
				_city_box(tower, Vector3(0.0, y - 1.9, 0.0), Vector3(17.5, 0.25, 20.5), trim)
			for column in 3:
				var offset := (float(column) - 1.0) * 5.0
				var glass: Color = glass_colors[(number + floor_number + column) % glass_colors.size()]
				for side in [-1.0, 1.0]:
					var front_lit: bool = window_rng.randf() < LIT_WINDOW_CHANCE or ((number == 1 or number == 3) and floor_number == 10 and column == 1 and side > 0.0)
					var side_lit: bool = window_rng.randf() < LIT_WINDOW_CHANCE
					_city_box(tower, Vector3(offset, y, side * 10.04), Vector3(2.8, 2.2, 0.12), glass if front_lit else DARK_WINDOW_COLOR, false, WINDOW_GLOW_ENERGY if front_lit else 0.0)
					_city_box(tower, Vector3(side * 8.54, y, offset * 1.25), Vector3(0.12, 2.2, 2.8), glass if side_lit else DARK_WINDOW_COLOR, false, WINDOW_GLOW_ENERGY if side_lit else 0.0)
					if front_lit:
						_queue_light_halo(tower, Vector3(offset, y, side * 10.16), Vector2(4.2, 3.4), Color(glass.r, glass.g, glass.b, 0.65))
					if side_lit:
						_queue_light_halo(tower, Vector3(side * 8.66, y, offset * 1.25), Vector2(4.2, 3.4), Color(glass.r, glass.g, glass.b, 0.65))
		if number == 1 or number == 3:
			_add_local_light(tower, "Upper Window Light", Vector3(0.0, 38.0, 10.45), Color("ffcd60ff"), 0.9, 5.5)
		if number == Rules.TOWER_COUNT + 1:
			var roof_spike := _city_box(tower, Vector3(6.5, roof_y + 1.5, 6.5), Vector3(0.12, 3.0, 0.12), ROOF_SPIKE_COLOR)
			roof_spike.name = "Finish Roof Beacon Pole"
			var spike_base := _roof_spike_base(tower, Vector3(6.5, roof_y + SNOW_LAYER_THICKNESS, 6.5), Color("e1ebf2"), 9001)
			spike_base.name = "Finish Roof Spike Base"
			var beacon_position := Vector3(6.5, roof_y + 3.18, 6.5)
			var beacon_color := Color("e9d3a0ff")
			var bulb := MeshInstance3D.new()
			var bulb_mesh := SphereMesh.new()
			bulb_mesh.radius = 0.18
			bulb_mesh.height = 0.36
			bulb.mesh = bulb_mesh
			bulb.name = "Finish Roof Beacon"
			bulb.material_override = _material(beacon_color, false, STREETLAMP_GLOW_ENERGY)
			bulb.position = beacon_position
			tower.add_child(bulb)
			_add_local_light(tower, "Finish Roof Beacon Light", beacon_position, beacon_color, 1.2, 7.5)
			_queue_light_halo(tower, beacon_position, Vector2(1.35, 1.35), Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.75))
			var cap_glow := _add_roof_snow_glow(spike_base, Vector3(0.0, 0.83, 0.0), 1.0, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.8))
			cap_glow.name = "Finish Spike Base Cap Glow"
			var snow_glow := _add_roof_snow_glow(tower, Vector3(beacon_position.x, roof_y + SNOW_LAYER_THICKNESS + 0.03, beacon_position.z), 9.0, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.6))
			snow_glow.name = "Finish Roof Snow Glow"


func _build_cityscape() -> void:
	var city := Node3D.new()
	city.name = "Cityscape"
	add_child(city)
	var skyline_rng := RandomNumberGenerator.new()
	skyline_rng.seed = 49021
	var distant_rng := RandomNumberGenerator.new()
	distant_rng.seed = 73011
	var walls := [Color("252942"), Color("303149"), Color("36364d"), Color("292d46")]
	var windows := [Color("f9e15bff"), Color("ffbe9dff"), Color("ffc473ff")]
	for side_index in 2:
		var side := -1.0 if side_index == 0 else 1.0
		for row in 2:
			var distance := 49.0 + row * 28.0
			for index in 42:
				var building_rng := skyline_rng if index < 25 else distant_rng
				var window_rng := RandomNumberGenerator.new()
				window_rng.seed = 73017 + side_index * 100000 + row * 10000 + index
				var z := 39.0 - index * 17.0 - row * 7.0
				var height := building_rng.randf_range(22.0, 56.0) + row * 8.0
				var width := building_rng.randf_range(12.0, 18.0)
				var depth := building_rng.randf_range(11.0, 17.0)
				var x := side * (distance + building_rng.randf_range(-4.0, 4.0))
				var building := _city_box(city, Vector3(x, -12.0 + height * 0.5, z), Vector3(width, height, depth), walls[building_rng.randi_range(0, walls.size() - 1)])
				building.name = "Building %d %d %d" % [int(side), row, index]
				var snow_color := Color("d1dee8") if row == 0 else Color("b8c9d8")
				var roof_snow := _snow_cap(city, Vector3(x, -12.0 + height, z), Vector2(width - 0.3, depth - 0.3), snow_color, side_index * 100 + row * 25 + index)
				roof_snow.name = "Building Snow %d %d %d" % [int(side), row, index]
				var inner_face := x - side * (width * 0.5 + 0.04)
				for floor_number in range(2, int(height / 5.0)):
					if building_rng.randf() < 0.28:
						continue
					for column in 2:
						var pane_z := z + (float(column) - 0.5) * depth * 0.38
						var window_color: Color = windows[building_rng.randi_range(0, windows.size() - 1)]
						var window_position := Vector3(inner_face, -12.0 + floor_number * 5.0, pane_z)
						var lit: bool = window_rng.randf() < LIT_WINDOW_CHANCE
						_city_box(city, window_position, Vector3(0.12, 1.55, 1.2), window_color if lit else DARK_WINDOW_COLOR, false, WINDOW_GLOW_ENERGY if lit else 0.0)
						if lit:
							_queue_light_halo(city, window_position - Vector3(side * 0.12, 0.0, 0.0), Vector2(3.2, 2.3), Color(window_color.r, window_color.g, window_color.b, 0.6))
				var beacon_slot: bool = row == 0 and index in BEACON_BUILDING_INDICES
				var has_spike: bool = building_rng.randf() < 0.3
				if has_spike or beacon_slot:
					var spike := _city_box(city, Vector3(x, -12.0 + height + 2.5, z), Vector3(0.14, 5.0, 0.14), ROOF_SPIKE_COLOR)
					spike.name = "City Roof Spike %d %d %d" % [side_index, row, index]
					var spike_base := _roof_spike_base(city, Vector3(x, -12.0 + height + SNOW_LAYER_THICKNESS, z), snow_color, side_index * 1000 + row * 100 + index)
					spike_base.name = "City Roof Spike Base %d %d %d" % [side_index, row, index]
					var beacon_color := Color("ff5048") if (index + side_index + row) % 2 == 1 else Color("ffca88")
					var beacon_position := Vector3(x, -12.0 + height + 5.12, z)
					var bulb := MeshInstance3D.new()
					var bulb_mesh := SphereMesh.new()
					bulb_mesh.radius = 0.18
					bulb_mesh.height = 0.36
					bulb.mesh = bulb_mesh
					bulb.name = "Roof Beacon %d %d %d" % [side_index, row, index]
					bulb.material_override = _material(beacon_color, false, STREETLAMP_GLOW_ENERGY)
					bulb.position = beacon_position
					city.add_child(bulb)
					var is_red := beacon_color.g < 0.5
					var beacon_light := _add_local_light(city, "Roof Beacon Light %d %d %d" % [side_index, row, index], beacon_position, beacon_color, 0.55 if is_red else 1.2, 6.5 if is_red else 7.5)
					var halo_color := Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.75)
					var cap_glow := _add_roof_snow_glow(spike_base, Vector3(0.0, 0.83, 0.0), 1.0, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.4 if is_red else 0.8))
					cap_glow.name = "Spike Base Cap Glow"
					var snow_glow := _add_roof_snow_glow(city, Vector3(x, -12.0 + height + SNOW_LAYER_THICKNESS + 0.03, z), 5.5 if is_red else 9.0, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.28 if is_red else 0.6))
					snow_glow.name = "Roof Snow Glow %d %d %d" % [side_index, row, index]
					if is_red:
						var halo := _add_light_halo(city, beacon_position, Vector2(1.35, 1.35), halo_color)
						halo.name = "Roof Beacon Halo %d %d %d" % [side_index, row, index]
						var phase := fmod(float(_red_beacons.size()) * 0.43, RED_BEACON_PERIOD)
						var flashing: bool = phase < RED_BEACON_FLASH_DURATION
						bulb.visible = flashing
						beacon_light.visible = flashing
						halo.visible = flashing
						snow_glow.visible = flashing
						cap_glow.visible = flashing
						_red_beacons.append({"bulb": bulb, "light": beacon_light, "halo": halo, "snow_glow": snow_glow, "cap_glow": cap_glow, "phase": phase})
					else:
						_queue_light_halo(city, beacon_position, Vector2(1.35, 1.35), halo_color)
	_build_distant_skyline(city)


func _build_distant_skyline(city: Node3D) -> void:
	var skyline := Node3D.new()
	skyline.name = "Distant Skyline"
	city.add_child(skyline)
	var skyline_rng := RandomNumberGenerator.new()
	skyline_rng.seed = 81247
	var wall_colors := [Color("30364b"), Color("394056"), Color("42475b"), Color("2c3347")]
	var side_windows: Array[Transform3D] = []
	var end_windows: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for row in 3:
			var distance := 115.0 + float(row) * 45.0
			for index in 46:
				var x: float = side * (distance + skyline_rng.randf_range(-6.0, 6.0))
				var z := 215.0 - float(index) * 28.0 - float(row) * 8.0 + skyline_rng.randf_range(-5.0, 5.0)
				var height := skyline_rng.randf_range(24.0, 65.0) + float(row) * 3.0
				var width := skyline_rng.randf_range(15.0, 23.0)
				var depth := skyline_rng.randf_range(14.0, 21.0)
				_add_distant_building(skyline, x, z, width, depth, height, wall_colors[(index + row) % wall_colors.size()], side_windows, true)
	for z in [270.0, -1110.0]:
		for index in 19:
			var x: float = -225.0 + float(index) * 25.0 + skyline_rng.randf_range(-3.0, 3.0)
			var height := skyline_rng.randf_range(25.0, 60.0)
			_add_distant_building(skyline, x, z + skyline_rng.randf_range(-3.0, 3.0), skyline_rng.randf_range(16.0, 22.0), skyline_rng.randf_range(15.0, 20.0), height, wall_colors[index % wall_colors.size()], end_windows, false)
	_add_distant_windows(skyline, "Distant Side Windows", side_windows, Vector3(0.12, 1.5, 2.2))
	_add_distant_windows(skyline, "Distant End Windows", end_windows, Vector3(2.2, 1.5, 0.12))


func _add_distant_building(parent: Node3D, x: float, z: float, width: float, depth: float, height: float, wall_color: Color, windows: Array[Transform3D], side_facing: bool) -> void:
	var building := Node3D.new()
	building.name = "Distant Building"
	building.position = Vector3(x, 0.0, z)
	parent.add_child(building)
	_city_box(building, Vector3(0.0, STREET_SURFACE_Y + height * 0.5, 0.0), Vector3(width, height, depth), wall_color)
	_city_box(building, Vector3(0.0, STREET_SURFACE_Y + height + 0.12, 0.0), Vector3(width + 0.5, 0.24, depth + 0.5), Color("9baabd"))
	var floor_count := clampi(floori(height / 9.0), 3, 7)
	for floor_number in range(1, floor_count):
		var window_y := STREET_SURFACE_Y + height * float(floor_number) / float(floor_count)
		for column in 2:
			if (floor_number + column + floori(absf(x)) + floori(absf(z))) % 5 == 0:
				continue
			var window_position: Vector3
			if side_facing:
				window_position = Vector3(-signf(x) * (width * 0.5 + 0.06) + x, window_y, z + (float(column) - 0.5) * depth * 0.45)
			else:
				window_position = Vector3(x + (float(column) - 0.5) * width * 0.45, window_y, z - signf(z) * (depth * 0.5 + 0.06))
			windows.append(Transform3D(Basis(), window_position))


func _add_distant_windows(parent: Node3D, window_name: String, positions: Array[Transform3D], size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = positions.size()
	for index in positions.size():
		instances.set_instance_transform(index, positions[index])
	var windows := MultiMeshInstance3D.new()
	windows.name = window_name
	windows.multimesh = instances
	windows.material_override = _material(Color("d1b38c"), false, 1.3)
	windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(windows)


func _build_city_ground() -> void:
	var ground := Node3D.new()
	ground.name = "City Ground"
	add_child(ground)
	var outer_ground := _city_box(ground, Vector3(0.0, STREET_SURFACE_Y - 1.2, CITY_GROUND_CENTER_Z), Vector3(CITY_GROUND_WIDTH, 1.0, CITY_GROUND_LENGTH), Color("343a4d"))
	outer_ground.name = "Outer City Ground"
	var street := _city_box(ground, Vector3(0.0, STREET_SURFACE_Y - 0.5, CITY_GROUND_CENTER_Z), Vector3(STREET_WIDTH, 1.0, CITY_GROUND_LENGTH), Color("252a39"))
	street.name = "Asphalt Street"
	var street_snow := _city_box(ground, Vector3(0.0, STREET_SURFACE_Y + GROUND_SNOW_THICKNESS * 0.5, CITY_GROUND_CENTER_Z), Vector3(STREET_WIDTH - 0.5, GROUND_SNOW_THICKNESS, CITY_GROUND_LENGTH - 0.5), Color("c5d1dc"))
	street_snow.name = "Street Snow"
	for side_index in 2:
		var side := -1.0 if side_index == 0 else 1.0
		var sidewalk := _city_box(ground, Vector3(side * SIDEWALK_CENTER_X, STREET_SURFACE_Y - 0.25, CITY_GROUND_CENTER_Z), Vector3(SIDEWALK_WIDTH, 1.5, CITY_GROUND_LENGTH), Color("51566b"))
		sidewalk.name = "Sidewalk %d" % side_index
		var sidewalk_top := sidewalk.position.y + (sidewalk.mesh as BoxMesh).size.y * 0.5
		var sidewalk_snow := _city_box(ground, Vector3(side * SIDEWALK_CENTER_X, sidewalk_top + GROUND_SNOW_THICKNESS * 0.5, CITY_GROUND_CENTER_Z), Vector3(SIDEWALK_WIDTH - 0.2, GROUND_SNOW_THICKNESS, CITY_GROUND_LENGTH - 0.5), Color("d6e0e8"))
		sidewalk_snow.name = "Sidewalk Snow %d" % side_index
		_city_box(ground, Vector3(side * (STREET_WIDTH * 0.5 + 0.15), STREET_SURFACE_Y + GROUND_SNOW_THICKNESS + 0.25, CITY_GROUND_CENTER_Z), Vector3(0.3, 0.5, CITY_GROUND_LENGTH), Color("9a9bae"))
		for index in range(-12, 66):
			var z := 49.0 - float(index) * 18.0
			_city_box(ground, Vector3(side * (TRAFFIC_LANE_X - 4.0), STREET_SURFACE_Y + GROUND_SNOW_THICKNESS + 0.01, z), Vector3(0.35, 0.02, 7.0), Color("d4b77b"), true)


func _build_street_lights() -> void:
	var lamps := Node3D.new()
	lamps.name = "Street Lights"
	add_child(lamps)
	for index in range(-4, 25):
		var z := 30.0 - float(index) * 48.0
		for side in [-1.0, 1.0]:
			var lamp := Node3D.new()
			lamp.position = Vector3(side * SIDEWALK_CENTER_X, SIDEWALK_SURFACE_Y, z)
			lamps.add_child(lamp)
			_city_box(lamp, Vector3(0.0, 2.8, 0.0), Vector3(0.18, 5.6, 0.18), Color("4a4b5c"))
			_city_box(lamp, Vector3(-side * 0.65, 5.55, 0.0), Vector3(1.3, 0.13, 0.13), Color("4a4b5c"))
			_city_box(lamp, Vector3(-side * 1.3, 5.45, 0.0), Vector3(0.7, 0.18, 0.5), Color("ffce83"), false, STREETLAMP_GLOW_ENERGY)
			_queue_light_halo(lamp, Vector3(-side * 1.3, 5.45, 0.0), Vector2(2.2, 2.2), Color(1.0, 0.8, 0.5, 0.9))
			if index % 2 == 0:
				var glow := OmniLight3D.new()
				glow.position = Vector3(-side * 1.3, 5.2, 0.0)
				glow.light_color = Color("ffd39a")
				glow.light_energy = 0.85
				glow.omni_range = 13.0
				lamp.add_child(glow)
				_local_lights.append({"light": glow, "energy": 0.85})


func _build_traffic() -> void:
	var traffic := Node3D.new()
	traffic.name = "Street Traffic"
	add_child(traffic)
	for index in TRAFFIC_SPAWN_Z.size():
		var direction := 1.0 if index % 2 == 0 else -1.0
		var car := Node3D.new()
		car.position = Vector3(-TRAFFIC_LANE_X if direction > 0.0 else TRAFFIC_LANE_X, -11.65, TRAFFIC_SPAWN_Z[index])
		traffic.add_child(car)
		_city_box(car, Vector3(0.0, 0.22, 0.0), Vector3(2.2, 0.55, 3.5), Color("252a36"))
		for side in [-1.0, 1.0]:
			_city_box(car, Vector3(side * 0.75, 0.48, direction * 1.8), Vector3(0.38, 0.22, 0.16), Color("fff0c3"), false, HEADLIGHT_GLOW_ENERGY)
			_city_box(car, Vector3(side * 0.75, 0.48, -direction * 1.8), Vector3(0.38, 0.22, 0.16), Color("ff625b"), false, TAILLIGHT_GLOW_ENERGY)
			_add_light_halo(car, Vector3(side * 0.75, 0.48, direction * 1.91), Vector2(1.2, 1.0), Color("fff0c3"))
			_add_light_halo(car, Vector3(side * 0.75, 0.48, -direction * 1.91), Vector2(1.1, 0.9), Color("ff625b"))
		traffic_lights.append(car)


func _update_traffic(dt: float) -> void:
	for index in traffic_lights.size():
		var car := traffic_lights[index]
		var direction := 1.0 if index % 2 == 0 else -1.0
		car.position.z = wrapf(car.position.z + direction * (14.0 + float(index % 3) * 2.0) * dt, TRAFFIC_START_Z, TRAFFIC_END_Z)


func _snow_cap(parent: Node3D, at: Vector3, size: Vector2, color: Color, seed_value: int, thickness: float = SNOW_LAYER_THICKNESS, edge_variation: float = 0.3, bevel_width: float = 0.75) -> MeshInstance3D:
	var corners: Array[Vector2] = [
		Vector2(-size.x, -size.y) * 0.5,
		Vector2(-size.x, size.y) * 0.5,
		Vector2(size.x, size.y) * 0.5,
		Vector2(size.x, -size.y) * 0.5,
	]
	var outward: Array[Vector2] = [Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT, Vector2.UP]
	var inner := PackedVector3Array()
	var rim := PackedVector3Array()
	var base := PackedVector3Array()
	var inner_scale := Vector2(1.0 - bevel_width / (size.x * 0.5), 1.0 - bevel_width / (size.y * 0.5))
	for side in 4:
		for step in 12:
			var edge := corners[side].lerp(corners[(side + 1) % 4], float(step) / 12.0)
			if step == 0:
				edge *= 0.97
			var point_index := side * 12 + step
			var angle := TAU * float(point_index) / 48.0
			var wave := 0.68 * sin(angle * 5.0 + float(seed_value) * 0.31) + 0.32 * sin(angle * 11.0 + float(seed_value) * 0.73)
			edge += outward[side] * wave * edge_variation
			inner.append(Vector3(edge.x * inner_scale.x, thickness, edge.y * inner_scale.y))
			rim.append(Vector3(edge.x, thickness * (0.58 + wave * 0.28), edge.y))
			base.append(Vector3(edge.x, -0.02, edge.y))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(0.0, thickness, 0.0)
	for point_index in rim.size():
		var next := (point_index + 1) % rim.size()
		_snow_triangle(surface, center, inner[point_index], inner[next])
		_snow_triangle(surface, inner[point_index], rim[point_index], rim[next])
		_snow_triangle(surface, inner[point_index], rim[next], inner[next])
		_snow_triangle(surface, rim[point_index], base[point_index], base[next])
		_snow_triangle(surface, rim[point_index], base[next], rim[next])
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.material_override = _material(color)
	node.position = at
	parent.add_child(node)
	return node


func _roof_spike_base(parent: Node3D, at: Vector3, snow_color: Color, seed_value: int) -> Node3D:
	var base := Node3D.new()
	base.position = at
	parent.add_child(base)
	var pedestal := MeshInstance3D.new()
	pedestal.name = "Metal Cylinder"
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 0.48
	pedestal_mesh.bottom_radius = 0.48
	pedestal_mesh.height = 0.7
	pedestal.mesh = pedestal_mesh
	pedestal.material_override = _material(ROOF_SPIKE_COLOR)
	pedestal.position.y = 0.35
	base.add_child(pedestal)
	var snow_cap := MeshInstance3D.new()
	snow_cap.name = "Snow Cap"
	var snow_mesh := CylinderMesh.new()
	var snow_radius := 0.58 + 0.025 * sin(float(seed_value) * 0.73)
	snow_mesh.top_radius = snow_radius - 0.035
	snow_mesh.bottom_radius = snow_radius
	snow_mesh.height = 0.13
	snow_cap.mesh = snow_mesh
	snow_cap.material_override = _material(snow_color)
	snow_cap.position.y = 0.745
	base.add_child(snow_cap)
	return base


func _snow_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)


func _city_box(parent: Node3D, at: Vector3, size: Vector3, color: Color, unshaded: bool = false, emission_energy: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color, unshaded, emission_energy)
	node.position = at
	parent.add_child(node)
	return node


func _queue_light_halo(parent: Node3D, at: Vector3, size: Vector2, color: Color) -> void:
	_static_light_halos.append({"position": parent.to_global(at), "size": size, "color": color})


func _build_static_light_halos() -> void:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = _halo_quad
	instances.instance_count = _static_light_halos.size()
	for index in instances.instance_count:
		var halo: Dictionary = _static_light_halos[index]
		var size: Vector2 = halo["size"]
		var at: Vector3 = halo["position"]
		instances.set_instance_transform(index, Transform3D(Basis().scaled(Vector3(size.x, size.y, 1.0)), at))
		instances.set_instance_color(index, halo["color"])
	var node := MultiMeshInstance3D.new()
	node.name = "Window and Streetlamp Halos"
	node.multimesh = instances
	node.material_override = _halo_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_static_light_halos.clear()


func _add_light_halo(parent: Node3D, at: Vector3, size: Vector2, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Vehicle Light Halo %d" % parent.get_child_count()
	node.mesh = _halo_quad
	var tinted_material := _halo_material.duplicate() as StandardMaterial3D
	tinted_material.albedo_color = color
	node.material_override = tinted_material
	_halo_materials.append({"material": tinted_material, "color": color})
	node.position = at
	node.scale = Vector3(size.x, size.y, 1.0)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _add_roof_snow_glow(parent: Node3D, at: Vector3, diameter: float, color: Color) -> MeshInstance3D:
	var glow := _add_light_halo(parent, at, Vector2(diameter, diameter), color)
	(glow.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	glow.rotation.x = -PI * 0.5
	return glow


func _make_halo_material() -> StandardMaterial3D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var uv := (Vector2(float(x) + 0.5, float(y) + 0.5) / 64.0 - Vector2(0.5, 0.5)) * 2.0
			var alpha := pow(1.0 - smoothstep(0.0, 1.0, uv.length()), 2.0) * 0.58
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.albedo_color = Color.WHITE
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	return material


func _add_local_light(parent: Node3D, light_name: String, at: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = light_name
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.omni_attenuation = 2.0
	parent.add_child(light)
	_local_lights.append({"light": light, "energy": energy})
	return light


func _material(color: Color, unshaded: bool = false, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
		_emissive_materials.append({"material": material, "energy": emission_energy})
	return material


func _install_input_actions() -> void:
	_add_key("lean_left", KEY_Q)
	_add_key("lean_right", KEY_P)
	_add_key("step_left", KEY_W)
	_add_key("step_right", KEY_O)
	_add_key("skip_intro", KEY_SPACE)
	_add_key("skip_fall", KEY_SPACE)
	_add_key("release", KEY_SPACE)
	_add_key("release", KEY_E)
	_add_key("pause_run", KEY_ESCAPE)
	_add_key("restart_run", KEY_R)
	_add_joy_button("step", JOY_BUTTON_A)
	_add_joy_button("release", JOY_BUTTON_X)
	_add_joy_button("pause_run", JOY_BUTTON_START)
	_add_joy_axis("lean_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("lean_right", JOY_AXIS_LEFT_X, 1.0)


func _add_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


func _add_joy_button(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
