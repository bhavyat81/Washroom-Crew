## task_manager.gd
## Manages the per-stall task checklist.
##
## One TaskManager node lives inside each stall.
## It auto-discovers Stain, TrashItem, FlushHandle, and SoapDispenser siblings
## by scanning its parent node in _ready, and connects their signals.
##
## Emits "stall_complete" when all tasks for this stall are done.

class_name TaskManager
extends Node

# -------------------------------------------------
# Signals
signal stall_complete(stall_index: int)
signal task_updated(task_id: String, completed: bool)

# -------------------------------------------------
# Stall index (set by LevelManager / scene)
@export var stall_index: int = 0

# Legacy component references (optional — connect via exports in editor)
@export var cleanable_surface: CleanableSurface
@export var foam_system: FoamSystem
@export var tissue_holder: TissueHolder
@export var soap_dispenser: SoapDispenser
@export var trash_bin: TrashBin

# -------------------------------------------------
# Per-stall dynamic task tracking
var total_stains: int = 0
var stains_cleaned: int = 0

var total_trash: int = 0
var trash_picked: int = 0

var toilet_flushed: bool = false
var _has_flush_handle: bool = false

var special_task_done: bool = false
var special_task_required: bool = false
var special_task_label: String = ""

# Discovered soap dispenser (scanned from stall children)
var _scanned_soap: SoapDispenser = null
var soap_task_done: bool = false

# Drain / dirt-blob tracking
var total_dirt_blobs: int = 0
var dirt_blobs_drained: int = 0

# Legacy task completion state
var tasks: Dictionary = {
	"clean_surface": false,
	"foam_applied":  false,
	"tissue":        false,
	"soap":          false,
	"trash":         false,
}

# -------------------------------------------------
func _ready() -> void:
	# Connect legacy component signals (if assigned via exports)
	if cleanable_surface:
		cleanable_surface.surface_clean.connect(_on_surface_clean)
	if foam_system:
		foam_system.foam_complete.connect(_on_foam_complete)
	if tissue_holder:
		tissue_holder.task_completed.connect(_on_tissue_replaced)
	if soap_dispenser:
		soap_dispenser.task_completed.connect(_on_soap_refilled)
	if trash_bin:
		trash_bin.task_completed.connect(_on_trash_changed)

	# Scan parent stall node for dynamic task objects
	call_deferred("_scan_stall")

# -------------------------------------------------
## Scans sibling nodes (children of our parent stall) for task objects.
func _scan_stall() -> void:
	var stall_node := get_parent()
	if stall_node == null:
		return
	_scan_node(stall_node)

func _scan_node(node: Node) -> void:
	for child in node.get_children():
		_connect_stall_object(child)
		# Recurse, but skip other TaskManagers to avoid crossing stall boundaries
		if not child is TaskManager:
			_scan_node(child)

func _connect_stall_object(node: Node) -> void:
	if node is Stain:
		total_stains += 1
		(node as Stain).stain_cleaned.connect(_on_stain_cleaned)
	elif node is TrashItem:
		total_trash += 1
		(node as TrashItem).picked_up.connect(_on_trash_picked)
	elif node is FlushHandle:
		_has_flush_handle = true
		(node as FlushHandle).flushed.connect(_on_toilet_flushed)
	elif node is SoapDispenser and _scanned_soap == null and soap_dispenser == null:
		# Only auto-discover a soap dispenser when none is wired via the export property
		_scanned_soap = node as SoapDispenser
		_scanned_soap.task_completed.connect(_on_soap_task_scanned)
	elif node is DirtBlob:
		total_dirt_blobs += 1
	elif node is FloorDrain:
		(node as FloorDrain).dirt_drained.connect(_on_drain_dirt_drained)

# -------------------------------------------------
## Returns true when every required task for this stall is complete.
func all_tasks_complete() -> bool:
	# Dynamic stain progress
	if total_stains > 0 and stains_cleaned < total_stains:
		return false
	# Dynamic trash progress
	if total_trash > 0 and trash_picked < total_trash:
		return false
	# Flush handle
	if _has_flush_handle and not toilet_flushed:
		return false
	# Scanned soap dispenser
	if _scanned_soap != null and not soap_task_done:
		return false
	# Special task (e.g., plunging)
	if special_task_required and not special_task_done:
		return false
	# Drain dirt task
	if total_dirt_blobs > 0 and dirt_blobs_drained < total_dirt_blobs:
		return false
	# Legacy component tasks
	if cleanable_surface and not tasks["clean_surface"]:
		return false
	if foam_system and not tasks["foam_applied"]:
		return false
	if tissue_holder and not tasks["tissue"]:
		return false
	if soap_dispenser and not tasks["soap"]:
		return false
	if trash_bin and not tasks["trash"]:
		return false
	return true

# -------------------------------------------------
## Returns a summary dictionary for the checklist/HUD to display.
func get_task_summary() -> Dictionary:
	return {
		"stall_index":          stall_index,
		"total_stains":         total_stains,
		"stains_cleaned":       stains_cleaned,
		"total_trash":          total_trash,
		"trash_picked":         trash_picked,
		"toilet_flushed":       toilet_flushed,
		"has_flush_handle":     _has_flush_handle,
		"special_task_required": special_task_required,
		"special_task_done":    special_task_done,
		"special_task_label":   special_task_label,
		"has_soap":             (_scanned_soap != null or soap_dispenser != null),
		"soap_done":            (soap_task_done or tasks.get("soap", false)),
		"total_dirt_blobs":     total_dirt_blobs,
		"dirt_blobs_drained":   dirt_blobs_drained,
	}

# -------------------------------------------------
## Resets all tasks and component states.
func reset() -> void:
	stains_cleaned = 0
	trash_picked = 0
	toilet_flushed = false
	special_task_done = false
	soap_task_done = false
	total_stains = 0
	total_trash = 0
	_has_flush_handle = false
	_scanned_soap = null
	total_dirt_blobs = 0
	dirt_blobs_drained = 0

	for key in tasks:
		tasks[key] = false

	if cleanable_surface:
		cleanable_surface.reset()
	if foam_system:
		foam_system.reset()
	if tissue_holder:
		tissue_holder.reset()
	if soap_dispenser:
		soap_dispenser.reset()
	if trash_bin:
		trash_bin.reset()

# -------------------------------------------------
## Returns a list of pending task identifiers (for debugging / legacy use).
func get_pending_tasks() -> Array[String]:
	var pending: Array[String] = []
	if total_stains > 0 and stains_cleaned < total_stains:
		pending.append("stains_%d_%d" % [stains_cleaned, total_stains])
	if total_trash > 0 and trash_picked < total_trash:
		pending.append("trash_%d_%d" % [trash_picked, total_trash])
	if _has_flush_handle and not toilet_flushed:
		pending.append("toilet_flush")
	if _scanned_soap != null and not soap_task_done:
		pending.append("soap")
	if special_task_required and not special_task_done:
		pending.append("special_task")
	if total_dirt_blobs > 0 and dirt_blobs_drained < total_dirt_blobs:
		pending.append("drain_dirt_%d_%d" % [dirt_blobs_drained, total_dirt_blobs])
	for key in tasks:
		if not tasks[key]:
			pending.append(key)
	return pending

# -------------------------------------------------
# Signal handlers — new dynamic task types

func _on_stain_cleaned(_stain: Stain) -> void:
	stains_cleaned += 1
	var all_done := stains_cleaned >= total_stains
	emit_signal("task_updated", "stains", all_done)
	_check_complete()

func _on_trash_picked(_item: TrashItem) -> void:
	trash_picked += 1
	var all_done := trash_picked >= total_trash
	emit_signal("task_updated", "trash_items", all_done)
	_check_complete()

func _on_toilet_flushed(_handle: FlushHandle) -> void:
	toilet_flushed = true
	emit_signal("task_updated", "toilet_flush", true)
	_check_complete()

func _on_soap_task_scanned(_dispenser: SoapDispenser) -> void:
	soap_task_done = true
	emit_signal("task_updated", "soap", true)
	_check_complete()

# -------------------------------------------------
# Drain / blob signal handlers

func _on_drain_dirt_drained(_blob: DirtBlob) -> void:
	dirt_blobs_drained = min(dirt_blobs_drained + 1, total_dirt_blobs)
	var all_done := dirt_blobs_drained >= total_dirt_blobs
	emit_signal("task_updated", "drain_dirt", all_done)
	_check_complete()

# -------------------------------------------------
# Signal handlers — legacy component types

func _on_surface_clean(_surface: CleanableSurface) -> void:
	_complete_task("clean_surface")

func _on_foam_complete() -> void:
	_complete_task("foam_applied")

func _on_tissue_replaced(_holder: TissueHolder) -> void:
	_complete_task("tissue")

func _on_soap_refilled(_dispenser: SoapDispenser) -> void:
	_complete_task("soap")

func _on_trash_changed(_bin: TrashBin) -> void:
	_complete_task("trash")

# -------------------------------------------------
func _complete_task(task_id: String) -> void:
	if tasks.has(task_id) and not tasks[task_id]:
		tasks[task_id] = true
		emit_signal("task_updated", task_id, true)
		_check_complete()

func _check_complete() -> void:
	if all_tasks_complete():
		emit_signal("stall_complete", stall_index)
