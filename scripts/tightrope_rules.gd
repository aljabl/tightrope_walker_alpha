class_name TightropeRules
extends RefCounted
## Pure gameplay rules ported from TightropeRules.luau.

const TOWER_COUNT := 3
const STEPS_PER_TOWER := 13
const TOWER_SPACING := 62.0
const ROOFTOP_START_OFFSET := 15.0
const ROOF_FRONT_EDGE_OFFSET := 16.0
const ROPE_ROOF_ANCHOR_OFFSET := 10.0
const ROPE_START_OFFSET := ROOF_FRONT_EDGE_OFFSET
const ROPE_LENGTH := 39.0
const STEP_COOLDOWN := 0.45
const INSTABILITY := 1.2
const LEAN_POWER := 2.4
const LEAN_KICK := 0.20
const LEAN_START_KICK := 0.50
const DAMPING := 1.8
const LEAN_SMOOTHING := 14.0
const WOBBLE := 0.28
const WIND_ENABLED := true
const WIND_PUSH := 0.9
const WIND_RAMP_TIME := 1.2
const WIND_CUE_DURATION := 0.45
const WIND_RESPONSE_TIME := 1.0
const WIND_BLOW_DURATION := 0.35
const WIND_FAIL_SHOVE := 7.0
const BIRD_APPROACH := 1.3
const BIRD_WARN := 1.0
const BIRD_REST := 1.6
const BIRD_GUST_DURATION := 0.35
const BIRD_GUST_PUSH := 1.1
const BIRD_GUST_IMPULSE := 1.2
const INTERRUPTION_SAFE_PERIOD := 1.0
const TENSION_RATE := 0.11
const TENSION_COUNTDOWN_START := 0.8
const TENSION_PER_STEP := 0.05
const TENSION_JITTER := 0.8
const RELEASE_COOLDOWN := 0.5
const STAGES := ["Wind", "Birds", "Tension"]
const BIRD_PATTERNS := [[-1, -1, -1], [1, 1, 1], [-1, 1, -1], [1, -1, 1]]

var tower := 1
var checkpoint_tower := 1
var step := 0
var on_rope := false
var state := "walking"
var time := 0.0
var stage_time := 0.0
var falls := 0
var finish_time := 0.0
var fall_reason := ""
var fall_dir := 1
var tilt := 0.0
var tilt_vel := 0.0
var lean_smooth := 0.0
var last_lean_input := 0.0
var last_step_at := -10.0
var last_release_at := -10.0
var wind_dir := 1
var wind_flag_side := 1
var wind_phase := "rest"
var wind_timer := 2.5
var wind_ramp := 0.0
var wind_response := 0
var wind_attempts := 0
var wind_passes := 0
var bird_phase := "rest"
var bird_timer := 1.8
var bird_dir := 1
var bird_dirs := [1, 1, 1]
var bird_entry_side := 1
var bird_response := 0
var bird_gust_timer := 0.0
var interruption_safe_timer := 0.0
var tension := 0.0
var push := 0.0
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	_reset_stage()


static func tower_z(tower_number: int) -> float:
	return -(tower_number - 1) * TOWER_SPACING


static func step_z(tower_number: int, step_number: int) -> float:
	var z := tower_z(tower_number)
	if step_number <= 0:
		return z - ROOFTOP_START_OFFSET
	if step_number >= STEPS_PER_TOWER:
		return tower_z(tower_number + 1) - ROOFTOP_START_OFFSET
	var first_rope_step := ROOF_FRONT_EDGE_OFFSET + 1.0
	var last_rope_step := ROPE_START_OFFSET + ROPE_LENGTH - 1.0
	return z - first_rope_step - (step_number - 1) * ((last_rope_step - first_rope_step) / (STEPS_PER_TOWER - 2))


static func rope_at(z: float) -> Dictionary:
	var index := floori((-z - ROPE_START_OFFSET) / TOWER_SPACING) + 1
	if index < 1 or index > TOWER_COUNT:
		return {}
	var progress := (tower_z(index) - ROPE_START_OFFSET - z) / ROPE_LENGTH
	if progress < 0.0 or progress > 1.0 or z >= tower_z(index) - ROOF_FRONT_EDGE_OFFSET:
		return {}
	return {"tower": index, "progress": progress}


func stage_kind() -> String:
	return STAGES[tower - 1]


func birds_enabled() -> bool:
	return tower >= 2


func tension_enabled() -> bool:
	return tower >= 3


static func bird_check(response_direction: int, direction: int) -> bool:
	return response_direction == direction


func update(delta: float, lean: float, gust_response: int = 0) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != "walking":
		return events
	var dt := minf(delta, 0.1)
	time += dt
	if not on_rope:
		tilt = 0.0
		tilt_vel = 0.0
		lean_smooth = 0.0
		last_lean_input = 0.0
		push = 0.0
		return events
	stage_time += dt
	interruption_safe_timer = maxf(0.0, interruption_safe_timer - dt)
	var stage_push := sin(time * 1.7) * WOBBLE + sin(time * 3.1 + 1.0) * WOBBLE * 0.45
	if WIND_ENABLED:
		stage_push += _update_wind(dt, gust_response, events)
	if birds_enabled():
		if bird_gust_timer > 0.0:
			bird_gust_timer = maxf(0.0, bird_gust_timer - dt)
			stage_push -= bird_dir * BIRD_GUST_PUSH
			if bird_gust_timer <= 0.0:
				interruption_safe_timer = INTERRUPTION_SAFE_PERIOD
		var bird_had_time := bird_timer > 0.0
		bird_timer -= dt
		if bird_phase == "rest" and bird_timer <= 0.0 and wind_phase == "rest" and interruption_safe_timer <= 0.0:
			bird_phase = "approach"
			bird_timer = BIRD_APPROACH
			bird_entry_side = _random_sign()
			bird_dirs = BIRD_PATTERNS[_rng.randi_range(0, BIRD_PATTERNS.size() - 1)].duplicate()
			bird_dir = bird_dirs[1]
			bird_response = 0
			events.append({"type": "birds", "entry_side": bird_entry_side})
		elif bird_phase == "approach" and bird_timer <= 0.0:
			bird_phase = "warn"
			bird_timer = BIRD_WARN
			events.append({"type": "birds_arrived", "dir": bird_dir})
		elif bird_phase == "warn":
			if bird_had_time and bird_response == 0 and absf(lean) > 0.5:
				bird_response = 1 if lean > 0.0 else -1
			if bird_response != 0 or bird_timer <= 0.0:
				bird_phase = "rest"
				bird_timer = BIRD_REST
				bird_gust_timer = BIRD_GUST_DURATION
				stage_push -= bird_dir * BIRD_GUST_PUSH
				tilt_vel -= bird_dir * BIRD_GUST_IMPULSE
				var survived := bird_check(bird_response, bird_dir)
				if survived:
					events.append({"type": "birds_pass"})
				events.append({"type": "bird_gust", "dir": -bird_dir})
				if not survived:
					_fall("birds", events, -bird_dir)
					return events
	if tension_enabled():
		tension += dt * TENSION_RATE
		stage_push += sin(time * 11.0) * tension * TENSION_JITTER
		if tension >= 1.0:
			tension = 1.0
			_fall("snap", events)
			return events
	push = stage_push
	var lean_input := clampf(lean, -1.0, 1.0)
	var kick := LEAN_START_KICK if absf(lean_input) > absf(last_lean_input) else LEAN_KICK
	tilt_vel += (lean_input - last_lean_input) * kick
	last_lean_input = lean_input
	lean_smooth += (lean_input - lean_smooth) * minf(1.0, dt * LEAN_SMOOTHING)
	var acceleration := tilt * INSTABILITY + push + lean_smooth * LEAN_POWER - tilt_vel * DAMPING
	tilt_vel += acceleration * dt
	tilt += tilt_vel * dt
	if absf(tilt) >= 1.0:
		tilt = clampf(tilt, -1.0, 1.0)
		_fall("balance", events)
	return events


func _update_wind(dt: float, response: int, events: Array[Dictionary]) -> float:
	var gust_push := 0.0
	var had_time := wind_timer > 0.0
	if wind_phase == "rest":
		wind_timer -= dt
		if interruption_safe_timer > 0.0 or (birds_enabled() and (bird_phase != "rest" or bird_gust_timer > 0.0)):
			return 0.0
		if wind_timer <= 0.0:
			wind_dir = _random_sign()
			wind_flag_side = -wind_dir
			wind_phase = "cue"
			wind_timer = WIND_CUE_DURATION
			wind_ramp = 0.0
			wind_response = 0
			events.append({"type": "gust_cue", "side": wind_flag_side})
	elif wind_phase == "cue":
		wind_timer -= dt
		if wind_timer <= 0.0:
			wind_phase = "react"
			wind_timer = WIND_RESPONSE_TIME
			wind_attempts += 1
			events.append({"type": "gust", "dir": wind_dir})
	elif wind_phase == "react":
		wind_timer -= dt
		wind_ramp = minf(1.0, wind_ramp + dt / WIND_RAMP_TIME)
		gust_push = wind_dir * WIND_PUSH * wind_ramp
		if had_time and response != 0:
			wind_response = signi(response)
		if wind_response != 0 or wind_timer <= 0.0:
			var passed := wind_response == -wind_flag_side
			if passed:
				wind_passes += 1
				events.append({"type": "gust_pass"})
			else:
				tilt_vel += wind_dir * WIND_FAIL_SHOVE
				events.append({"type": "gust_fail", "dir": wind_dir})
			wind_phase = "blow"
			wind_timer = WIND_BLOW_DURATION
	elif wind_phase == "blow":
		wind_timer -= dt
		wind_ramp = minf(1.0, wind_ramp + dt / WIND_RAMP_TIME)
		gust_push = wind_dir * WIND_PUSH * wind_ramp
		if wind_timer <= 0.0:
			wind_phase = "rest"
			wind_timer = _rng.randf_range(3.2, 4.6)
			wind_ramp = 0.0
			interruption_safe_timer = INTERRUPTION_SAFE_PERIOD
	return gust_push


func try_step() -> String:
	if state != "walking":
		return "blocked"
	if time - last_step_at < STEP_COOLDOWN:
		return "cooldown"
	if step > 0 and not on_rope:
		return "blocked"
	last_step_at = time
	var result := "ok"
	if on_rope and tension_enabled():
		tension = minf(0.99, tension + TENSION_PER_STEP)
	if on_rope:
		tilt_vel += _rng.randf_range(-0.3, 0.3)
	step += 1
	if step >= STEPS_PER_TOWER:
		if tower >= TOWER_COUNT:
			state = "won"
			finish_time = time
			return "won"
		tower += 1
		var keep_time := time
		_reset_stage()
		last_step_at = keep_time
		return "tower"
	return result


func release() -> String:
	if state != "walking" or not on_rope or not tension_enabled():
		return "none"
	if time - last_release_at < RELEASE_COOLDOWN:
		return "cooldown"
	last_release_at = time
	tension = 0.0
	tilt_vel += _rng.randf_range(-0.25, 0.25)
	return "released"


func respawn() -> int:
	tower = checkpoint_tower
	_reset_stage()
	state = "walking"
	fall_reason = ""
	return tower


func reach_tower() -> void:
	if state == "walking" and step == 0:
		checkpoint_tower = tower


func reach_rope() -> void:
	if state == "walking" and step == 1:
		on_rope = true


func _fall(reason: String, events: Array[Dictionary], direction: int = 0) -> void:
	state = "falling"
	falls += 1
	fall_reason = reason
	fall_dir = direction if direction != 0 else (1 if tilt >= 0.0 else -1)
	events.append({"type": "fall", "reason": reason})


func _random_sign() -> int:
	return _rng.randi_range(0, 1) * 2 - 1


func _reset_stage() -> void:
	step = 0
	on_rope = false
	tilt = 0.0
	tilt_vel = 0.0
	lean_smooth = 0.0
	last_lean_input = 0.0
	stage_time = 0.0
	last_step_at = -10.0
	last_release_at = -10.0
	wind_dir = _random_sign()
	wind_flag_side = -wind_dir
	wind_phase = "rest"
	wind_timer = 2.5
	wind_ramp = 0.0
	wind_response = 0
	bird_phase = "rest"
	bird_timer = 1.8
	bird_dir = 1
	bird_dirs = [1, 1, 1]
	bird_entry_side = 1
	bird_response = 0
	bird_gust_timer = 0.0
	interruption_safe_timer = 0.0
	tension = 0.0
	push = 0.0
