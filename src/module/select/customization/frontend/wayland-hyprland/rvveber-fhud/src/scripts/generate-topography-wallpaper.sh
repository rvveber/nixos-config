#!/usr/bin/env bash
set -euo pipefail

# ---------- final output ----------
OUTPUT_WIDTH=${OUTPUT_WIDTH}
OUTPUT_HEIGHT=${OUTPUT_HEIGHT}

# ---------- work grid (controls contour smoothness) ----------
WORK_BASE_RESOLUTION=${WORK_BASE_RESOLUTION}

# ---------- contour look ----------
CONTOUR_LEVEL_COUNT=${CONTOUR_LEVEL_COUNT}
OUTER_LINE_DARK_FRACTION=${OUTER_LINE_DARK_FRACTION}
BASE_STROKE_WIDTH_PX=${BASE_STROKE_WIDTH_PX}
TOP_THICK_LEVEL_COUNT=${TOP_THICK_LEVEL_COUNT}
TOP_THICK_STROKE_FACTOR=${TOP_THICK_STROKE_FACTOR}
OUTER_DARK_LINE_OPACITY=${OUTER_DARK_LINE_OPACITY}
INNER_LIGHT_LINE_OPACITY=${INNER_LIGHT_LINE_OPACITY}

# dashed levels
DASH_EVERY_NTH_LEVEL=${DASH_EVERY_NTH_LEVEL}
DASH_PATTERN_PX=${DASH_PATTERN_PX}
DASH_OFFSET_PX=${DASH_OFFSET_PX}

# ---------- symbols ----------
SYMBOL_EVERY_NTH_LEVEL=${SYMBOL_EVERY_NTH_LEVEL}
SYMBOL_SHAPE=${SYMBOL_SHAPE}                 # plus | x | hollow-triangle | pipe | hollow-square | hollow-circle
SYMBOL_SIZE_PX=${SYMBOL_SIZE_PX}
SYMBOL_STROKE_PX=${SYMBOL_STROKE_PX}
SYMBOL_SPACING_PX=${SYMBOL_SPACING_PX}
SYMBOL_OPACITY=${SYMBOL_OPACITY}
SYMBOL_KEEP_BASE_LINE=${SYMBOL_KEEP_BASE_LINE}
SYMBOL_ROTATE_WITH_PATH=${SYMBOL_ROTATE_WITH_PATH}

# ---------- gradient vignette (4 side overlays) ----------
VIGNETTE_INSET_X_PX=${VIGNETTE_INSET_X_PX}
VIGNETTE_INSET_Y_PX=${VIGNETTE_INSET_Y_PX}
VIGNETTE_COLOR=${VIGNETTE_COLOR}
VIGNETTE_OPACITY=${VIGNETTE_OPACITY}
VIGNETTE_EXPONENT=${VIGNETTE_EXPONENT}

# ---------- terrain ----------
LARGE_BLOB_GRID_X=${LARGE_BLOB_GRID_X}
LARGE_BLOB_GRID_Y=${LARGE_BLOB_GRID_Y}
SMALL_BLOB_GRID_X=${SMALL_BLOB_GRID_X}
SMALL_BLOB_GRID_Y=${SMALL_BLOB_GRID_Y}
LARGE_BLOB_STRENGTH=${LARGE_BLOB_STRENGTH}
SMALL_BLOB_STRENGTH=${SMALL_BLOB_STRENGTH}
BLOB_POSITION_JITTER=${BLOB_POSITION_JITTER}
BLOB_MARGIN_FRACTION=$BLOB_MARGIN_FRACTION

PY=$PY
RSVG=$RSVG
VIPS=$VIPS

AA_SUPERSAMPLE=$AA_SUPERSAMPLE

BACKGROUND=$BACKGROUND
FOREGROUND=$FOREGROUND

# Create temporary SVG file
svg=$(mktemp --suffix=.svg)

"$PY" - <<'PY' > "$svg"
import os, math
import numpy as np
import contourpy as cpy

# ----- env / sizes
OW=int(os.environ["OUTPUT_WIDTH"]);  OH=int(os.environ["OUTPUT_HEIGHT"])
WBR=int(os.environ["WORK_BASE_RESOLUTION"])
W=WBR
H=(WBR * OH + OW//2) // OW

LEVELS=int(os.environ["CONTOUR_LEVEL_COUNT"])
OUTER_FRAC=int(os.environ["OUTER_LINE_DARK_FRACTION"])
BASE_STROKE=float(os.environ["BASE_STROKE_WIDTH_PX"])
TOP_N=int(os.environ["TOP_THICK_LEVEL_COUNT"])
TOP_FACTOR=float(os.environ["TOP_THICK_STROKE_FACTOR"])
OUTER_ALPHA=float(os.environ["OUTER_DARK_LINE_OPACITY"])
INNER_ALPHA=float(os.environ["INNER_LIGHT_LINE_OPACITY"])

DASH_EVERY=int(os.environ["DASH_EVERY_NTH_LEVEL"])
DASH_PATTERN=os.environ["DASH_PATTERN_PX"]
DASH_OFFSET=float(os.environ["DASH_OFFSET_PX"])

SYM_EVERY=int(os.environ["SYMBOL_EVERY_NTH_LEVEL"])
SYM_SHAPE=os.environ["SYMBOL_SHAPE"].strip().lower()
SYM_SIZE=float(os.environ["SYMBOL_SIZE_PX"])
SYM_STROKE=float(os.environ["SYMBOL_STROKE_PX"])
SYM_STEP=float(os.environ["SYMBOL_SPACING_PX"])
SYM_OPA=float(os.environ["SYMBOL_OPACITY"])
SYM_KEEP=os.environ["SYMBOL_KEEP_BASE_LINE"].lower()=="true"
SYM_ROTATE = os.environ["SYMBOL_ROTATE_WITH_PATH"].lower() == "true"

BG=os.environ["BACKGROUND"]; FG=os.environ["FOREGROUND"]

GX_L=int(os.environ["LARGE_BLOB_GRID_X"]); GY_L=int(os.environ["LARGE_BLOB_GRID_Y"])
GX_S=int(os.environ["SMALL_BLOB_GRID_X"]); GY_S=int(os.environ["SMALL_BLOB_GRID_Y"])
AMP_L=float(os.environ["LARGE_BLOB_STRENGTH"]); AMP_S=float(os.environ["SMALL_BLOB_STRENGTH"])
JITTER=float(os.environ["BLOB_POSITION_JITTER"])
MARGIN=float(os.environ["BLOB_MARGIN_FRACTION"])

INSET_X=float(os.environ["VIGNETTE_INSET_X_PX"])
INSET_Y=float(os.environ["VIGNETTE_INSET_Y_PX"])
VIGN=os.environ["VIGNETTE_COLOR"]
VOP=float(os.environ["VIGNETTE_OPACITY"])
VEXP=float(os.environ["VIGNETTE_EXPONENT"])

AA_SUPERSAMPLE=int(os.environ["AA_SUPERSAMPLE"])

rng=np.random.default_rng(None)

# half-pixel snapping for better anti-aliasing
SNAP = True

def fmt_xy(px, py):
    if SNAP:
        px = round(px * 2.0) / 2.0
        py = round(py * 2.0) / 2.0
    return f"{px:.2f},{py:.2f}"

# ----- height field
x=np.linspace(0,1,W); y=np.linspace(0,1,H)
X,Y=np.meshgrid(x,y, indexing="xy")
Z=np.zeros((H,W), dtype=np.float64)

def add_oct(nx,ny,amp,sigma_scale):
    if nx<=0 or ny<=0 or amp==0: return
    base_sigma=sigma_scale/min(nx,ny)
    for j in range(ny):
        for i in range(nx):
            cx=(i+0.5)/nx + rng.uniform(-JITTER,JITTER)/nx
            cy=(j+0.5)/ny + rng.uniform(-JITTER,JITTER)/ny
            cx=np.clip(cx,MARGIN,1.0-MARGIN); cy=np.clip(cy,MARGIN,1.0-MARGIN)
            sx=base_sigma*(0.90+0.25*rng.random()); sy=base_sigma*(0.90+0.25*rng.random())
            Z[:] += amp*np.exp(-(((X-cx)**2)/(2*sx*sx) + ((Y-cy)**2)/(2*sy*sy)))

add_oct(GX_L,GY_L, AMP_L, 0.55)
add_oct(GX_S,GY_S, AMP_S, 0.30)

Z -= Z.min(); Z /= float(np.ptp(Z)) or 1.0

qs=np.linspace(0.15,0.90,LEVELS); levels=np.quantile(Z, qs)
n_dark=int(math.ceil(LEVELS*OUTER_FRAC/100.0))
top_idxs=set(range(max(0,LEVELS-TOP_N), LEVELS))

cont=cpy.contour_generator(x=x,y=y,z=Z,name="serial")

def paths_at(t):
    out=[]; polys=[]
    for seg in cont.lines(float(t)):
        if len(seg)<2: continue
        seg[:,0]*=OW; seg[:,1]*=OH
        coords=" L ".join(fmt_xy(px,py) for px,py in seg)
        out.append(f"M {coords}")
        polys.append(seg.copy())
    return out, polys

# robust marker resampler (half-step, incremental, sentinels)
def resample_polyline_for_markers(P, step):
    if len(P) < 2 or step <= 0: return None
    EPS = 1e-6
    closed = np.linalg.norm(P[0] - P[-1]) < 0.5
    Q = np.vstack([P, P[1]]) if closed else P
    seg = Q[1:] - Q[:-1]
    d = np.sqrt((seg**2).sum(axis=1))
    s = np.concatenate([[0.0], np.cumsum(d)])
    total = float(s[-1])
    if total <= EPS: return None
    half = step * 0.5
    targets = []
    if closed:
        t = half % total
        start_t = t
        for _ in range(int(total/step)+3):
            targets.append(t)
            t += step
            if t >= total - EPS: t -= total
            if abs(t - start_t) < step*0.25: break
        s0 = (targets[0] - half) % total
        s1 = (targets[-1] + half) % total
    else:
        start = half
        end   = max(0.0, total - half)
        if end <= start + EPS: return None
        t = start
        while t <= end + EPS:
            targets.append(t); t += step
        s0 = max(0.0, targets[0] - half)
        s1 = min(total, targets[-1] + half)
    def interp_at(pos):
        return np.array([np.interp(pos, s, Q[:,0]),
                         np.interp(pos, s, Q[:,1])])
    samples = [interp_at(s0)] + [interp_at(t) for t in targets] + [interp_at(s1)]
    if len(samples) < 3: return None
    coords = " L ".join(fmt_xy(pt[0], pt[1]) for pt in samples)
    return f"M {coords}"

dark_solid, dark_dash, dark_sym = [], [], []
light_solid, light_dash, light_sym = [], [], []
top_thick = []

for idx,t in enumerate(levels):
    path_strings, poly_arrays = paths_at(t)
    is_dash = (DASH_EVERY>0 and ((idx+1)%DASH_EVERY==0))
    is_sym  = (SYM_EVERY>0  and ((idx+1)%SYM_EVERY==0))

    if is_sym:
        sym_paths = [resample_polyline_for_markers(P, SYM_STEP) for P in poly_arrays]
        sym_paths = [p for p in sym_paths if p and p.strip()]
        if idx < n_dark: dark_sym.extend(sym_paths)
        else:            light_sym.extend(sym_paths)
        if SYM_KEEP and not is_dash:
            (dark_solid if idx<n_dark else light_solid).extend(path_strings)
    elif is_dash:
        (dark_dash if idx<n_dark else light_dash).extend(path_strings)
    else:
        (dark_solid if idx<n_dark else light_solid).extend(path_strings)
        if idx in top_idxs:
            top_thick.extend(path_strings)

def pack(ps): return "".join(f'<path d="{d}"/>' for d in ps if d and d.strip())

# helper that emits paths with marker-mid directly on each element
def pack_with_marker(ps, marker_id="sym"):
    return "".join(
        f'<path d="{d}" fill="none" stroke="black" stroke-opacity="0" marker-mid="url(#{marker_id})"/>'
        for d in ps if d and d.strip()
    )

# marker (userSpaceOnUse)
orient_attr = 'auto' if SYM_ROTATE else '0'
h = float(SYM_SIZE)/2.0
root3_2 = 0.8660254037844386

if SYM_SHAPE == "x":
    marker_g = (f'<g stroke="{FG}" stroke-width="{SYM_STROKE}" stroke-linecap="square" opacity="{SYM_OPA}">'
                f'<line x1="{-h}" y1="{-h}" x2="{h}" y2="{h}"/>'
                f'<line x1="{-h}" y1="{h}"  x2="{h}" y2="{-h}"/></g>')
elif SYM_SHAPE == "hollow-triangle":
    p1 = (0, -h); p2 = ( h, h*root3_2); p3 = (-h, h*root3_2)
    marker_g = (f'<g stroke="{FG}" stroke-width="{SYM_STROKE}" fill="none" opacity="{SYM_OPA}">'
                f'<polyline points="{p1[0]},{p1[1]} {p2[0]},{p2[1]} {p3[0]},{p3[1]} {p1[0]},{p1[1]}"/></g>')
elif SYM_SHAPE == "pipe":
    marker_g = (f'<g stroke="{FG}" stroke-width="{SYM_STROKE}" stroke-linecap="square" opacity="{SYM_OPA}">'
                f'<line x1="0" y1="{-h}" x2="0" y2="{h}"/></g>')
elif SYM_SHAPE == "hollow-square":
    marker_g = (f'<g stroke="{FG}" stroke-width="{SYM_STROKE}" fill="none" opacity="{SYM_OPA}">'
                f'<rect x="{-h}" y="{-h}" width="{SYM_SIZE}" height="{SYM_SIZE}"/></g>')
elif SYM_SHAPE == "hollow-circle":
    marker_g = (f'<g stroke="{FG}" stroke-width="{SYM_STROKE}" fill="none" opacity="{SYM_OPA}">'
                f'<circle cx="0" cy="0" r="{h}"/></g>')
else:  # plus
    marker_g = (f'<g stroke="{FG}" stroke-width="{SYM_STROKE}" stroke-linecap="square" opacity="{SYM_OPA}">'
                f'<line x1="{-h}" y1="0" x2="{h}" y2="0"/>'
                f'<line x1="0" y1="{-h}" x2="0" y2="{h}"/></g>')

marker_def = (f'<marker id="sym" markerUnits="userSpaceOnUse" orient="{orient_attr}" '
              f'overflow="visible" refX="0" refY="0" markerWidth="{SYM_SIZE}" markerHeight="{SYM_SIZE}">'
              f'{marker_g}</marker>')

# vignette gradients
def stop_opacity(t, vop, exp_):
    t = max(0.0, min(1.0, t))
    return vop * (t ** exp_)
op0 = 0.0
op1 = stop_opacity(0.60, VOP, VEXP)
op2 = stop_opacity(0.85, VOP, VEXP)
op3 = VOP

grad_defs = f"""
  <linearGradient id="vigLeft" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%"   stop-color="{VIGN}" stop-opacity="{op3:.4f}"/>
    <stop offset="60%"  stop-color="{VIGN}" stop-opacity="{op1:.4f}"/>
    <stop offset="85%"  stop-color="{VIGN}" stop-opacity="{op2:.4f}"/>
    <stop offset="100%" stop-color="{VIGN}" stop-opacity="{op0:.4f}"/>
  </linearGradient>
  <linearGradient id="vigRight" x1="100%" y1="0%" x2="0%" y2="0%">
    <stop offset="0%"   stop-color="{VIGN}" stop-opacity="{op3:.4f}"/>
    <stop offset="60%"  stop-color="{VIGN}" stop-opacity="{op1:.4f}"/>
    <stop offset="85%"  stop-color="{VIGN}" stop-opacity="{op2:.4f}"/>
    <stop offset="100%" stop-color="{VIGN}" stop-opacity="{op0:.4f}"/>
  </linearGradient>
  <linearGradient id="vigTop" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%"   stop-color="{VIGN}" stop-opacity="{op3:.4f}"/>
    <stop offset="60%"  stop-color="{VIGN}" stop-opacity="{op1:.4f}"/>
    <stop offset="85%"  stop-color="{VIGN}" stop-opacity="{op2:.4f}"/>
    <stop offset="100%" stop-color="{VIGN}" stop-opacity="{op0:.4f}"/>
  </linearGradient>
  <linearGradient id="vigBottom" x1="0%" y1="100%" x2="0%" y2="0%">
    <stop offset="0%"   stop-color="{VIGN}" stop-opacity="{op3:.4f}"/>
    <stop offset="60%"  stop-color="{VIGN}" stop-opacity="{op1:.4f}"/>
    <stop offset="85%"  stop-color="{VIGN}" stop-opacity="{op2:.4f}"/>
    <stop offset="100%" stop-color="{VIGN}" stop-opacity="{op0:.4f}"/>
  </linearGradient>
"""

left_rect   = f'<rect x="0" y="0" width="{INSET_X:.4f}" height="{OH}" fill="url(#vigLeft)"/>'   if INSET_X > 0 else ""
right_rect  = f'<rect x="{OW-INSET_X:.4f}" y="0" width="{INSET_X:.4f}" height="{OH}" fill="url(#vigRight)"/>' if INSET_X > 0 else ""
top_rect    = f'<rect x="0" y="0" width="{OW}" height="{INSET_Y:.4f}" fill="url(#vigTop)"/>'    if INSET_Y > 0 else ""
bottom_rect = f'<rect x="0" y="{OH-INSET_Y:.4f}" width="{OW}" height="{INSET_Y:.4f}" fill="url(#vigBottom)"/>' if INSET_Y > 0 else ""

# symbols: direct marker-mid on each path (so orient=auto rotates with tangent)
dark_sym_svg  = pack_with_marker(dark_sym)
light_sym_svg = pack_with_marker(light_sym)

# ----- SVG
print(f"""
<svg xmlns="http://www.w3.org/2000/svg" width="{OW}" height="{OH}" viewBox="0 0 {OW} {OH}">
  <defs>
    {marker_def}
    {grad_defs}
  </defs>

  <rect width="100%" height="100%" fill="{BG}"/>

  <!-- light inner solids -->
  <g fill="none" stroke-linecap="round" stroke-linejoin="round"
     stroke="{FG}" stroke-width="{BASE_STROKE}" stroke-opacity="{INNER_ALPHA}" shape-rendering="geometricPrecision">
    {pack(light_solid)}
  </g>

  <!-- dark outer solids -->
  <g fill="none" stroke-linecap="round" stroke-linejoin="round"
     stroke="{FG}" stroke-width="{BASE_STROKE}" stroke-opacity="{OUTER_ALPHA}" shape-rendering="geometricPrecision">
    {pack(dark_solid)}
  </g>

  <!-- dashed -->
  <g fill="none" stroke-linecap="round" stroke-linejoin="round"
     stroke="{FG}" stroke-width="{BASE_STROKE}" stroke-opacity="{INNER_ALPHA}"
     stroke-dasharray="{DASH_PATTERN}" stroke-dashoffset="{DASH_OFFSET}" shape-rendering="geometricPrecision">
    {pack(light_dash)}
  </g>
  <g fill="none" stroke-linecap="round" stroke-linejoin="round"
     stroke="{FG}" stroke-width="{BASE_STROKE}" stroke-opacity="{OUTER_ALPHA}"
     stroke-dasharray="{DASH_PATTERN}" stroke-dashoffset="{DASH_OFFSET}" shape-rendering="geometricPrecision">
    {pack(dark_dash)}
  </g>

  <!-- thicker top-N (inner tone) -->
  <g fill="none" stroke-linecap="round" stroke-linejoin="round"
     stroke="{FG}" stroke-width="{BASE_STROKE*TOP_FACTOR}" stroke-opacity="{INNER_ALPHA}" shape-rendering="geometricPrecision">
    {pack(top_thick)}
  </g>

  <!-- symbols -->
  {dark_sym_svg}
  {light_sym_svg}

  <!-- vignette overlays -->
  {left_rect}{right_rect}{top_rect}{bottom_rect}
</svg>
""")
PY

# rasterize
if [ "$AA_SUPERSAMPLE" -gt 1 ]; then
  supersample_width=$(( OUTPUT_WIDTH * AA_SUPERSAMPLE ))
  supersample_height=$(( OUTPUT_HEIGHT * AA_SUPERSAMPLE ))

  # render big
  big_png="$(mktemp --suffix=.png)"
  "$RSVG" -w "$supersample_width" -h "$supersample_height" "$svg" -o "$big_png"

  # compute 1/AA as float
  scale="$(python3 - <<PY
print(1.0/float(${AA_SUPERSAMPLE}))
PY
)"

  # downscale with a good kernel (lanczos3 if available, else lanczos)
  if "$VIPS" resize "$big_png" "$out" "$scale" --kernel lanczos3 2>/dev/null; then
    :
  else
    "$VIPS" resize "$big_png" "$out" "$scale" --kernel lanczos
  fi

  rm -f "$big_png"
else
  "$RSVG" -w "$OUTPUT_WIDTH" -h "$OUTPUT_HEIGHT" "$svg" -o "$out"
fi

# Clean up temporary SVG file
rm "$svg"
