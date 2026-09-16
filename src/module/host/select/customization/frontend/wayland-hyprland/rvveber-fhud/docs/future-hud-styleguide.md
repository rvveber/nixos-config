# FutureHUD style guide

## Principle

> Calm field. Live objects.

FHUD is a working instrument with cinematic confidence. Stable structure makes
it fast to scan. Each object owns its value, state, motion, and response. Depth
and energy reveal meaning.

The order is **task → state → continuity → character**.

## Visual authority

Every visual decision follows one chain:

1. **Stylix leads:** palette, type, opacity, icons, cursor, and wallpaper.
2. **`src/appearance.nix` shapes:** space, geometry, borders, glow, depth, and
   motion tokens.
3. **`Appearance` names:** QML receives semantic roles through the generated
   adapter.
4. **Components express:** UI code consumes those roles.

Task clarity and accessibility bound the chain. `theme.nix` is a Stylix scheme
input. `appearance.nix` stays toolkit-neutral. It and Stylix generate
target-native values for Hyprland and Quickshell; neither reads the other.
Components use semantic `Appearance` roles only, while target names stay inside
the adapter. An adapter names an unsupported role rather than guessing it. A
future portable Stylix geometry role can become an adapter input without
changing components.

## One object, every scale

An object's identity is **label · value · unit · state · freshness**.

| View | Shows |
| --- | --- |
| Overview | One main value, label, unit, state, optional trend |
| Detail | Same label, value, unit, state, and freshness; then cause, history, limits, source, and actions |

Keep units, precision, polarity, and severity stable across views. Reserve value
width. Names describe the sensed quantity; units come from the source. Keep the
last sound value visible while its freshness changes.

## Bar discipline

A bar is compact readouts. Each readout shows one object at a glance. Its
flyout is the object's focal view: it preserves the same identity and owns the
full task. One controller owns focus across the bar. Feedback uses reserved
space, so a state change never moves its neighbours. The bar uses Panels and
Vectors only. Models stay in spatial scenes.

Controls name the result of activation. Readouts name the current state.

The overview stacks a quiet identifier above its primary value. The upper
trailing field carries connection type, acquisition, or an exceptional state;
routine metadata belongs in the flyout. Spacing groups output controls,
connections, and system state. Ten ticks encode the available range (volume
0–150%, brightness and battery 0–100%). A focus contour identifies the active
control; an animated trace identifies ongoing work. Narrow screens wrap groups
into additional rows while preserving text size and control access.

Workspace lanes represent monitor groups. Numbers match the workspace keys;
occupancy ticks show populated slots, the contour marks visible workspaces,
and the moving underline locates keyboard focus. An urgent slot keeps its
warning until the underlying workspace clears it. Activation uses the same
group-switching operation as the keyboard bindings.

## Form has meaning

| Form | Meaning | Use |
| --- | --- | --- |
| **Panel** — rectilinear | Stable work | Readouts, lists, settings, routine flyouts |
| **Vector** — directional 2D callout | Link or direction | Source-linked focus, flow, range, target |
| **Model** — 3D subject with flat labels | Spatial truth | Physical systems, topology, simulation |

Panel is the default. A Vector points to its owner or flow. A bevel or
trapezoid only marks that direction. A Model earns its depth through useful
viewpoint or spatial relation. Text stays screen-aligned.

Pulse is a signal, rather than a surface. It means active acquisition, real
change, or critical urgency. It ends as the state settles. One focal object may
carry spectacle; the surrounding field stays quiet.

## State and motion

Each object exposes two small state axes:

- **Life:** ready → working → done or failed.
- **Health:** normal · caution · critical · stale · unknown.

Color and a word or icon repeat health. Form stays tied to the task. Normal
rests. Caution persists. Critical may interrupt and pulse.

Motion follows **source → transform → settle → return**. The source responds at
once. Overview grows into detail while its label and value persist. Closing
retraces the relationship.

Use **quick · move · scene** for transitions and **orbit** for active work. Values live in
`appearance.nix`. Reduced motion maps travel and pulse to opacity and state.
Interaction stays available through transitions. Loops show active work or
changing data, then stop.

### Shell motion vocabulary

- Segmented gauges expose a bounded range in the object's detail view. The
  center keeps the actual value and unit; the small caption names the range.
- A rotating outer contour means ongoing work. The measured ring stays fixed,
  so acquisition and amount remain distinct. Hidden surfaces suspend rotation.
- Opening content gets one soft opacity dip, then settles within 300 ms. The
  panel outline establishes the boundary first; corner marks resolve toward it.
  Values remain readable and controls respond throughout the entrance.
- Corner marks locate the focused panel or selected result. Stable top-bar
  readouts retain their quiet linear scales.
- Reduced motion presents the settled layout immediately and keeps a static
  work contour. The separate 3D demo remains an exploratory scene.

Application windows share fine focus borders, slight transparency, blur and
directional shadows. Their shader tints neutral dark panels and makes those
backgrounds translucent while retaining text and saturated colors. Long
horizontal and vertical dividers receive an accent contour and a displaced
echo, including low-contrast separators. The echo contracts toward its resting
offset during entry. This is optical depth over application pixels; application
state remains owned by the application. The effect settles without pointer
input or continuous animation.
Fullscreen windows bypass the shader immediately and use full compositor
opacity. Reduced motion starts at the settled appearance.

## Work stays with its object

| Work | Indication |
| --- | --- |
| First data | Final-shape silhouette |
| Refresh | Last value plus freshness |
| Unknown length | Named action plus one contour trace |
| Known length | Fill or arc in the owner, with amount or phase |
| Success | Brief settle and stable result |
| Failure or stall | Fixed state, cause, and next action |

A bar lives in its readout. A scan lives in its panel. An orbit lives on its
model. A global indicator represents global work. A changed value may emit one
short accent tick, then rest.

## Alerts earn focus

An interrupt is important, time-sensitive, and actionable. Its message states
**what changed · impact · next action**. Warning and danger roles keep their
severity meaning. One alert owns the focal layer; the rest remain near their
objects.

## Character

- Dark space carries fine, luminous structure.
- Glow marks focus, energy, or risk.
- One angle family, line scale, space scale, and depth scale unify the shell.
- Rings, grids, ticks, and particles map real range, topology, work, or flow.
- Short tags may use capitals. Prose uses mixed case. Telemetry uses mono type.
- Contrast, focus, keyboard flow, and reduced motion remain clear in every mode.

The Stark quality comes from terse data, spatial models, and decisive response.
Operational calm makes it believable.

## Development gate

Services own truth. Shared components own expression. Prefer common primitives
for `Readout`, `Activity`, `Panel`, `VectorCallout`, and `SpatialModel`.

Before merging a view, check:

- Overview and detail preserve one object identity.
- Advanced form carries a spatial or state reason.
- Motion reveals cause, work, or urgency.
- Loading stays attached to its owner.
- Meaning survives a still, grayscale frame.
- Keyboard focus and reduced motion preserve the full task.
- Visual values flow through `Appearance`.
- Shared geometry serves both Hyprland decoration and shell surfaces.

## Research basis

- [NASA's display standard](https://www.nasa.gov/reference/appendix-f-vol-2/)
  grounds consistency, stable fields, units, freshness, and command feedback.
- The [FAA multifunction display guide](https://www.faa.gov/sites/faa.gov/files/data_research/research/med_humanfacs/oamtechreports/0117.pdf)
  supports sparse information, color economy, grouping, and redundant codes.
- [Android Automotive heads-up guidance](https://developer.android.com/training/cars/platforms/automotive-os/notifications)
  reserves interruption for critical, timely, actionable events.
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/) supports contrast, focus, motion
  control, and safe flashing.
- [Territory Studio's Stark interfaces](https://territorystudio.com/project/marvels-avengers-age-of-ultron/)
  show cinematic form grounded in engineering, robotics, AI, and avionics.
