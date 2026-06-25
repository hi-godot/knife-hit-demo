# Knife Hit — Godot 4 mechanic

A minimal, self-contained Knife Hit style mechanic in **Godot 4** (GDScript, 2D): knives fly up into a spinning
target, stick into the rim at a **consistent depth every time**, and ride the
rotation.

Open the project and press **Play** — click, tap, or hit **Space** to throw.

![knife hit](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)

## The point of this demo

The usual first attempt uses an `Area2D` overlap (`body_entered` / `area_entered`)
to detect the hit. It "works," but knives stick at a **different depth every
throw** — and faster knives are worse.

**Why:** a manually-moved knife jumps `velocity / 60` pixels per physics frame.
The overlap signal only fires *after* the blade has already pushed past the
surface, and how far past depends on which frame it happened to cross. Bigger
step = bigger overshoot = more variation. (The opposite symptom — "stops before
touching" — is usually just the collision shape being larger than the sprite.)

**The fix** (see [`knife_hit/knife.gd`](knife_hit/knife.gd)): move the knife
manually and use a `RayCast2D` to snap it to the *real* surface point every
frame, instead of wherever it happened to drift to.

Each physics frame:

1. `step = velocity * delta`
2. `ray.target_position = Vector2(step.length() + margin, 0)` — cover one full
   frame of travel **plus a margin**, so a fast knife can't tunnel through the rim
3. `ray.force_raycast_update()`
4. **Hit?** Snap to `ray.get_collision_point()`, push the tip in by a fixed
   `embed_depth`, zero the velocity, stop processing, then reparent under the
   target so it rides the spin. **Miss?** `global_position += step`.

Anchoring to the collision point is what kills the inconsistency. In this demo
every knife ends up at exactly `radius - embed_depth` from the target center,
no matter the speed or which frame it landed on.

## Gotchas this demo handles

- **`RayCast2D` ignores `Area2D` by default.** The target here *is* an `Area2D`,
  so the ray sets `collide_with_areas = true` (and `collide_with_bodies = false`).
- **The ray has its OWN `collision_mask`,** separate from the knife's `Area2D`
  mask. It must include the target's layer (knife on layer 1, target on layer 2,
  ray mask = 2). Fixing only `collide_with_areas` and forgetting the mask is the
  classic "it still doesn't collide."
- **The ray points along the knife's local +X.** `throw()` sets
  `rotation = direction.angle()`, so +X always faces the flight direction.
- **Air-spin is cosmetic only.** Each throw rolls a random `spin_speed`
  (magnitude `spin_speed_min`..`spin_speed_max`, random direction) that rotates
  *only* the `Sprite2D` child — never the `Area2D` body or the ray, or detection
  breaks. On impact it tweens back to flight heading (`wrapf` then `TRANS_BACK` /
  `EASE_OUT`).
- **Want to inspect the ray/shapes?** Turn on **Debug → Visible Collision
  Shapes** in the editor — the knife's `RayCast2D` then draws as a line so you
  can confirm it reaches the target.

## Files

| File | What it is |
|---|---|
| [`knife_hit/knife.tscn`](knife_hit/knife.tscn) / [`knife.gd`](knife_hit/knife.gd) | Reusable knife: `Area2D` + `Sprite2D` + `CollisionShape2D` + `RayCast2D` |
| [`knife_hit/target.gd`](knife_hit/target.gd) | The spinning target disc |
| [`knife_hit/main.tscn`](knife_hit/main.tscn) / [`main.gd`](knife_hit/main.gd) | Minimal test bed; spawns a knife on input |

Exported, tweakable in the Inspector: knife `speed`, `embed_depth`, `ray_margin`,
`spin_speed_min` / `spin_speed_max`; target `spin_speed_min` / `spin_speed_max`,
`radius`. Both the knife (per throw) and the target (per run) randomize spin
magnitude **and** direction within their min/max.

## Requirements

Godot **4.x** (built and tested on 4.6). No addons, no dependencies.

## License

[MIT](LICENSE).
