# -*- coding: utf-8 -*-
"""
Bulak / "Булак" - mobile app icon concept generator.

Renders three 1024x1024 RGB (no alpha) icon concepts plus a contact sheet.
Everything is drawn at 4x supersampling (4096x4096) and downsampled with
Image.LANCZOS, so edges stay clean.

Run (no arguments required):

    "C:\\Users\\Taalaibek\\.dsh\\dsh-runtimes\\dsh-primary-runtime\\dependencies\\python\\python.exe" tools/icon/generate_concepts.py

Outputs:
    assets/icon/concepts/concept_a_drop.png
    assets/icon/concepts/concept_b_spring.png
    assets/icon/concepts/concept_c_play_bubble.png
    assets/icon/concepts/contact_sheet.png
"""

from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --------------------------------------------------------------------------
# Global configuration
# --------------------------------------------------------------------------

SS = 4                      # supersampling factor
OUT = 1024                  # final icon size
N = OUT * SS                # render size (4096)
CX = CY = N / 2.0           # render centre
SQ = 0.950 * N              # squircle side => 2.5% margin on each side
S = SQ / 983.0              # design-space -> render-pixel scale factor
RNG = np.random.default_rng(20240517)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT_DIR = os.path.join(ROOT, "assets", "icon", "concepts")

r2 = lambda v: int(round(v))

# --------------------------------------------------------------------------
# Palette (final HEX codes are documented in the report)
# --------------------------------------------------------------------------

PAL_A = {
    "bg": [(0x6C, 0xE8, 0xFF), (0x2F, 0x8B, 0xFF), (0x46, 0x3A, 0xE8)],
    "name": "concept_a_drop",
}
# explicit, readable palettes (final HEX codes are documented in the report)
A_BG = ("#6CE8FF", "#2F8BFF", "#463AE8")
A_DROP = ("#FFFFFF", "#D6ECFF")
A_PLAY = ("#FFFFFF", "#E8F4FF")
A_SHADOW = "#123A8C"

B_BG = ("#3FC1FF", "#2A6BFF", "#5B4BFF")
B_WAVE = ("#FFFFFF", "#DCEBFF")
B_PLAY = ("#FFFFFF", "#EAF5FF")
B_ACCENT_Y = "#FFD93D"
B_ACCENT_C = "#FF7A59"

C_BG = ("#FF7A59", "#FF4F9A", "#8A3DFF")
C_BUBBLE = ("#FFE066", "#FFC42E")
C_FACE = "#123A8C"
C_TRI = "#1E3FC8"
C_BADGE = ("#FFFFFF", "#F2F6FF")

FACE = "#123A8C"


def hx(s: str):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


# --------------------------------------------------------------------------
# Low level helpers
# --------------------------------------------------------------------------

def smoothstep(x, e0, e1):
    t = np.clip((x - e0) / float(e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def to_rgba(img):
    return img if img.mode == "RGBA" else img.convert("RGBA")


def composite(base, layer):
    """Alpha-composite `layer` over `base` (both RGBA)."""
    return Image.alpha_composite(base, layer)


def fill_mask(mask, color, alpha=1.0):
    """RGBA layer filled with a colour, shaped by a greyscale mask."""
    c = hx(color) if isinstance(color, str) else tuple(color[:3])
    arr = np.zeros((N, N, 4), dtype=np.uint8)
    a = np.asarray(mask, dtype=np.float32)
    arr[..., 0] = c[0]
    arr[..., 1] = c[1]
    arr[..., 2] = c[2]
    arr[..., 3] = np.clip(a * alpha, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def mask_from_draw(draw_fn):
    """Greyscale mask (L, 4096) from a function that draws in white."""
    m = Image.new("L", (N, N), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def soften(mask, radius):
    return mask.filter(ImageFilter.GaussianBlur(radius))


def mask_to_np(mask):
    return np.asarray(mask, dtype=np.float32) / 255.0


def drop_shadow(mask, tint, blur=34.0, strength=0.45, dx=-8.0, dy=-16.0):
    """RGBA shadow layer: mask shifted by (dx, dy) so the dark edge lands on
    the opposite (lower-right) side of the object."""
    m = soften(mask, blur).point(lambda v: int(v * strength))
    layer = fill_mask(m, tint)
    return layer.transform((N, N), Image.AFFINE, (1, 0, dx, 0, 1, dy),
                           resample=Image.BILINEAR)


# --------------------------------------------------------------------------
# Background: linear gradient + squircle mask + rim/vignette + dithering
# --------------------------------------------------------------------------

def gradient_img(stops, p0, p1):
    """Linear gradient along p0 -> p1 built at render resolution.

    Stop positions are fractions (0..1) of the p0..p1 span.
    """
    vx, vy = float(p1[0] - p0[0]), float(p1[1] - p0[1])
    span = math.hypot(vx, vy)
    ux, uy = vx / span, vy / span
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    t = ((xx - p0[0]) * ux + (yy - p0[1]) * uy) / span   # 0 at p0, 1 at p1
    stops = sorted([(float(s[0]), hx(s[1])) for s in stops], key=lambda s: s[0])

    cols = np.zeros((N, N, 3), dtype=np.float32)
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        m = (t > t0) & (t <= t1) if i else (t <= t1)
        f = np.clip((t - t0) / (t1 - t0), 0.0, 1.0)[..., None]
        c0a = np.array(c0, dtype=np.float32)
        c1a = np.array(c1, dtype=np.float32)
        cols[m] = (c0a * (1.0 - f) + c1a * f)[m]
    t_last, c_last = stops[-1]
    m = t > t_last
    if m.any():
        cols[m] = np.array(c_last, dtype=np.float32)
    del m
    return Image.fromarray(np.clip(cols, 0, 255).astype(np.uint8), "RGB")


# Gradient sweep: 37 degrees from horizontal, tuned so the mid stop lands on
# the icon centre (a corner-to-corner sweep would waste half the ramp).
GRAD_DIR = (0.6, 0.8)
GRAD_STOPS = (0.18, 0.50, 0.92)


def diag_gradient(stops_hex):
    proj = (GRAD_DIR[0] + GRAD_DIR[1]) / 2.0
    p0 = (CX - proj * GRAD_STOPS[0] * SQ, CY - proj * GRAD_STOPS[0] * SQ)
    p1 = (CX + proj * (1.0 - GRAD_STOPS[0]) * SQ,
          CY + proj * (1.0 - GRAD_STOPS[0]) * SQ)
    st = [(0.0, stops_hex[0]),
          ((GRAD_STOPS[1] - GRAD_STOPS[0]) / (1.0 - GRAD_STOPS[0]), stops_hex[1]),
          (1.0, stops_hex[2])]
    return gradient_img(st, p0, p1)


def squircle_mask(n_exp=4.6):
    """Analytic superellipse mask; fills the full frame except the 4 corners."""
    a = SQ / 2.0
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    x = np.abs(xx - CX) / a
    y = np.abs(yy - CY) / a
    d = np.power(x, n_exp) + np.power(y, n_exp)
    cov = np.clip((1.0 - d) * N * 0.35 + 0.5, 0.0, 1.0)  # ~0.5px AA edge
    return Image.fromarray((cov * 255.0).astype(np.uint8), "L")


def full_frame_bg(stops_hex):
    """Diagonal gradient for the squircle body (corner fill happens later)."""
    return diag_gradient(stops_hex)


def finish_squircle(bg_rgb, mask, dither=1.25, grain=0.007):
    """Compose the squircle over its own filled corners, add depth + grain."""
    arr = np.asarray(bg_rgb, dtype=np.float32).copy()
    cov = mask_to_np(mask)

    # rim light on the top-left edge, soft shade on the bottom-right
    rl = soften(mask, 26.0)
    inner = np.clip((cov - mask_to_np(rl)) / 0.9, 0.0, 1.0)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    gx = (xx - CX) / (SQ / 2.0)
    gy = (yy - CY) / (SQ / 2.0)
    diag = np.clip((gx + gy) / 2.0, -1.0, 1.0)          # -1 = top-left
    light = np.clip(-diag, 0.0, 1.0) * inner            # white top-left
    shade = np.clip(diag, 0.0, 1.0) * inner             # dark bottom-right
    arr += light[..., None] * np.array([255, 255, 255], np.float32) * 0.16
    arr -= shade[..., None] * np.array([32, 22, 96], np.float32) * 0.16

    # gentle centre glow from the top-left (fake volume)
    rad = np.hypot(gx, gy)
    arr += np.clip(1.0 - rad, 0.0, 1.0)[..., None] * np.array([16, 20, 40], np.float32) * 0.35

    # dither to kill gradient banding, then a whisper of grain
    noise = RNG.integers(0, 2, size=(N, N)) * 2 - 1
    noise = np.asarray(Image.fromarray((noise + 1).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(0.6)), dtype=np.float32) - 1.0
    arr += noise[..., None] * float(dither)

    g = (RNG.random((N, N)) - 0.5) * 2.0 * 255.0 * float(grain)
    arr += g[..., None]

    arr = np.clip(arr, 0, 255).astype(np.uint8)

    # corners outside the squircle: mirror continuation of the gradient
    out = np.array(arr)
    inside = cov > 0.5
    f = 0.030
    xm = np.clip((CX + (xx - CX) * (1.0 - f)).astype(np.int32), 0, N - 1)
    ym = np.clip((CY + (yy - CY) * (1.0 - f)).astype(np.int32), 0, N - 1)
    out[~inside] = arr[ym[~inside], xm[~inside]]
    # blend across the squircle boundary so the corner fill is seamless
    edge = (cov > 0.001) & (cov < 0.999)
    alpha = cov[edge][..., None]
    out[edge] = (alpha * arr[edge] + (1.0 - alpha) * out[edge]).astype(np.uint8)
    return Image.fromarray(out, "RGB")


# --------------------------------------------------------------------------
# Shape primitives
# --------------------------------------------------------------------------

def rrect(draw, cx, cy, w, h, radius, fill):
    draw.rounded_rectangle([cx - w / 2.0, cy - h / 2.0, cx + w / 2.0, cy + h / 2.0],
                           radius=radius, fill=fill)


def arc_band(draw, cx, cy, r, width, a0, a1, fill, steps=280):
    """Thick circular arc drawn as a stroked polyline plus round caps.

    Drawing a polyline with `joint="curve"` avoids the stray end tails you get
    from stamping circles at every sample point.
    """
    pts = []
    for i in range(steps + 1):
        a = math.radians(a0 + (a1 - a0) * i / steps)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    w = max(1, r2(width))
    draw.line(pts, fill=fill, width=w, joint="curve")
    for p in (pts[0], pts[-1]):
        draw.ellipse([p[0] - w / 2.0, p[1] - w / 2.0,
                      p[0] + w / 2.0, p[1] + w / 2.0], fill=fill)


def rounded_tri(cx, cy, h, r, rot_deg):
    """2D rounded-triangle outline (right-pointing) -> list of points."""
    h = float(h)
    pts = [(h * 0.577, 0.0), (-h * 0.289, h * 0.5), (-h * 0.289, -h * 0.5)]
    th = math.radians(rot_deg)
    ct, st = math.cos(th), math.sin(th)
    pts = [(p[0] * ct - p[1] * st, p[0] * st + p[1] * ct) for p in pts]

    d = float(r)
    inner = []
    for i in range(3):
        a, b, c = pts[i], pts[(i + 1) % 3], pts[(i + 2) % 3]
        ux, uy = b[0] - a[0], b[1] - a[1]
        vx, vy = c[0] - a[0], c[1] - a[1]
        lu, lv = math.hypot(ux, uy), math.hypot(vx, vy)
        ux, uy, vx, vy = ux / lu, uy / lu, vx / lv, vy / lv
        cosal = ux * vx + uy * vy
        sinal = math.sqrt(max(1e-9, 1.0 - cosal * cosal))
        sinhalf = math.sqrt(max(1e-12, (1.0 - cosal) / 2.0))
        t = d * sinhalf / sinal
        bx, by = a[0] + ux * t, a[1] + uy * t
        dx, dy = a[0] + vx * t, a[1] + vy * t
        mx, my = (bx + dx) / 2.0, (by + dy) / 2.0
        L = math.hypot(mx - a[0], my - a[1])
        inner.append((mx + (mx - a[0]) / L * d, my + (my - a[1]) / L * d))

    def norm(p):
        l = math.hypot(p[0], p[1])
        return (p[0] / l, p[1] / l)

    out = []
    for i in range(3):
        A = pts[i]
        INp, INn = inner[i], inner[(i + 1) % 3]
        d1 = norm((INp[0] - A[0], INp[1] - A[1]))
        d2 = norm((INn[0] - A[0], INn[1] - A[1]))
        a0 = math.degrees(math.atan2(d1[1], d1[0]))
        a1 = math.degrees(math.atan2(d2[1], d2[0]))
        while a1 - a0 > 180.0:
            a1 -= 360.0
        while a1 - a0 < -180.0:
            a1 += 360.0
        steps = max(8, int(abs(a1 - a0) / 3.0))
        for k in range(steps + 1):
            a = math.radians(a0 + (a1 - a0) * k / steps)
            out.append((A[0] + d * math.cos(a), A[1] + d * math.sin(a)))
    return out


def sc(pts, cx_off, cy_off, extra=0.0):
    """design-space (origin at icon centre, y down) -> render pixels."""
    return [(CX + (p[0] + cx_off) * S, CY + (p[1] + cy_off) * S + extra) for p in pts]


def bez(p0, p1, p2, p3, steps=64):
    out = []
    for i in range(1, steps + 1):
        t = i / float(steps)
        mt = 1.0 - t
        x = (mt ** 3 * p0[0] + 3 * mt * mt * t * p1[0]
             + 3 * mt * t * t * p2[0] + t ** 3 * p3[0])
        y = (mt ** 3 * p0[1] + 3 * mt * mt * t * p1[1]
             + 3 * mt * t * t * p2[1] + t ** 3 * p3[1])
        out.append((x, y))
    return out


# Teardrop geometry, design space (origin = icon centre, +y down).
# Height 856 x width 566: a real droplet ratio, the bulb owning the lower 60%
# and a blunt-but-pointed cap on top. Both joins are curvature-continuous:
#   * the apex cap handle is chosen so its tangent at DROP_WIDE lies along the
#     bulb circle tangent there;
#   * the bulb handle is DROP_K * R and its offset point lies on the cap's
#     tangent line, so the two curves meet without a kink.
DROP_APEX = (0.0, -440.0)
DROP_WIDE = (283.0, 80.0)
DROP_TOP = (0.0, -392.0)
DROP_BOTTOM = (0.0, 416.0)
DROP_K = 0.78          # handle length = DROP_K * R keeps the outline kink-free


def drop_outline():
    """Smooth teardrop: tapered apex, fairing, circular bulb."""
    apex, wide, top, bot = DROP_APEX, DROP_WIDE, DROP_TOP, DROP_BOTTOM
    R = (wide[0] ** 2 + (bot[1] - wide[1]) ** 2 / 4.0) / (2.0 * wide[0])
    cy = bot[1] - R

    hx, hy = top[0] - apex[0], top[1] - apex[1]
    ll = math.hypot(hx, hy)
    hx, hy = hx / ll, hy / ll
    dx, dy = wide[0] - apex[0], wide[1] - apex[1]
    dl = math.hypot(dx, dy)
    wx, wy = dx / dl, dy / dl
    hl = dl / (2.0 * (hx * wx + hy * wy))          # |apex handle|

    c2o = (wide[0] - DROP_K * R * wx, wide[1] - DROP_K * R * wy)   # bulb outer handle
    C1 = (apex[0] + hx * hl, apex[1] + hy * hl)
    a0 = math.atan2(wide[1] - cy, wide[0])
    a1 = math.atan2(bot[1] - cy, 0.0)

    pts = [apex]
    pts += bez(apex, C1, c2o, wide, steps=72)
    steps = 240
    for i in range(1, steps + 1):
        a = a0 + (a1 - a0) * i / float(steps)
        pts.append((R * math.cos(a), cy + R * math.sin(a)))
    pts.append((-wide[0], wide[1]))
    mirror = [(-x, y) for (x, y) in pts[1:-1]][::-1]
    pts += mirror
    return pts


def crescent_oval_mask(cx, cy, w, h, rot_deg, blur):
    """Soft crescent built from an even-odd oval pair (glossy highlight)."""
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    d.ellipse([cx - w / 2.0, cy - h / 2.0, cx + w / 2.0, cy + h / 2.0], fill=255)
    off = w * 0.62
    d.ellipse([cx - w / 2.0 + off, cy - h / 2.0 + off * 0.42,
               cx + w / 2.0 + off, cy + h / 2.0 + off * 0.42], fill=0)
    m = m.rotate(rot_deg, resample=Image.BICUBIC, center=(cx, cy))
    return soften(m, blur)


def soft_oval_mask(cx, cy, w, h, rot_deg, blur, gain=1.0):
    m = Image.new("L", (N, N), 0)
    ImageDraw.Draw(m).ellipse([cx - w / 2.0, cy - h / 2.0, cx + w / 2.0, cy + h / 2.0],
                              fill=255)
    m = m.rotate(rot_deg, resample=Image.BICUBIC, center=(cx, cy))
    m = soften(m, blur)
    if gain != 1.0:
        m = m.point(lambda v: int(min(255, v * gain)))
    return m


# --------------------------------------------------------------------------
# Concept A - water drop + play triangle
# --------------------------------------------------------------------------

def concept_a():
    bg = full_frame_bg(A_BG)
    mask = squircle_mask()
    base = to_rgba(finish_squircle(bg, mask))
    cov = mask_to_np(mask)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)

    oy = 24.0                      # optical vertical centring of the drop
    dpix = sc(drop_outline(), 0.0, oy)
    drop_mask = mask_from_draw(lambda d: d.polygon(dpix, fill=255))
    drop_mask = Image.fromarray(
        np.clip(mask_to_np(drop_mask) * cov, 0, 1).__mul__(255).astype(np.uint8), "L")
    dm = mask_to_np(drop_mask)

    # soft shadow: the drop must separate clearly from the blue field
    base = composite(base, drop_shadow(drop_mask, A_SHADOW, blur=58.0,
                                       strength=0.68, dx=-14.0, dy=-30.0))

    # body: vertical gradient white -> pale ice blue, plus edge shading
    arr = np.asarray(base, dtype=np.float32).copy()
    ty = (yy - (CY + (DROP_APEX[1] + oy) * S)) / ((DROP_BOTTOM[1] - DROP_APEX[1]) * S)
    tt = np.clip(ty, 0, 1)[..., None]
    col = (np.array([255, 255, 255], np.float32) * (1.0 - tt)
           + np.array(hx(A_DROP[1]), np.float32) * tt)
    arr[..., :3] = arr[..., :3] * (1.0 - dm[..., None]) + col * dm[..., None]
    arr[..., 3] = np.clip(arr[..., 3] + dm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")

    # inner shading: bright rim top-left, cool shade bottom-right
    er = soften(drop_mask, 40.0)
    inner = np.clip(dm - mask_to_np(er), 0, 1)
    nx = (xx - CX) / 283.0
    ny = (yy - (CY + (80.0 + oy) * S)) / 290.0
    light = np.clip(-(nx + ny * 0.75), 0, 1) * inner
    dark = np.clip(nx * 0.85 + ny * 0.8, 0, 1) * inner
    arr = np.asarray(base, np.float32)
    arr[..., :3] = np.clip(arr[..., :3]
                           + light[..., None] * np.array([255, 255, 255], np.float32) * 0.95
                           - dark[..., None] * np.array([64, 112, 196], np.float32) * 0.34,
                           0, 255)
    base = Image.fromarray(arr.astype(np.uint8), "RGBA")

    # glossy crescent hugging the left wall of the bulb
    lp = sc([(0.0, 0.0)], 0.0, oy)[0]
    cres = crescent_oval_mask(lp[0] - 172 * S, lp[1] + 80 * S, 210 * S, 600 * S,
                              0.0, 26.0)
    cres = Image.fromarray(
        (mask_to_np(cres) * dm * (1.0 - mask_to_np(soften(drop_mask, 22.0)))).__mul__(255)
        .astype(np.uint8), "L")
    base = composite(base, fill_mask(cres, "#FFFFFF", 0.85))

    # small sparkle inside the drop, on the left of the apex taper
    sp = sc([(0.0, 0.0)], -158.0, oy - 158.0)[0]
    spm = soft_oval_mask(sp[0], sp[1], 96 * S, 220 * S, -28.0, 32.0, 1.25)
    spm = Image.fromarray(
        (mask_to_np(spm) * dm).__mul__(255).astype(np.uint8), "L")
    base = composite(base, fill_mask(spm, "#FFFFFF", 0.80))

    # play triangle: white, soft shadow, nudged right for optical centring
    tri_pix = sc(rounded_tri(0.0, 0.0, 340.0, 46.0, 0.0), 22.0, oy + 112.0)
    tri_mask = mask_from_draw(lambda d: d.polygon(tri_pix, fill=255))
    base = composite(base, drop_shadow(tri_mask, A_SHADOW, blur=26.0,
                                       strength=0.52, dx=-6.0, dy=-11.0))
    tarr = np.asarray(base, dtype=np.float32).copy()
    tm = mask_to_np(tri_mask)
    tgrad = np.clip(((xx - CX) / 290.0 + (yy - CY) / 330.0) * 0.5 + 0.5, 0, 1)[..., None]
    tcol = (np.array(hx(A_PLAY[1]), np.float32) * tgrad
            + np.array(hx(A_PLAY[0]), np.float32) * (1.0 - tgrad))
    tarr[..., :3] = tarr[..., :3] * (1.0 - tm[..., None]) + tcol * tm[..., None]
    tarr[..., 3] = np.clip(tarr[..., 3] + tm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(tarr, 0, 255).astype(np.uint8), "RGBA")

    return composited_rgb(base)


def wave_layer_band(draw, y0, amp, h, phase, fill, step=11.0, x0=-560.0, x1=560.0,
                    period=900.0):
    """One horizontal water band: sine crest with a closed-polygon body."""
    top, bot = [], []
    x = x0
    while x <= x1 + 1e-6:
        yc = y0 + amp * math.sin(2.0 * math.pi * (x / period) + phase)
        top.append((CX + x * S, CY + (yc - h / 2.0) * S))
        bot.append((CX + x * S, CY + (yc + h / 2.0) * S))
        x += step
    draw.polygon(top + bot[::-1], fill=fill)


# --------------------------------------------------------------------------
# Concept B - spring / flowing water + play triangle
# --------------------------------------------------------------------------

def concept_b():
    bg = full_frame_bg(B_BG)
    mask = squircle_mask()
    base = to_rgba(finish_squircle(bg, mask))
    cov = mask_to_np(mask)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)

    # ---- flowing water: the whole field is water moving past the button ----
    wave_layer = Image.new("L", (N, N), 0)
    wd = ImageDraw.Draw(wave_layer)
    bands = [
        (-392.0, 58.0, 74.0, 1.20, 0.40),
        (-228.0, 80.0, 84.0, 3.10, 0.66),
        (-56.0, 94.0, 90.0, 5.00, 0.96),
        (120.0, 96.0, 92.0, 0.60, 1.00),
        (302.0, 82.0, 84.0, 2.50, 0.84),
        (470.0, 60.0, 72.0, 4.40, 0.56),
    ]
    for y0, amp, h, phase, al in bands:
        wave_layer_band(wd, y0, amp, h, phase, int(255 * al))

    # ripples fanning out of the source, drawn under the rings
    rip = Image.new("L", (N, N), 0)
    rd2 = ImageDraw.Draw(rip)
    for rr, w, al in ((300.0, 18.0, 0.50), (420.0, 16.0, 0.32), (540.0, 14.0, 0.18)):
        arc_band(rd2, CX, CY, rr * S, w * S, 206.0, 334.0, int(255 * al))
    rip = Image.fromarray(
        np.clip(mask_to_np(rip) * cov, 0, 1).__mul__(255).astype(np.uint8), "L")
    base = composite(base, fill_mask(rip, "#FFFFFF"))

    wave_layer = Image.fromarray(
        np.clip(mask_to_np(wave_layer) * cov, 0, 1).__mul__(255).astype(np.uint8), "L")
    base = composite(base, drop_shadow(wave_layer, "#0B2568", blur=26.0,
                                       strength=0.44, dx=-7.0, dy=-12.0))

    war = np.asarray(base, dtype=np.float32).copy()
    wm = mask_to_np(wave_layer)
    gx = (xx - CX) / (SQ / 2.0)
    gy = (yy - CY) / (SQ / 2.0)
    tt = np.clip(0.5 + 0.38 * (gx + gy), 0, 1)[..., None]
    wcol = (np.array(hx(B_WAVE[0]), np.float32) * (1.0 - tt)
            + np.array(hx(B_WAVE[1]), np.float32) * tt)
    war[..., :3] = war[..., :3] * (1.0 - wm[..., None]) + wcol * wm[..., None]
    war[..., 3] = np.clip(war[..., 3] + wm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(war, 0, 255).astype(np.uint8), "RGBA")

    # ---- the source: one big water circle the button sits on ---------------
    src_r = 268.0
    src_mask = mask_from_draw(lambda d: d.ellipse(
        [CX - src_r * S, CY - src_r * S, CX + src_r * S, CY + src_r * S], fill=255))
    src_mask = Image.fromarray(
        np.clip(mask_to_np(src_mask) * cov, 0, 1).__mul__(255).astype(np.uint8), "L")
    base = composite(base, drop_shadow(src_mask, "#0B2568", blur=30.0,
                                       strength=0.55, dx=-8.0, dy=-14.0))
    rm = mask_to_np(src_mask)
    srad = np.clip(1.0 - 0.62 * (1.0 - np.clip(np.hypot(xx - CX, yy - CY) / (src_r * S),
                                               0, 1)), 0, 1)[..., None]
    scol = (np.array(hx("#BFE8FF"), np.float32) * (1.0 - srad)
            + np.array([255, 255, 255], np.float32) * srad)
    sarr = np.asarray(base, dtype=np.float32).copy()
    sarr[..., :3] = sarr[..., :3] * (1.0 - rm[..., None]) + scol * rm[..., None]
    sarr[..., 3] = np.clip(sarr[..., 3] + rm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(sarr, 0, 255).astype(np.uint8), "RGBA")

    # ---- a few bubbles rising out of the source ----------------------------
    for (bx_, by_, rr_, al_) in ((-296.0, -158.0, 27.0, 0.72),
                                 (306.0, -46.0, 23.0, 0.60),
                                 (240.0, -256.0, 19.0, 0.44),
                                 (-214.0, 268.0, 21.0, 0.50)):
        p = sc([(0.0, 0.0)], bx_, by_)[0]
        bm_ = mask_from_draw(lambda d, p=p, rr_=rr_: d.ellipse(
            [p[0] - rr_ * S, p[1] - rr_ * S, p[0] + rr_ * S, p[1] + rr_ * S], fill=255))
        base = composite(base, fill_mask(bm_, "#FFFFFF", al_))

    # one warm spark, big enough to survive 48px
    sp = sc([(0.0, 0.0)], -336.0, 288.0)[0]
    spm = mask_from_draw(lambda d: d.ellipse(
        [sp[0] - 27 * S, sp[1] - 27 * S, sp[0] + 27 * S, sp[1] + 27 * S], fill=255))
    base = composite(base, fill_mask(spm, B_ACCENT_Y, 0.95))

    # ---- play triangle ----------------------------------------------------
    # Warm yellow, not white: the button sits on a white water circle, so a
    # white triangle would smear into it at 48px. Yellow separates from both
    # the white circle and the blue field, and adds the one warm accent.
    tri_pix = sc(rounded_tri(0.0, 0.0, 366.0, 50.0, 0.0), 22.0, -6.0)
    tri_mask = mask_from_draw(lambda d: d.polygon(tri_pix, fill=255))
    base = composite(base, drop_shadow(tri_mask, "#0B2568", blur=24.0,
                                       strength=0.42, dx=-6.0, dy=-10.0))
    tarr = np.asarray(base, dtype=np.float32).copy()
    tm = mask_to_np(tri_mask)
    tgrad = np.clip(((xx - CX) / 290.0 + (yy - CY) / 330.0) * 0.5 + 0.5, 0, 1)[..., None]
    tcol = (np.array(hx("#FFF0A8"), np.float32) * tgrad
            + np.array(hx(B_ACCENT_Y), np.float32) * (1.0 - tgrad))
    tarr[..., :3] = tarr[..., :3] * (1.0 - tm[..., None]) + tcol * tm[..., None]
    tarr[..., 3] = np.clip(tarr[..., 3] + tm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(tarr, 0, 255).astype(np.uint8), "RGBA")

    return composited_rgb(base)


# --------------------------------------------------------------------------
# Concept C - friendly bubble face with a play triangle inside
# --------------------------------------------------------------------------

def concept_c():
    bg = full_frame_bg(C_BG)
    mask = squircle_mask()
    base = to_rgba(finish_squircle(bg, mask))
    cov = mask_to_np(mask)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)

    bubble_c = (0.0, -78.0)
    bubble_r = 336.0
    px, py = sc([(0.0, 0.0)], bubble_c[0], bubble_c[1])[0]
    br = bubble_r * S

    bmask = mask_from_draw(lambda d: d.ellipse([px - br, py - br, px + br, py + br], fill=255))
    bmask = Image.fromarray(
        np.clip(mask_to_np(bmask) * cov, 0, 1).__mul__(255).astype(np.uint8), "L")
    bm = mask_to_np(bmask)

    # shadow
    base = composite(base, drop_shadow(bmask, "#3A0F6E", blur=46.0,
                                       strength=0.52, dx=-10.0, dy=-22.0))

    # body: warm sunny gradient, lit from the upper-left
    arr = np.asarray(base, dtype=np.float32).copy()
    bx = (xx - px) / br
    by = (yy - py) / br
    ll = np.clip(0.5 - 0.62 * (bx + by) * 0.5, 0, 1)[..., None]
    bcol = (np.array(hx(C_BUBBLE[1]), np.float32) * (1.0 - ll)
            + np.array(hx(C_BUBBLE[0]), np.float32) * ll)
    arr[..., :3] = arr[..., :3] * (1.0 - bm[..., None]) + bcol * bm[..., None]
    arr[..., 3] = np.clip(arr[..., 3] + bm * 255.0, 0, 255)

    # darker inner rim toward the bottom-right, bright rim top-left
    er = soften(bmask, 26.0)
    inner = np.clip(bm - mask_to_np(er), 0, 1)
    light = np.clip(-(bx + by), 0, 1) * inner
    dark = np.clip(bx + by, 0, 1) * inner
    arr[..., :3] = np.clip(arr[..., :3]
                           + light[..., None] * np.array([255, 255, 255], np.float32) * 0.55
                           - dark[..., None] * np.array([190, 120, 20], np.float32) * 0.35,
                           0, 255)
    base = Image.fromarray(arr.astype(np.uint8), "RGBA")

    # face
    fdraw = ImageDraw.Draw(base)
    blue = hx(C_FACE)
    for sx in (-1.0, 1.0):
        ex, ey = sc([(0.0, 0.0)], bubble_c[0] + sx * 118.0, bubble_c[1] - 44.0)[0]
        fdraw.ellipse([ex - 35 * S, ey - 44 * S, ex + 35 * S, ey + 44 * S], fill=blue)
    # eyes glint
    for sx in (-1.0, 1.0):
        gx0, gy0 = sc([(0.0, 0.0)], bubble_c[0] + sx * 118.0 - 12.0,
                      bubble_c[1] - 44.0 - 17.0)[0]
        fdraw.ellipse([gx0 - 12 * S, gy0 - 12 * S, gx0 + 12 * S, gy0 + 12 * S],
                      fill=(255, 255, 255, 210))
    # smile
    scx, scy = sc([(0.0, 0.0)], bubble_c[0], bubble_c[1] + 56.0)[0]
    srr = 132.0 * S
    fdraw.arc([scx - srr, scy - srr, scx + srr, scy + srr], 22.0, 158.0,
              fill=blue, width=r2(29 * S))
    for a in (22.0, 158.0):
        ar = math.radians(a)
        mx, my = scx + srr * math.cos(ar), scy + srr * math.sin(ar)
        fdraw.ellipse([mx - 14.5 * S, my - 14.5 * S, mx + 14.5 * S, my + 14.5 * S],
                      fill=blue)
    # cheeks
    for sx in (-1.0, 1.0):
        chx, chy = sc([(0.0, 0.0)], bubble_c[0] + sx * 204.0, bubble_c[1] + 52.0)[0]
        fdraw.ellipse([chx - 33 * S, chy - 21 * S, chx + 33 * S, chy + 21 * S],
                      fill=hx("#FF9A5A") + (150,))

    # top-left glossy highlight on the bubble
    hp = sc([(0.0, 0.0)], bubble_c[0] - 150.0, bubble_c[1] - 168.0)[0]
    hm = mask_from_draw(lambda d: d.ellipse(
        [hp[0] - 55 * S, hp[1] - 84 * S, hp[0] + 55 * S, hp[1] + 84 * S], fill=255))
    hm = hm.rotate(-40, resample=Image.BICUBIC, center=(hp[0], hp[1]))
    hm = soften(hm, 34.0).point(lambda v: int(min(255, v * 1.3)))
    base = composite(base, fill_mask(hm, "#FFFFFF", 0.92))

    # play badge, lower-right (kept inside the squircle safe area)
    badge_c = (216.0, 164.0)
    qx, qy = sc([(0.0, 0.0)], badge_c[0], badge_c[1])[0]
    qr = 186.0 * S
    qmask = mask_from_draw(lambda d: d.ellipse([qx - qr, qy - qr, qx + qr, qy + qr], fill=255))
    base = composite(base, drop_shadow(qmask, "#3A0F6E", blur=36.0,
                                       strength=0.50, dx=-9.0, dy=-17.0))
    qarr = np.asarray(base, dtype=np.float32).copy()
    qm = mask_to_np(qmask)
    qx0 = (xx - qx) / qr
    qy0 = (yy - qy) / qr
    ll = np.clip(0.5 - 0.35 * (qx0 + qy0) * 0.5, 0, 1)[..., None]
    qcol = (np.array(hx(C_BADGE[1]), np.float32) * (1.0 - ll)
            + np.array(hx(C_BADGE[0]), np.float32) * ll)
    qarr[..., :3] = qarr[..., :3] * (1.0 - qm[..., None]) + qcol * qm[..., None]
    qarr[..., 3] = np.clip(qarr[..., 3] + qm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(qarr, 0, 255).astype(np.uint8), "RGBA")

    # triangle inside the badge (optically centred)
    tri = rounded_tri(0.0, 0.0, 196.0, 30.0, 0.0)
    tri_pix = sc(tri, badge_c[0] + 12.0, badge_c[1] - 2.0)
    tri_mask = mask_from_draw(lambda d: d.polygon(tri_pix, fill=255))
    tarr = np.asarray(base, dtype=np.float32).copy()
    tm = mask_to_np(tri_mask)
    tcol = np.array(hx(C_TRI), np.float32)
    tarr[..., :3] = tarr[..., :3] * (1.0 - tm[..., None]) + tcol * tm[..., None]
    tarr[..., 3] = np.clip(tarr[..., 3] + tm * 255.0, 0, 255)
    base = Image.fromarray(np.clip(tarr, 0, 255).astype(np.uint8), "RGBA")

    return composited_rgb(base)


# --------------------------------------------------------------------------
# Output helpers
# --------------------------------------------------------------------------

def composited_rgb(rgba):
    """Flatten to RGB, guaranteeing no alpha channel in the saved PNG."""
    return rgba.convert("RGB")


def save_icon(img_rgb, name):
    path = os.path.join(OUT_DIR, name)
    final = img_rgb.resize((OUT, OUT), Image.LANCZOS)
    final = final.convert("RGB")
    final.save(path, "PNG", optimize=True)
    return final, path


def tile(img, size, radius_frac=0.225):
    """Downsample one icon and give it a soft drop shadow for the sheet."""
    small = img.resize((size, size), Image.LANCZOS).convert("RGBA")
    ss = 4
    big = small.resize((size * ss, size * ss), Image.LANCZOS)
    m = Image.new("L", (size * ss, size * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size * ss - 1, size * ss - 1], radius=int(size * ss * radius_frac), fill=255)
    big.putalpha(m)
    return big


def contact_sheet(icons):
    """One block per concept: a 512px hero tile plus 128 / 64 / 48 in a column.

    The small sizes sit to the right of the hero at its vertical centre, where
    they can still be judged at their true pixel size.
    """
    names = ["Concept A - water drop + play",
             "Concept B - spring flow + play",
             "Concept C - friendly play bubble"]
    pad = 46
    hero = 512
    smalls = [128, 64, 48]
    small_gap = 40
    label_h = 30
    block_gap = 58
    hero_w = 560
    small_col = max(smalls) + small_gap + 40
    width = pad * 2 + hero_w + small_col
    block_h = hero + label_h
    header_h = 60
    height = pad * 2 + header_h + len(icons) * (block_h + block_gap) - block_gap

    sheet = Image.new("RGB", (width, height), (236, 238, 242))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.load_default(size=19)
        tfont = ImageFont.load_default(size=25)
    except TypeError:  # very old Pillow
        font = ImageFont.load_default()
        tfont = font

    d.text((pad, pad - 4), "Bulak - icon concepts - readability at 512 / 128 / 64 / 48 px",
           fill=(36, 42, 58), font=tfont)

    y = pad + header_h
    for name, img in zip(names, icons):
        d.text((pad, y), name, fill=(44, 50, 70), font=font)
        top = y + label_h

        t = tile(img, hero)
        sheet.paste(t, (pad, top), t)
        d.text((pad + 4, top + hero + 8), "512px", fill=(92, 98, 116), font=font)

        x = pad + hero_w
        # stack the small sizes vertically, centred on the hero
        total = sum(smalls) + small_gap * (len(smalls) - 1)
        sy = top + (hero - total) // 2
        for size in smalls:
            st = tile(img, size)
            sheet.paste(st, (x, sy), st)
            d.text((x + size + 26, sy + size // 2 - 10), "%dpx" % size,
                   fill=(92, 98, 116), font=font)
            sy += size + small_gap

        y += block_h + block_gap

    return sheet


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print("Bulak icon concepts ->", OUT_DIR)

    icons = []
    for fn, name in ((concept_a, "concept_a_drop.png"),
                     (concept_b, "concept_b_spring.png"),
                     (concept_c, "concept_c_play_bubble.png")):
        img, path = save_icon(fn(), name)
        icons.append(img)
        print("  %-34s %7d bytes  %s" % (name, os.path.getsize(path), img.mode))

    sheet = contact_sheet(icons)
    spath = os.path.join(OUT_DIR, "contact_sheet.png")
    sheet.save(spath, "PNG", optimize=True)
    print("  %-34s %7d bytes  %s" % ("contact_sheet.png", os.path.getsize(spath),
                                     sheet.mode))
    print("done.")


if __name__ == "__main__":
    main()
