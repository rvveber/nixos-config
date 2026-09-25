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
horizontal and vertical dividers receive an accent contour and a fixed diagonal
echo after a continuous 33-pixel run passes contrast and coherence checks.
Entry changes the highlight intensity while the depth offset stays fixed.
This is optical depth over application pixels; application state remains owned
by the application. The effect settles without pointer input or continuous animation.

Super+F10 toggles the effect on the focused window. Super+Shift+F10 toggles
rectangle debugging on that window. Debug mode shows the original content with
translucent boxes and matching outlines. Confirmed circular corners also show
warm-colored circles and center marks; each corner has its own fitted radius.
Similar parallel segments anchor narrow
search regions at their ends. Within those regions, short coherent perpendicular
segments can establish a connecting side when both ends fit the predicted corner
regions. Outward extension determines the allowance for rounding; inward cuts
require evidence near both junctions. A side continuing past an inferred corner
must meet its anchor or connect through a visible corner contour. This keeps
detached row highlights from borrowing panel borders while allowing rounded
controls beside scrollbars. Corner confidence measures the complete turn and its
straight continuation. Once a side has sufficient contrast, its supported length
determines coverage. The more confident side is reflected through the shared
midpoint of the parallel anchors; observed sides near that prediction receive a
bounded ranking bonus. Midpoint disagreement widens the tolerance. This favors
symmetric bounds while allowing uneven visible segments; reflection alone never
creates an edge. Independently detected orthogonal segments contribute reciprocal
endpoint agreement: less extension into the proposed corners gives stronger
support. This also strengthens the three-sided reference used to rank the fourth
side. Outward proximity breaks otherwise equal rankings.
The intersections give implicit corners across rounded or missing corner pixels.
Coherent sections remain separate candidates when a line spans a gap. Matching
gaps in both opposite anchors reject a combined surface, keeping adjacent controls
separate after reduction while retaining a boundary interrupted on one side.
The same search runs from horizontal and vertical anchor pairs. Long anchors and
connectors require sustained continuity; thin strokes also need a stable profile.
A one-pixel band follows antialiased edges, with direct support retaining their
position. Sustained direct support fixes the endpoints, keeping isolated fragments
and neighboring shadow pixels from extending anchors;
opposite transitions of a thin rim remain separate. Faint edges qualify through
longer coherent runs. Within predicted side regions,
a one-level color difference can complete a long, nearly uninterrupted connector;
this weaker evidence never seeds anchor lines. A side whose contrast disappears
remains unconfirmed. Corner confidence and mirrored-side agreement rank overlapping
rectangles before supported perimeter, coverage, and area. Nearby confidence values
share a ranking band so small measurement differences yield to complete support.
Text inside a detected box leaves its overlay intact; smaller nested controls
receive their own color. The minimum thickness is six analysis pixels. Short sides
use shorter continuity runs and require confirmed corners. A short parallel edge
can use its section of a shared longer edge when both connecting corners agree.
Duplicate removal preserves independently inset small controls. Established parent
and child bounds reject weaker proposals assembled from their separate edges.

The 45-degree probe seeds a circular radius; four additional directions must
support the same arc and color transition. The exterior portion of the probe must
remain consistent, which keeps interior texture from supplying a false corner.
Each corner is fitted independently, and adjacent radii must fit along their shared
side. Three source pixels is the smallest reported radius. Square, unresolved,
and incompatible noncircular corners retain their rectangle bounds without a
circle. Existing contour continuity remains useful when a circular fit is absent.

Detection runs once per committed main-surface update and reuses its result while
moving the window. Repeated 2x2 reduction preserves thin-line coverage; contrast
thresholds account for its scale. A maximum dimension of 1024 pixels bounds the
coarse readback and detection work; up to 64 boxes are passed to the shader.
Candidate edges and corners then use native texture tiles packed into a second
readback of at most 1024 by 1024 pixels. Supported transitions refine each boundary
within its coarse sampling uncertainty; inset controls retain distinct parent
boundaries. A distributed weak transition can extend the native search up to twelve
pixels inward toward a substantially sharper opposite transition. This recovers a
surface inside its hover shadow. Recovered sides must face opposite ways, and
converging outlines share one result. Complete native bounds also supersede nearby
incomplete duplicates. Circle fits use these refined bounds and native pixels, so reduced
resolution does not multiply their fitting error. A corner needs both adjacent
edges confirmed at native resolution. Exhausted tile budgets retain coarse bounds
and omit unverified circles. Coarse radii guide the native corner search; unresolved
corners initially search up to 32 source pixels. Large image panels are supported
across the window. This remains a visual heuristic: low-contrast
or interrupted borders can be missed, and subsurfaces are outside this debug pass.
The normal shader uses its existing local line tracing without detection or readback.

The plugin expands local window damage by the shader's sampling radius, so
changed controls also redraw their displaced highlights. Screen shader changes
invalidate all monitor damage histories, including buffers awaiting reuse.
The nightshift tuner applies mouse-driven changes on slider release; keyboard
changes are debounced. Off and Quit cancel pending updates.

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
