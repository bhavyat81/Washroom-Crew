# 🧹 Washroom Crew

A **first-person 3D restroom cleaning game** built with **Godot 4.x**.

> **Theme:** Professional facility hygiene — airport restroom crew, stadium event cleanup, mall maintenance.
> **Core Loop:** Hit the cleanliness KPI before the next rush of visitors arrives!

---

## 🎮 Game Concept

You are a professional facility hygiene technician. Race against the clock to clean restrooms to inspection standards before the next wave of visitors arrives. Spray, foam, restock — and get out.

**NOT a gross-out game.** Think pressure-washer-satisfying meets time-management strategy.

### Venues
| Venue | Challenge |
|-------|-----------|
| ✈️ Airport Terminal | Gate opens in 3 minutes — keep traveller restrooms spotless |
| 🏟️ Stadium Event Cleanup | Half-time: clean the block before 80,000 fans return |
| 🛍️ Mall Maintenance | Non-stop Saturday shoppers — zero tolerance for mess |

---

## 🕹️ MVP Gameplay (Vertical Slice)

1. **One restroom room** with **3 toilet stalls** in a row
2. **First-person controller** — player holds a jet spray tool
3. **Each stall has a full task list:**
   - Clean dirt to ≤ 5% (spray away grime)
   - Apply foam/disinfectant (timed hold)
   - Replace tissue roll (press E near holder)
   - Refill soap dispenser (press E)
   - Change trash bag (press E)
4. **LevelManager** unlocks one stall at a time
5. **Final inspection score** — star rating based on time and accuracy

---

## 🚀 How to Run

### Requirements
- **Godot 4.3+** — [Download here](https://godotengine.org/download)

### Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/bhavyat81/Washroom-Crew.git
   ```
2. Open **Godot 4.3+**
3. Click **Import** and select the `project.godot` file from this repo
4. Press **F5** (or click the Play button) to run the game

### Controls
| Action | Key / Button |
|--------|-------------|
| Move | W A S D |
| Sprint | Left Shift (hold) |
| Look | Mouse |
| Jump | Space |
| **Spray** (clean dirt) | Left Mouse Button |
| **Foam** (disinfect, hold) | Right Mouse Button |
| **Interact** (tissue/soap/trash) | E |
| Pause / Release cursor | Escape |

---

## 📁 Project Structure

```
project.godot               ← Godot 4.x project config (input maps, settings)
.gitignore                  ← Godot-specific ignores

scenes/
  main_menu/
    main_menu.tscn          ← Title screen with Play / Settings / Quit
    main_menu.gd
  game/
    game_level.tscn         ← Main game scene (room + 3 stalls + player + UI)
    game_level.gd
  ui/
    hud.tscn                ← Timer, dirt bar, foam bar, crosshair, prompt
    hud.gd
    checklist.tscn          ← Per-stall task checklist overlay
    checklist.gd
    level_complete.tscn     ← Results screen (stars, score, next/menu)
    level_complete.gd

scripts/
  player/
    player_controller.gd   ← First-person CharacterBody3D (WASD + mouse look)
    interact_ray.gd        ← Raycast interaction (detects interactable objects)
    spray_tool.gd          ← Jet spray + foam application logic
  cleaning/
    cleanable_surface.gd   ← Dirt value (0–1), shader update, clean signal
    foam_system.gd         ← Timed foam/disinfectant step with progress
  interactables/
    interactable_base.gd   ← Base class: get_interact_prompt(), interact()
    tissue_holder.gd       ← Press E to replace tissue roll
    soap_dispenser.gd      ← Press E to refill soap
    trash_bin.gd           ← Press E to change trash bag
  level/
    level_manager.gd       ← Stall progression, rush timer, score calculation
    task_manager.gd        ← Per-stall task tracking and completion signals
    random_events.gd       ← Framework: clog / spill / vandalism incidents
  progression/
    tool_data.gd           ← Tool upgrade resource (spray power, range, etc.)
    venue_data.gd          ← Venue/level pack data (unlock, IAP hooks)
    cosmetics_data.gd      ← Cosmetic items (skins, themes)

resources/
  tools/
    basic_spray.tres        ← Starter tool (unlocked)
    improved_nozzle.tres    ← Tier 1 upgrade
    foam_cannon.tres        ← Tier 2 upgrade
    uv_detector_pro.tres    ← Tier 3 (Pro) upgrade
  venues/
    airport.tres            ← Airport pack (starter, unlocked)
    stadium.tres            ← Stadium pack (unlock after 9 ⭐)
    mall.tres               ← Mall pack (IAP)
  cosmetics/
    gloves_default.tres     ← Default gloves (free)
    spraygun_neon.tres      ← Neon spray gun skin (soft currency)
    theme_marble.tres       ← Luxury marble room theme (premium IAP)

assets/
  materials/
    dirty_material.tres     ← Standard brownish-grey dirty material
    clean_material.tres     ← Bright clean tile material
  shaders/
    dirt_clean_surface.gdshader  ← Shader: lerps clean↔dirty via dirt_amount
  models/                   ← Placeholder — add 3D models here
  textures/                 ← Placeholder — add textures here
  sounds/                   ← Placeholder — add SFX/music here
```

---

## ⚙️ Core Systems

### 🧴 Cleaning System
- `CleanableSurface` tracks `dirt_value` (0.0 = clean, 1.0 = filthy)
- `SprayTool` fires a RayCast3D and calls `apply_spray(amount)` each frame
- The surface drives a shader uniform `dirt_amount` for visual feedback
- When `dirt_value ≤ 0.05` → `surface_clean` signal → task ticked off

### 🫧 Foam System
- After spraying, hold **Right Click** to apply foam
- `FoamSystem.apply_foam(delta)` fills `foam_progress` over `foam_duration` seconds
- Requires surface to be mostly clean first (`requires_pre_clean = true`)

### ✅ Task / Checklist System
- `TaskManager` per stall connects to all component signals
- Tracks: `clean_surface`, `foam_applied`, `tissue`, `soap`, `trash`
- Emits `stall_complete` when all tasks done → LevelManager advances

### ⏱️ Level Manager
- 180-second countdown (configurable)
- Unlocks stalls one at a time as each is completed
- Calculates star rating (1–3⭐) based on time remaining
- Triggers level-complete screen with score breakdown

### 🎲 Random Events (Framework)
- `RandomEvents` node can fire: `clog`, `spill`, `vandalism`
- Connect `event_triggered` signal to your gameplay responses
- Enable `auto_trigger = true` for automatic mid-level incidents

---

## 💰 Monetization Structure

All monetization is **data-only** at this stage (no store integration yet).

| Type | Implementation |
|------|---------------|
| Cosmetic skins | `CosmeticsData` resource (`is_premium`, `unlock_cost`) |
| Venue packs | `VenueData` resource (`is_iap`, `iap_product_id`) |
| Rewarded ads | `rewarded_ad_available` flag on VenueData / hooks in LevelManager |
| Soft currency | `unlock_cost` field on tools and cosmetics |

> Rewarded ad hooks: "skip drying time", "instant supplies refill" — **not pay-to-win**.

---

## 🗺️ Progression Roadmap

```
Tier 1: Airport Terminal (10 levels) — Starter
   ↓ 9 ⭐
Tier 2: Stadium Event Cleanup (10 levels)
   ↓ 18 ⭐
Tier 3: Mall Maintenance (10 levels) — IAP pack
   ↓
Tier 4: Concert Festival Portables (coming soon)
```

**Tool Progression:**
Basic Spray → Improved Nozzle → Foam Cannon → UV Stain Detector Pro

---

## 🛠️ Technical Notes

- **Engine:** Godot 4.3+, GDScript
- **Camera:** First-person (`CharacterBody3D` + `Camera3D`)
- **Geometry:** CSG primitives for MVP (swap in proper meshes later)
- **Dirty→Clean visual:** `dirt_clean_surface.gdshader` with `dirt_amount` uniform
- **Platform target:** Mobile-first (keyboard/mouse for desktop dev; touch coming later)
- **Architecture:** Component-based — `CleanableSurface`, `FoamSystem`, and interactables are independent nodes

---

## 📝 License

This project is private / proprietary. All rights reserved.
