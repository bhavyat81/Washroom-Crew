## random_events.gd
## Framework for random mid-level incidents (clog, spill, vandalism).
##
## The LevelManager can call trigger_random_event() or this node can fire
## events on a timer automatically.  Each event type is a stub — connect
## the signals to gameplay responses (e.g., spawning a spill mesh, blocking
## a task until the incident is resolved).

class_name RandomEvents
extends Node

# -------------------------------------------------
# Signals — connect these to the rest of the gameplay systems
signal event_triggered(event_type: String, stall_index: int)
signal event_resolved(event_type: String, stall_index: int)

# -------------------------------------------------
@export var auto_trigger: bool = false          # Enable for automatic random events
@export var min_interval: float = 30.0          # Minimum seconds between events
@export var max_interval: float = 60.0          # Maximum seconds between events
@export var event_probability: float = 0.5      # Chance (0..1) that a scheduled roll fires an event

# Registered event types — expand this list as new incidents are added
const EVENT_TYPES: Array[String] = [
	"clog",       # Toilet is clogged — needs unclogging before cleaning continues
	"spill",      # Liquid spill — extra dirt added to floor
	"vandalism",  # Graffiti or breakage — adds a special task
]

# Active events: stall_index → event_type
var _active_events: Dictionary = {}

# Internal timer for auto-triggering
var _next_event_time: float = 0.0

# -------------------------------------------------
func _ready() -> void:
	if auto_trigger:
		_schedule_next_event()

# -------------------------------------------------
func _process(delta: float) -> void:
	if not auto_trigger:
		return

	_next_event_time -= delta
	if _next_event_time <= 0.0:
		_attempt_random_event()
		_schedule_next_event()

# -------------------------------------------------
## Manually trigger a specific event on a stall.
func trigger_event(event_type: String, stall_index: int) -> void:
	if _active_events.has(stall_index):
		return  # Stall already has an active event

	_active_events[stall_index] = event_type
	emit_signal("event_triggered", event_type, stall_index)
	print("RandomEvents: [%s] triggered on stall %d" % [event_type, stall_index])

# -------------------------------------------------
## Mark an event as resolved (called by the gameplay system when fixed).
func resolve_event(stall_index: int) -> void:
	if not _active_events.has(stall_index):
		return

	var event_type: String = _active_events[stall_index]
	_active_events.erase(stall_index)
	emit_signal("event_resolved", event_type, stall_index)

# -------------------------------------------------
## Returns the active event type for a stall, or "" if none.
func get_active_event(stall_index: int) -> String:
	return _active_events.get(stall_index, "")

# -------------------------------------------------
func _attempt_random_event() -> void:
	if randf() > event_probability:
		return  # No event this cycle

	var stall_index := randi_range(0, 2)   # Pick a random stall (0..2 for 3-stall level)
	var event_type: String = EVENT_TYPES[randi_range(0, EVENT_TYPES.size() - 1)]
	trigger_event(event_type, stall_index)

func _schedule_next_event() -> void:
	_next_event_time = randf_range(min_interval, max_interval)
