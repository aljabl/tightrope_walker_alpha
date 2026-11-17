extends SceneTree
## Run with: godot --headless --path . --script res://tests/test_rules.gd

const Rules := preload("res://scripts/tightrope_rules.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_test_path()
	_test_safe_checkpoints()
	_test_steps_and_checkpoints()
	_test_checkpoint_respawn()
	_test_gust_warning()
	_test_birds()
	_test_interruption_safe_period()
	_test_tension()
	_test_final_stage_combo()
	_test_determinism()
	_test_full_run(11)
	_test_full_run(29)
	if failures.is_empty():
		print("PASS: all tightrope rule tests")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)


func _test_path() -> void:
	for tower in range(1, Rules.TOWER_COUNT):
		_check(is_equal_approx(Rules.step_z(tower, Rules.STEPS_PER_TOWER), Rules.step_z(tower + 1, 0)), "tower %d path continuity" % tower)
	for tower in range(1, Rules.TOWER_COUNT + 1):
		_check(Rules.rope_at(Rules.step_z(tower, 0)).is_empty(), "tower %d start is on deck" % tower)
		for step in range(1, Rules.STEPS_PER_TOWER):
			_check(Rules.rope_at(Rules.step_z(tower, step)).get("tower", -1) == tower, "tower %d step %d is on rope" % [tower, step])


func _test_safe_checkpoints() -> void:
	for tower_number in range(1, Rules.TOWER_COUNT + 1):
		var run := Rules.new(100 + tower_number)
		run.tower = tower_number
		run.tilt = 0.99
		run.tilt_vel = 2.0
		run.bird_timer = 0.0
		run.tension = 0.99
		var events := run.update(0.1, 1.0)
		_check(events.is_empty() and run.state == "walking" and not run.on_rope and is_zero_approx(run.tilt) and is_zero_approx(run.stage_time), "tower %d checkpoint ignores balance and interruptions" % tower_number)
		_check(run.try_step() == "ok" and run.step == 1 and not run.on_rope, "tower %d first step begins from rooftop" % tower_number)
		for tick in 4:
			events = run.update(0.1, 1.0)
			_check(events.is_empty() and run.state == "walking" and is_zero_approx(run.stage_time), "tower %d first step stays safe until it reaches the rope" % tower_number)
		run.tension = 0.0
		run.reach_rope()
		run.update(1.0 / 60.0, 0.0)
		_check(run.on_rope and run.stage_time > 0.0, "tower %d activates rules after reaching the rope" % tower_number)


func _test_steps_and_checkpoints() -> void:
	var run := Rules.new(1)
	_check(not run.on_rope, "start tower begins off the rope")
	_check(run.try_step() == "ok", "first press steps")
	_check(run.try_step() == "cooldown" and run.step == 1, "rapid second press is ignored")
	run.time += 0.5
	_check(run.try_step() == "blocked" and not run.on_rope, "second step waits for the first step to reach the rope")
	run.reach_rope()
	_check(run.on_rope, "first completed step activates balance")
	for index in Rules.STEPS_PER_TOWER - 1:
		run.time += 0.5
		run.tilt = 0.0
		var result := run.try_step()
		if index == Rules.STEPS_PER_TOWER - 2:
			_check(result == "tower" and run.tower == 2 and run.step == 0, "%d steps reach tower two" % Rules.STEPS_PER_TOWER)
		else:
			_check(result == "ok" and run.tower == 1, "step %d stays on the first rope" % (index + 2))
	run.tower = 3
	run.checkpoint_tower = 3
	run.time += 0.5
	_check(run.try_step() == "ok", "checkpoint first step begins")
	run.reach_rope()
	run.tilt = 0.99
	run.tilt_vel = 2.0
	var events := run.update(1.0 / 60.0, 0.0)
	_check(run.state == "falling" and events.back().get("type") == "fall", "balance fall fires event")
	run.respawn()
	_check(run.state == "walking" and run.tower == 3 and run.step == 0 and not run.on_rope, "fall restarts safely on same tower")


func _test_checkpoint_respawn() -> void:
	var run := Rules.new(13)
	for reached in range(1, Rules.TOWER_COUNT + 1):
		_check(run.tower == reached and run.checkpoint_tower == reached and not run.on_rope, "tower %d is a safe checkpoint" % reached)
		run.time += 0.5
		_check(run.try_step() == "ok", "tower %d first step begins" % reached)
		run.reach_rope()
		_force_balance_fall(run)
		run.respawn()
		_check(run.tower == reached and run.step == 0 and not run.on_rope, "fall before next tower respawns safely at tower %d" % reached)
		if reached == Rules.TOWER_COUNT:
			break
		for step_number in Rules.STEPS_PER_TOWER:
			run.time += 0.5
			var result := run.try_step()
			if step_number == 0:
				_check(not run.on_rope, "tower %d first step is safe until landing on rope" % reached)
				run.reach_rope()
			if step_number == Rules.STEPS_PER_TOWER - 1:
				_check(result == "tower" and run.tower == reached + 1 and not run.on_rope, "tower %d landing begins safely" % reached)
		_check(run.checkpoint_tower == reached, "checkpoint waits for landing on tower %d" % (reached + 1))
		run.tilt = 0.99
		run.tilt_vel = 2.0
		_check(run.update(1.0 / 60.0, 0.0).is_empty() and run.state == "walking" and is_zero_approx(run.tilt), "balance cannot fail during tower landing")
		run.reach_tower()
		_check(run.checkpoint_tower == reached + 1, "landing saves tower %d checkpoint" % (reached + 1))


func _force_balance_fall(run: TightropeRules) -> void:
	run.tilt = 0.99
	run.tilt_vel = 2.0
	var events := run.update(1.0 / 60.0, 0.0)
	_check(run.state == "falling" and events.back().get("type") == "fall", "balance fall triggers for checkpoint test")


func _enter_rope(run: TightropeRules) -> void:
	_check(run.try_step() == "ok", "first step onto rope begins")
	run.reach_rope()
	_check(run.on_rope, "first step onto rope completes")


func _test_gust_warning() -> void:
	var run := Rules.new(8)
	_check(run.stage_kind() == "Wind", "first section introduces gust warning")
	run.wind_timer = 0.01
	_check(run.update(0.1, 0.0).is_empty() and run.wind_phase == "rest", "gust does not start on the rooftop")
	_enter_rope(run)
	var events := run.update(1.0 / 60.0, 0.0)
	_check(run.wind_phase == "cue" and run.wind_flag_side == -run.wind_dir and events.size() == 1 and events[0]["type"] == "gust_cue" and events[0]["side"] == run.wind_flag_side and is_zero_approx(run.wind_ramp), "congruent flag cue precedes the gust")
	run.wind_timer = 0.0
	events = run.update(1.0 / 60.0, 0.0, run.wind_flag_side)
	_check(run.wind_phase == "react" and is_equal_approx(run.wind_timer, Rules.WIND_RESPONSE_TIME) and run.wind_attempts == 1 and run.wind_response == 0 and events.size() == 1 and events[0]["type"] == "gust", "reaction countdown starts when gust arrives")
	run.wind_dir = 1
	run.wind_flag_side = -1
	run.wind_timer = 0.5
	events = run.update(1.0 / 60.0, 1.0, 1)
	_check(run.wind_phase == "blow" and run.wind_response == 1 and run.wind_passes == 1 and events.any(func(event: Dictionary) -> bool: return event["type"] == "gust_pass"), "lean opposite flag passes and ends countdown early")
	for frame in 36:
		run.update(1.0 / 60.0, 0.0)
	_check(run.state == "walking", "correct gust response survives the blow")
	run.respawn()
	_check(run.wind_attempts == 1 and run.wind_passes == 1 and run.wind_phase == "rest", "gust statistics persist across checkpoint respawns")
	var wrong := Rules.new(9)
	_enter_rope(wrong)
	wrong.wind_phase = "react"
	wrong.wind_timer = 0.5
	wrong.wind_dir = 1
	wrong.wind_flag_side = -1
	events = wrong.update(1.0 / 60.0, -1.0, -1)
	_check(wrong.wind_phase == "blow" and wrong.tilt_vel > 6.0 and events.any(func(event: Dictionary) -> bool: return event["type"] == "gust_fail"), "lean toward left flag triggers strong gust")
	for frame in 36:
		if wrong.state == "falling":
			break
		wrong.update(1.0 / 60.0, -1.0)
	_check(wrong.state == "falling" and wrong.fall_reason == "balance", "lean toward left flag causes a fall")
	var wrong_right := Rules.new(12)
	_enter_rope(wrong_right)
	wrong_right.wind_phase = "react"
	wrong_right.wind_timer = 0.5
	wrong_right.wind_dir = -1
	wrong_right.wind_flag_side = 1
	wrong_right.update(1.0 / 60.0, 1.0, 1)
	for frame in 36:
		if wrong_right.state == "falling":
			break
		wrong_right.update(1.0 / 60.0, 1.0)
	_check(wrong_right.state == "falling" and wrong_right.fall_reason == "balance", "lean toward right flag causes a fall")
	var late := Rules.new(10)
	_enter_rope(late)
	late.wind_phase = "react"
	late.wind_timer = 0.01
	late.wind_dir = -1
	late.wind_flag_side = 1
	events = late.update(1.0 / 60.0, 0.0)
	_check(late.wind_phase == "blow" and late.tilt_vel < -6.0 and events.any(func(event: Dictionary) -> bool: return event["type"] == "gust_fail"), "late response triggers strong gust")
	var last_frame := Rules.new(11)
	_enter_rope(last_frame)
	last_frame.wind_phase = "react"
	last_frame.wind_timer = 0.01
	last_frame.wind_dir = -1
	last_frame.wind_flag_side = 1
	last_frame.update(1.0 / 60.0, -1.0, -1)
	_check(last_frame.wind_passes == 1, "lean in final reaction frame passes")
	var incongruent_cues := 0
	for seed_value in range(1, 401):
		var trial := Rules.new(seed_value)
		trial.wind_timer = 0.0
		_enter_rope(trial)
		trial.update(1.0 / 60.0, 0.0)
		if trial.wind_flag_side == trial.wind_dir:
			incongruent_cues += 1
	_check(incongruent_cues == 0, "all gust flag cues show the actual gust source")
	var later := Rules.new(12)
	later.tower = 3
	_enter_rope(later)
	later.wind_timer = 0.0
	later.update(1.0 / 60.0, 0.0)
	_check(later.wind_phase == "cue" and later.wind_flag_side == -later.wind_dir, "congruent gust warning remains active in later sections")
	var birds := Rules.new(13)
	birds.tower = 2
	_enter_rope(birds)
	birds.bird_phase = "warn"
	birds.bird_timer = 0.5
	birds.wind_timer = 0.0
	birds.update(1.0 / 60.0, 0.0)
	_check(birds.wind_phase == "rest", "gust cue waits for active birds")


func _test_birds() -> void:
	var run := Rules.new(4)
	run.tower = 2
	_enter_rope(run)
	run.bird_timer = 0.0
	var events := run.update(1.0 / 60.0, 0.0)
	_check(events.size() == 1 and events[0]["type"] == "birds" and run.bird_phase == "approach", "birds approach before warning")
	_check(run.bird_entry_side == -1 or run.bird_entry_side == 1, "birds enter from a side")
	_check(Rules.BIRD_PATTERNS.has(run.bird_dirs) and run.bird_dir == run.bird_dirs[1], "bird pattern is valid and the center sets the response")
	run.bird_timer = Rules.BIRD_APPROACH * 0.5
	events = run.update(1.0 / 60.0, 0.0)
	_check(run.bird_phase == "approach" and events.is_empty() and is_zero_approx(run.bird_gust_timer), "gust does not trigger during approach")
	run.bird_timer = 0.0
	events = run.update(1.0 / 60.0, 0.0)
	_check(run.bird_phase == "warn" and is_equal_approx(run.bird_timer, 1.0) and events.size() == 1 and events[0]["type"] == "birds_arrived", "one-second reaction countdown starts when birds arrive")
	run.bird_timer = 0.5
	run.tilt_vel = 0.0
	events = run.update(1.0 / 60.0, -float(run.bird_dir))
	_check(run.bird_response == -run.bird_dir and run.bird_phase == "rest" and is_equal_approx(run.bird_timer, Rules.BIRD_REST), "wrong response ends and resets countdown immediately")
	_check(run.state == "falling" and run.fall_dir == -run.bird_dir and events.back().get("reason") == "birds", "wrong lean falls in gust direction")
	_check(events.any(func(event: Dictionary) -> bool: return event["type"] == "bird_gust" and event["dir"] == -run.bird_dir), "gust triggers immediately on wrong response")
	_check(run.tilt_vel * run.bird_dir < 0.0, "bird gust pushes opposite the center bird")
	var correct := Rules.new(5)
	correct.tower = 2
	_enter_rope(correct)
	correct.bird_phase = "warn"
	correct.bird_timer = Rules.BIRD_WARN
	correct.bird_dir = 1
	for tick in 5:
		correct.update(0.1, 0.0)
	_check(correct.bird_phase == "warn" and is_equal_approx(correct.bird_timer, 0.5) and is_zero_approx(correct.bird_gust_timer), "no gust before a half-second response")
	correct.tilt_vel = 0.4
	events = correct.update(1.0 / 60.0, 1.0)
	_check(correct.bird_response == 1 and correct.state == "walking" and correct.bird_phase == "rest" and is_equal_approx(correct.bird_timer, Rules.BIRD_REST) and correct.bird_gust_timer > 0.0 and correct.tilt_vel < 0.0, "half-second response resets countdown and survives immediate gust")
	_check(events.any(func(event: Dictionary) -> bool: return event["type"] == "birds_pass") and events.any(func(event: Dictionary) -> bool: return event["type"] == "bird_gust" and event["dir"] == -1), "success emits pass and gust events")
	var last_frame := Rules.new(7)
	last_frame.tower = 2
	_enter_rope(last_frame)
	last_frame.bird_phase = "warn"
	last_frame.bird_timer = 0.01
	last_frame.bird_dir = -1
	last_frame.update(1.0 / 60.0, -1.0)
	_check(last_frame.state == "walking" and last_frame.bird_response == -1 and last_frame.bird_gust_timer > 0.0, "lean registered in the final countdown frame triggers the gust")
	correct.update(1.0 / 60.0, 1.0)
	_check(correct.push < 0.0 and correct.bird_gust_timer < Rules.BIRD_GUST_DURATION, "bird gust continues briefly after countdown")
	var idle := Rules.new(6)
	idle.tower = 2
	_enter_rope(idle)
	idle.bird_phase = "warn"
	idle.bird_timer = 0.0
	idle.update(1.0 / 60.0, 0.0)
	_check(idle.state == "falling" and idle.fall_dir == -idle.bird_dir, "missing response fails in gust direction")
	var saw_left := false
	var saw_right := false
	var seen_patterns: Array = []
	for seed_value in range(1, 101):
		var flock := Rules.new(seed_value)
		flock.tower = 2
		_enter_rope(flock)
		flock.bird_timer = 0.0
		flock.update(1.0 / 60.0, 0.0)
		saw_left = saw_left or flock.bird_entry_side == -1
		saw_right = saw_right or flock.bird_entry_side == 1
		if not seen_patterns.has(flock.bird_dirs):
			seen_patterns.append(flock.bird_dirs.duplicate())
	_check(saw_left and saw_right, "bird entry side varies across seeded rounds")
	_check(seen_patterns.size() == 4 and seen_patterns.has([-1, -1, -1]) and seen_patterns.has([1, 1, 1]) and seen_patterns.has([-1, 1, -1]) and seen_patterns.has([1, -1, 1]), "all congruent and incongruent bird conditions occur")
	_check(Rules.bird_check(1, 1) and Rules.bird_check(-1, -1), "correct bird lean passes")
	_check(not Rules.bird_check(0, 1) and not Rules.bird_check(-1, 1), "missing or wrong bird lean fails")


func _test_interruption_safe_period() -> void:
	var after_wind := Rules.new(14)
	after_wind.tower = 2
	_enter_rope(after_wind)
	after_wind.wind_phase = "blow"
	after_wind.wind_timer = 0.01
	after_wind.bird_timer = 0.0
	after_wind.update(1.0 / 60.0, 0.0)
	_check(after_wind.wind_phase == "rest" and after_wind.bird_phase == "rest" and is_equal_approx(after_wind.interruption_safe_timer, Rules.INTERRUPTION_SAFE_PERIOD), "wind blow starts safe period before birds can approach")
	for frame in 59:
		after_wind.update(1.0 / 60.0, 0.0)
	_check(after_wind.bird_phase == "rest" and after_wind.interruption_safe_timer > 0.0, "birds wait throughout safe period after wind")
	after_wind.update(1.0 / 60.0, 0.0)
	after_wind.update(1.0 / 60.0, 0.0)
	_check(after_wind.bird_phase == "approach", "birds may approach after safe period expires")

	var after_birds := Rules.new(15)
	after_birds.tower = 2
	_enter_rope(after_birds)
	after_birds.bird_gust_timer = 0.01
	after_birds.bird_timer = 100.0
	after_birds.wind_timer = 0.0
	after_birds.update(1.0 / 60.0, 0.0)
	_check(after_birds.wind_phase == "rest" and is_equal_approx(after_birds.interruption_safe_timer, Rules.INTERRUPTION_SAFE_PERIOD), "bird gust starts safe period before wind can cue")
	for frame in 59:
		after_birds.update(1.0 / 60.0, 0.0)
	_check(after_birds.wind_phase == "rest" and after_birds.interruption_safe_timer > 0.0, "wind waits throughout safe period after birds")
	after_birds.update(1.0 / 60.0, 0.0)
	after_birds.update(1.0 / 60.0, 0.0)
	_check(after_birds.wind_phase == "cue", "wind may cue after safe period expires")

	var tower_two := Rules.new(16)
	tower_two.tower = 2
	_enter_rope(tower_two)
	var saw_birds := false
	var saw_flag := false
	for frame in 60 * 7:
		tower_two.tilt = 0.0
		tower_two.tilt_vel = 0.0
		var lean := float(tower_two.bird_dir) if tower_two.bird_phase == "warn" else 0.0
		var response := -tower_two.wind_flag_side if tower_two.wind_phase == "react" else 0
		var events := tower_two.update(1.0 / 60.0, lean, response)
		for event in events:
			if event["type"] == "birds":
				saw_birds = true
			elif event["type"] == "gust_cue":
				saw_flag = true
				_check(tower_two.bird_phase == "rest" and tower_two.bird_gust_timer <= 0.0 and tower_two.interruption_safe_timer <= 0.0, "tower two flag starts only after birds and safe period")
		if saw_flag or tower_two.state != "walking":
			break
	_check(saw_birds and saw_flag and tower_two.state == "walking", "tower two shows both bird and flag interruptions")


func _test_tension() -> void:
	var run := Rules.new(5)
	run.tower = 3
	_check(run.release() == "none", "tension cannot be released on checkpoint")
	_enter_rope(run)
	run.tension = 0.7
	_check(run.release() == "released" and run.tension == 0.0, "release resets tension")
	_check(run.release() == "cooldown", "release has cooldown")
	run.tension = 0.995
	var events := run.update(0.1, 0.0)
	_check(run.state == "falling" and events.back().get("reason") == "snap", "full tension snaps rope")


func _test_final_stage_combo() -> void:
	var run := Rules.new(17)
	run.tower = Rules.TOWER_COUNT
	_check(run.stage_kind() == "Tension" and run.birds_enabled() and run.tension_enabled(), "final stage enables birds and tension alongside wind")
	_check(Rules.new(1).birds_enabled() == false and Rules.new(1).tension_enabled() == false, "first stage has wind only")
	var second := Rules.new(1)
	second.tower = 2
	_check(second.birds_enabled() and not second.tension_enabled(), "second stage adds birds and keeps tension for the final stage")
	_enter_rope(run)
	var saw_birds := false
	var saw_wind := false
	var released_tension := false
	for frame in 60 * 12:
		run.tilt = 0.0
		run.tilt_vel = 0.0
		var lean := float(run.bird_dir) if run.bird_phase == "warn" else 0.0
		var response := -run.wind_flag_side if run.wind_phase == "react" else 0
		for event in run.update(1.0 / 60.0, lean, response):
			if event["type"] == "birds_pass":
				saw_birds = true
			elif event["type"] == "gust_pass":
				saw_wind = true
		if run.tension > 0.5:
			released_tension = run.release() == "released" or released_tension
		if saw_birds and saw_wind and released_tension:
			break
	_check(run.state == "walking" and saw_birds and saw_wind and released_tension, "final stage runs all three interruptions and lets the player pass them")

	var step_run := Rules.new(18)
	step_run.tower = Rules.TOWER_COUNT
	_enter_rope(step_run)
	step_run.time += 0.5
	step_run.tension = 0.1
	_check(step_run.try_step() == "ok" and is_equal_approx(step_run.tension, 0.1 + Rules.TENSION_PER_STEP), "final stage step adds tension")
	_check(step_run.release() == "released" and is_zero_approx(step_run.tension), "final stage can release tension")
	step_run.tension = 0.995
	var snap_events := step_run.update(0.1, 0.0)
	_check(step_run.state == "falling" and snap_events.any(func(event: Dictionary) -> bool: return event.get("reason") == "snap"), "final stage wire still snaps at full tension")


func _test_determinism() -> void:
	var first := Rules.new(42)
	var second := Rules.new(42)
	_enter_rope(first)
	_enter_rope(second)
	for tick in 180:
		var lean := sin(float(tick) * 0.12)
		first.update(1.0 / 60.0, lean)
		second.update(1.0 / 60.0, lean)
		_check(first.wind_dir == second.wind_dir and first.wind_phase == second.wind_phase and first.wind_flag_side == second.wind_flag_side and is_equal_approx(first.tilt, second.tilt), "seeded run diverges at tick %d" % tick)


func _test_full_run(seed_value: int) -> void:
	var run := Rules.new(seed_value)
	var since_step := 0.0
	var final_stage_birds := false
	var final_stage_wind := false
	var final_stage_tension := false
	for tick in 60 * 400:
		var target := 0.0
		if run.birds_enabled() and run.bird_phase == "warn":
			target = 0.3 * run.bird_dir
		var lean: float = clampf(-((run.tilt - target) * 2.5 + run.tilt_vel * 1.4) - (run.push + run.tilt * Rules.INSTABILITY) / Rules.LEAN_POWER, -1.0, 1.0)
		var gust_response := -run.wind_flag_side if run.wind_phase == "react" else 0
		var events := run.update(1.0 / 60.0, lean, gust_response)
		for event in events:
			if run.tower == Rules.TOWER_COUNT:
				final_stage_birds = final_stage_birds or event["type"] == "birds"
				final_stage_wind = final_stage_wind or event["type"] == "gust_cue"
			if event["type"] == "fall":
				run.respawn()
		if run.tension_enabled() and run.tension > 0.6:
			final_stage_tension = final_stage_tension or run.tower == Rules.TOWER_COUNT
			run.release()
		since_step += 1.0 / 60.0
		var can_step := since_step > 0.5 and absf(run.tilt) < 0.35
		if run.birds_enabled() and run.bird_phase == "warn":
			can_step = false
		# On the last rope, hold short of the roof until the wind and the birds have
		# both had a turn, so the test proves they stack with the tension gauge.
		if run.tower == Rules.TOWER_COUNT and run.step >= Rules.STEPS_PER_TOWER - 2 and not (final_stage_birds and final_stage_wind):
			can_step = false
		if can_step:
			var result := run.try_step()
			if result != "cooldown":
				since_step = 0.0
			if run.step == 1 and not run.on_rope:
				run.reach_rope()
			if result == "tower":
				run.reach_tower()
			if result == "won":
				_check(run.state == "won" and run.tower == Rules.TOWER_COUNT, "seed %d win state" % seed_value)
				_check(final_stage_birds and final_stage_wind and final_stage_tension, "seed %d encountered all three minigames in the final stage" % seed_value)
				return
	_check(false, "seed %d could not complete course" % seed_value)
