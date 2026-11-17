class_name GameHUD
extends CanvasLayer
## On-screen status and menus for keyboard and gamepad players.

signal replay_requested
signal stargaze_requested
signal pause_requested

const CREAM := Color("fff4e4")
const GOLD := Color("ffca62")
const CORAL := Color("ff6a58")
const WARNING_RED := Color("ff3b3b")
const WireGaugeScene := preload("res://scripts/wire_tension_gauge.gd")
const MINT := Color("7ee8ac")
const PANEL := Color("211e36e8")
const MUTED := Color("b7b5c9")
const COUNTDOWN_BAR_HEIGHT := 4.0
const TOP_BANNER_SIDE_MARGIN := 24.0
const TOP_BANNER_TOP_MARGIN := 16.0
const TOP_BANNER_HEIGHT := 174.0
const TOP_BANNER_RIGHT := 390.0
const TITLE_PANEL_WIDTH := 640.0
const TITLE_BANNER_GAP := 16.0

var _progress: Label
var _stage: Label
var _run_timer: Label
var _cue: Label
var _step_control: Label
var _lean_control: Label
var _space_control: Label
var _balance: ProgressBar
var _wire_gauge: WireTensionGauge
var _wire_gauge_panel: PanelContainer
var _countdown_track: Panel
var _countdown_fill: Panel
var _countdown_fill_style: StyleBoxFlat
var _wire_countdown_track: Panel
var _wire_countdown_fill: Panel
var _wire_countdown_fill_style: StyleBoxFlat
var _caption: Label
var _toast: Label
var _toast_generation := 0
var _toast_tween: Tween
var _win: PanelContainer
var _win_text: Label
var _paused: PanelContainer
var _scrim: ColorRect
var _tower_marks: Array[Panel] = []
var _title: PanelContainer
var _title_prompt: Label
var _title_tween: Tween


func _ready() -> void:
	_build()
	get_viewport().size_changed.connect(_place_title)


func show_status(tower: int, step: int, steps: int, kind: String, tilt: float, cue: String, tension: float = 0.0, run_seconds: float = 0.0) -> void:
	_progress.text = "TOWER %02d / %02d     STEP %02d / %02d" % [tower, TightropeRules.TOWER_COUNT, step, steps]
	_stage.text = kind.to_upper()
	var elapsed_tenths := roundi(maxf(0.0, run_seconds) * 10.0)
	_run_timer.text = "TIME %02d:%02d.%d" % [floori(float(elapsed_tenths) / 600.0), floori(float(elapsed_tenths % 600) / 10.0), elapsed_tenths % 10]
	_cue.text = cue
	_wire_gauge_panel.visible = tower >= TightropeRules.TOWER_COUNT
	_wire_gauge.set_tension(tension)
	_balance.value = clampf((tilt + 1.0) * 50.0, 0.0, 100.0)
	var fill := _balance.get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = CORAL if absf(tilt) >= 0.7 else GOLD
	for index in _tower_marks.size():
		var style := _tower_marks[index].get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = GOLD if index < tower else Color("5b586f")


func show_space_control(message: String) -> void:
	_space_control.text = message
	_space_control.visible = not message.is_empty()


func show_countdown_bar(screen_position: Vector2, width: float, remaining_fraction: float) -> void:
	var fraction := clampf(remaining_fraction, 0.0, 1.0)
	if fraction <= 0.0:
		hide_countdown_bar()
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var timer_width := clampf(width, 40.0, viewport_size.x - 24.0)
	var minimum_y := TOP_BANNER_TOP_MARGIN + TOP_BANNER_HEIGHT + 8.0
	_countdown_track.size.x = timer_width
	_countdown_track.position = Vector2(
		clampf(screen_position.x - timer_width * 0.5, 12.0, maxf(12.0, viewport_size.x - timer_width - 12.0)),
		clampf(screen_position.y, minimum_y, maxf(minimum_y, viewport_size.y - COUNTDOWN_BAR_HEIGHT - 12.0))
	)
	_countdown_fill.size.x = timer_width * fraction
	_countdown_fill_style.bg_color = WARNING_RED if fraction <= 0.2501 else GOLD
	_countdown_track.show()


func show_wire_countdown_bar(remaining_fraction: float) -> void:
	var fraction := clampf(remaining_fraction, 0.0, 1.0)
	if fraction <= 0.0:
		hide_wire_countdown_bar()
		return
	var gauge_rect := _wire_gauge_panel.get_global_rect()
	var timer_width := gauge_rect.size.x - 16.0
	_wire_countdown_track.position = Vector2(gauge_rect.position.x + 8.0, gauge_rect.end.y + 8.0)
	_wire_countdown_track.size.x = timer_width
	_wire_countdown_fill.size.x = timer_width * fraction
	_wire_countdown_fill_style.bg_color = WARNING_RED if fraction <= 0.2501 else GOLD
	_wire_countdown_track.show()


func hide_wire_countdown_bar() -> void:
	_wire_countdown_track.hide()


func hide_countdown_bar() -> void:
	_countdown_track.hide()


func show_toast(message: String, duration: float = 3.0, font_size: int = 18) -> void:
	_toast_generation += 1
	var generation := _toast_generation
	if _toast_tween != null and _toast_tween.is_running():
		_toast_tween.kill()
	_toast.add_theme_font_size_override("font_size", font_size)
	_toast.text = message
	_toast.visible = true
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.18)
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_toast) and _toast_generation == generation:
			_toast_tween = create_tween()
			_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.22)
			_toast_tween.tween_callback(func() -> void: _toast.visible = false)
	)


func hide_toast() -> void:
	_toast_generation += 1
	if _toast_tween != null and _toast_tween.is_running():
		_toast_tween.kill()
	_toast.text = ""
	_toast.hide()


func show_caption(message: String) -> void:
	_caption.text = message
	_caption.visible = not message.is_empty()


func show_win(seconds: float, falls: int, best_time: float) -> void:
	_win_text.text = "YOU CROSSED THE SKY\n\nTime: %.1f s    Falls: %d\nBest: %.1f s" % [seconds, falls, best_time]
	_win.visible = true
	_scrim.visible = true


func hide_win() -> void:
	_win.visible = false
	_scrim.visible = _paused.visible


func set_paused(value: bool) -> void:
	_paused.visible = value
	_scrim.visible = value or _win.visible


func show_title() -> void:
	_title.visible = true
	_place_title()
	if _title_tween != null and _title_tween.is_running():
		_title_tween.kill()
	_title_prompt.modulate.a = 1.0
	_title_tween = create_tween().set_loops()
	_title_tween.tween_property(_title_prompt, "modulate:a", 0.3, 0.7).set_trans(Tween.TRANS_SINE)
	_title_tween.tween_property(_title_prompt, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func hide_title() -> void:
	if _title_tween != null and _title_tween.is_running():
		_title_tween.kill()
	_title.visible = false


func is_title_visible() -> bool:
	return _title.visible


## Centre the title panel, but in a window too narrow for the panel and the status
## banner to sit side by side, slide the panel right just enough to clear the banner.
func _place_title() -> void:
	if _title == null:
		return
	var viewport_width := get_viewport().get_visible_rect().size.x
	var centred_left := (viewport_width - TITLE_PANEL_WIDTH) * 0.5
	var shift := maxf(0.0, TOP_BANNER_RIGHT + TITLE_BANNER_GAP - centred_left)
	_title.offset_left = shift
	_title.offset_right = shift


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := PanelContainer.new()
	top.name = "Top Banner"
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = TOP_BANNER_SIDE_MARGIN
	top.offset_right = TOP_BANNER_RIGHT
	top.offset_top = TOP_BANNER_TOP_MARGIN
	top.offset_bottom = TOP_BANNER_TOP_MARGIN + TOP_BANNER_HEIGHT
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", _panel_style(16))
	root.add_child(top)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 3)
	top.add_child(top_box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	top_box.add_child(header)
	_progress = _label("TOWER 01 / %02d     STEP 00 / %02d" % [TightropeRules.TOWER_COUNT, TightropeRules.STEPS_PER_TOWER], 11, MUTED)
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_progress)
	for index in TightropeRules.TOWER_COUNT:
		var mark := Panel.new()
		mark.custom_minimum_size = Vector2(12, 3)
		mark.add_theme_stylebox_override("panel", _flat(Color("5b586f"), 2))
		header.add_child(mark)
		_tower_marks.append(mark)
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	top_box.add_child(stage_row)
	_stage = _label("WIND", 25, CREAM)
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_row.add_child(_stage)
	_run_timer = _label("TIME 00:00.0", 16, GOLD)
	_run_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage_row.add_child(_run_timer)
	var balance_row := HBoxContainer.new()
	balance_row.add_theme_constant_override("separation", 8)
	top_box.add_child(balance_row)
	balance_row.add_child(_label("L", 10, MUTED))
	_balance = ProgressBar.new()
	_balance.min_value = 0.0
	_balance.max_value = 100.0
	_balance.value = 50.0
	_balance.show_percentage = false
	_balance.custom_minimum_size = Vector2(0, 9)
	_balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_balance.add_theme_stylebox_override("background", _flat(Color("514b68"), 4))
	_balance.add_theme_stylebox_override("fill", _flat(GOLD, 4))
	balance_row.add_child(_balance)
	balance_row.add_child(_label("R", 10, MUTED))
	_cue = _label("Keep the pole level", 13, MINT)
	_cue.clip_text = true
	top_box.add_child(_cue)
	_step_control = _label("W / O: step left/right", 12, MUTED)
	top_box.add_child(_step_control)
	_lean_control = _label("Q / P: lean left / right", 12, MUTED)
	top_box.add_child(_lean_control)
	_space_control = _label("", 12, MUTED)
	top_box.add_child(_space_control)
	_space_control.hide()

	var gauge_panel := PanelContainer.new()
	gauge_panel.name = "Wire Tension Gauge"
	gauge_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gauge_panel.offset_left = -226.0
	gauge_panel.offset_right = -TOP_BANNER_SIDE_MARGIN
	gauge_panel.offset_top = TOP_BANNER_TOP_MARGIN
	gauge_panel.offset_bottom = 166.0
	gauge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge_panel.add_theme_stylebox_override("panel", _panel_style(8))
	root.add_child(gauge_panel)
	_wire_gauge_panel = gauge_panel
	_wire_gauge = WireGaugeScene.new() as WireTensionGauge
	gauge_panel.add_child(_wire_gauge)
	gauge_panel.hide()

	_countdown_track = Panel.new()
	_countdown_track.name = "Reaction Countdown"
	_countdown_track.size = Vector2(40.0, COUNTDOWN_BAR_HEIGHT)
	_countdown_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var timer_style := StyleBoxFlat.new()
	timer_style.bg_color = PANEL
	timer_style.set_border_width_all(0)
	timer_style.set_corner_radius_all(2)
	_countdown_track.add_theme_stylebox_override("panel", timer_style)
	root.add_child(_countdown_track)
	_countdown_fill = Panel.new()
	_countdown_fill.position = Vector2.ZERO
	_countdown_fill.size = Vector2(40.0, COUNTDOWN_BAR_HEIGHT)
	_countdown_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_fill_style = StyleBoxFlat.new()
	_countdown_fill_style.bg_color = GOLD
	_countdown_fill_style.set_border_width_all(0)
	_countdown_fill_style.set_corner_radius_all(2)
	_countdown_fill.add_theme_stylebox_override("panel", _countdown_fill_style)
	_countdown_track.add_child(_countdown_fill)
	_countdown_track.hide()
	_wire_countdown_track = Panel.new()
	_wire_countdown_track.name = "Wire Reaction Countdown"
	_wire_countdown_track.size = Vector2(40.0, COUNTDOWN_BAR_HEIGHT)
	_wire_countdown_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wire_countdown_track.add_theme_stylebox_override("panel", timer_style.duplicate())
	root.add_child(_wire_countdown_track)
	_wire_countdown_fill = Panel.new()
	_wire_countdown_fill.size = Vector2(40.0, COUNTDOWN_BAR_HEIGHT)
	_wire_countdown_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wire_countdown_fill_style = _countdown_fill_style.duplicate() as StyleBoxFlat
	_wire_countdown_fill.add_theme_stylebox_override("panel", _wire_countdown_fill_style)
	_wire_countdown_track.add_child(_wire_countdown_fill)
	_wire_countdown_track.hide()

	_caption = _label("", 22, CREAM)
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_left = 90.0
	_caption.offset_right = -90.0
	_caption.offset_top = -145.0
	_caption.offset_bottom = -84.0
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.visible = false
	root.add_child(_caption)

	_toast = _label("", 18, GOLD)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = TOP_BANNER_TOP_MARGIN + TOP_BANNER_HEIGHT + 20.0
	_toast.offset_left = -300.0
	_toast.offset_right = 300.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.visible = false
	root.add_child(_toast)

	_title = _build_title()
	root.add_child(_title)

	_scrim = ColorRect.new()
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.color = Color("0b0b19ad")
	_scrim.visible = false
	root.add_child(_scrim)

	_win = PanelContainer.new()
	_win.set_anchors_preset(Control.PRESET_CENTER)
	_win.offset_left = -220.0
	_win.offset_right = 220.0
	_win.offset_top = -155.0
	_win.offset_bottom = 155.0
	_win.add_theme_stylebox_override("panel", _panel_style(24))
	_win.visible = false
	root.add_child(_win)
	var win_box := VBoxContainer.new()
	win_box.add_theme_constant_override("separation", 12)
	_win.add_child(win_box)
	var eyebrow := _label("FOUR TOWERS  /  ONE NIGHT", 12, MINT)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_box.add_child(eyebrow)
	_win_text = _label("", 23, GOLD)
	_win_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_box.add_child(_win_text)
	var replay := _button("PLAY AGAIN")
	win_box.add_child(replay)
	replay.pressed.connect(func() -> void: replay_requested.emit())
	var stargaze := _button("STARGAZE")
	win_box.add_child(stargaze)
	stargaze.pressed.connect(func() -> void: stargaze_requested.emit())

	_paused = PanelContainer.new()
	_paused.set_anchors_preset(Control.PRESET_CENTER)
	_paused.offset_left = -180.0
	_paused.offset_right = 180.0
	_paused.offset_top = -110.0
	_paused.offset_bottom = 110.0
	_paused.add_theme_stylebox_override("panel", _panel_style(22))
	_paused.visible = false
	root.add_child(_paused)
	var pause_box := VBoxContainer.new()
	pause_box.add_theme_constant_override("separation", 12)
	_paused.add_child(pause_box)
	var pause_title := _label("PAUSED", 28, GOLD)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_box.add_child(pause_title)
	var resume := _button("RESUME")
	pause_box.add_child(resume)
	resume.pressed.connect(func() -> void: pause_requested.emit())
	var restart := _button("RESTART")
	pause_box.add_child(restart)
	restart.pressed.connect(func() -> void: replay_requested.emit())
	root.move_child(top, root.get_child_count() - 1)


func _build_title() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Title Screen"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(TITLE_PANEL_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(26))
	panel.visible = false

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var eyebrow := _label("FOUR TOWERS  /  ONE NIGHT", 12, MINT)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _label("TIGHTROPE WALKER", 36, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := _label("Cross the rooftops without falling. Keep the pole level, and answer every interruption before it knocks you off.", 14, CREAM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)
	box.add_child(_title_spacer(6))

	box.add_child(_label("CONTROLS", 11, MUTED))
	var controls := GridContainer.new()
	controls.columns = 2
	controls.add_theme_constant_override("h_separation", 18)
	controls.add_theme_constant_override("v_separation", 4)
	box.add_child(controls)
	_title_row(controls, "W / O", "Step with the left / right foot. Either order works.")
	_title_row(controls, "Q / P", "Lean left / right. Small, early taps keep the pole level.")
	_title_row(controls, "SPACE", "Release wire tension. During a fall, respawn at the last tower.")
	_title_row(controls, "ESC  /  R", "Pause  /  restart the run.")
	box.add_child(_title_spacer(6))

	box.add_child(_label("INTERRUPTIONS", 11, MUTED))
	var tasks := GridContainer.new()
	tasks.columns = 2
	tasks.add_theme_constant_override("h_separation", 18)
	tasks.add_theme_constant_override("v_separation", 4)
	box.add_child(tasks)
	_title_row(tasks, "GUST WARNING", "A flag shows the side the gust comes from. Lean away from the flag within one second.")
	_title_row(tasks, "FLANKER BIRDS", "Three birds fly in. Lean the way the centre bird points and ignore the outer two.")
	_title_row(tasks, "WIRE TENSION", "The gauge climbs with time and steps. Press Space before the needle reaches red.")
	_title_row(tasks, "THREE CROSSINGS", "Each crossing adds an interruption and keeps the earlier ones. The last one runs all three.")
	box.add_child(_title_spacer(8))

	_title_prompt = _label("PRESS SPACE TO START", 16, MINT)
	_title_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title_prompt)
	return panel


func _title_row(grid: GridContainer, key: String, description: String) -> void:
	var key_label := _label(key, 13, GOLD)
	key_label.custom_minimum_size = Vector2(130, 0)
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	grid.add_child(key_label)
	var text := _label(description, 13, CREAM)
	text.custom_minimum_size = Vector2(430, 0)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid.add_child(text)


func _title_spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _label(message: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = message
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color("111124"))
	node.add_theme_constant_override("outline_size", 2)
	return node


func _button(message: String) -> Button:
	var node := Button.new()
	node.text = message
	node.custom_minimum_size = Vector2(100, 48)
	node.add_theme_font_size_override("font_size", 16)
	node.add_theme_color_override("font_color", CREAM)
	node.add_theme_color_override("font_hover_color", PANEL)
	node.add_theme_color_override("font_pressed_color", PANEL)
	node.add_theme_stylebox_override("normal", _flat(Color("37314e"), 8))
	node.add_theme_stylebox_override("hover", _flat(GOLD, 8))
	node.add_theme_stylebox_override("pressed", _flat(CORAL, 8))
	node.add_theme_stylebox_override("focus", _flat(MINT, 8))
	return node


func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _panel_style(padding: int) -> StyleBoxFlat:
	var style := _flat(PANEL, 14)
	style.border_color = Color("81769988")
	style.set_border_width_all(1)
	style.set_content_margin_all(padding)
	style.shadow_color = Color("08081777")
	style.shadow_size = 8
	return style
