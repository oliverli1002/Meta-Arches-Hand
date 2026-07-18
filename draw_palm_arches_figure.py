from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math


OUT = Path(r"C:\Users\Oliver.OLIVER-LI-DESKT\Desktop\变胞手论文绘图")
W, H = 1800, 760
SCALE = 2


COL = {
    "ink": "#30343B",
    "soft": "#F7DAB6",
    "skin": "#F3C99B",
    "skin2": "#F6E0C4",
    "joint": "#C58F5A",
    "blue": "#2F80ED",
    "green": "#26A269",
    "magenta": "#D64A7F",
    "cyan": "#6EC6D8",
    "orange": "#F4A261",
    "gray": "#70757D",
    "light": "#F8FAFC",
}


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def bezier(p0, p1, p2, p3, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def svg_path(points):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


class Canvas:
    def __init__(self, w, h, scale=2):
        self.w, self.h, self.scale = w, h, scale
        self.svg = []
        self.img = Image.new("RGB", (w * scale, h * scale), "white")
        self.draw = ImageDraw.Draw(self.img)
        try:
            self.font = ImageFont.truetype("arial.ttf", 30 * scale)
            self.font_small = ImageFont.truetype("arial.ttf", 23 * scale)
            self.font_bold = ImageFont.truetype("arialbd.ttf", 32 * scale)
        except Exception:
            self.font = ImageFont.load_default()
            self.font_small = ImageFont.load_default()
            self.font_bold = ImageFont.load_default()

    def _spts(self, pts):
        return [(int(x * self.scale), int(y * self.scale)) for x, y in pts]

    def poly(self, pts, fill, stroke=None, width=2, opacity=1):
        self.svg.append(
            f'<polygon points="{svg_path(pts)}" fill="{fill}" fill-opacity="{opacity}" '
            f'stroke="{stroke or "none"}" stroke-width="{width}" stroke-linejoin="round"/>'
        )
        self.draw.polygon(self._spts(pts), fill=fill, outline=stroke)
        if stroke:
            self.draw.line(self._spts(pts + [pts[0]]), fill=stroke, width=width * self.scale, joint="curve")

    def line(self, pts, fill, width=4, dash=None, opacity=1):
        dash_attr = f' stroke-dasharray="{dash}"' if dash else ""
        self.svg.append(
            f'<polyline points="{svg_path(pts)}" fill="none" stroke="{fill}" stroke-opacity="{opacity}" '
            f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"{dash_attr}/>'
        )
        if dash:
            self._draw_dashed(pts, fill, width, dash)
        else:
            self.draw.line(self._spts(pts), fill=fill, width=width * self.scale, joint="curve")

    def _draw_dashed(self, pts, fill, width, dash):
        dash_len, gap_len = [float(x) for x in dash.split(",")[:2]]
        for a, b in zip(pts[:-1], pts[1:]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            dist = math.hypot(dx, dy)
            if dist == 0:
                continue
            ux, uy = dx / dist, dy / dist
            t = 0
            while t < dist:
                end = min(t + dash_len, dist)
                p1 = (a[0] + ux * t, a[1] + uy * t)
                p2 = (a[0] + ux * end, a[1] + uy * end)
                self.draw.line(self._spts([p1, p2]), fill=fill, width=width * self.scale)
                t += dash_len + gap_len

    def curve(self, p0, p1, p2, p3, fill, width=4, dash=None, opacity=1):
        pts = bezier(p0, p1, p2, p3, 80)
        self.svg.append(
            f'<path d="M {p0[0]:.1f} {p0[1]:.1f} C {p1[0]:.1f} {p1[1]:.1f}, {p2[0]:.1f} {p2[1]:.1f}, {p3[0]:.1f} {p3[1]:.1f}" '
            f'fill="none" stroke="{fill}" stroke-opacity="{opacity}" stroke-width="{width}" stroke-linecap="round" '
            f'stroke-linejoin="round"{" stroke-dasharray=\"" + dash + "\"" if dash else ""}/>'
        )
        self.line(pts, fill, width, dash, opacity)

    def ellipse(self, box, fill, stroke=None, width=2, opacity=1):
        x0, y0, x1, y1 = box
        self.svg.append(
            f'<ellipse cx="{(x0+x1)/2:.1f}" cy="{(y0+y1)/2:.1f}" rx="{(x1-x0)/2:.1f}" ry="{(y1-y0)/2:.1f}" '
            f'fill="{fill}" fill-opacity="{opacity}" stroke="{stroke or "none"}" stroke-width="{width}"/>'
        )
        self.draw.ellipse([int(v * self.scale) for v in box], fill=fill, outline=stroke, width=width * self.scale)

    def rect(self, box, fill, stroke=None, width=2, radius=0, opacity=1):
        x0, y0, x1, y1 = box
        self.svg.append(
            f'<rect x="{x0}" y="{y0}" width="{x1-x0}" height="{y1-y0}" rx="{radius}" '
            f'fill="{fill}" fill-opacity="{opacity}" stroke="{stroke or "none"}" stroke-width="{width}"/>'
        )
        self.draw.rounded_rectangle([int(v * self.scale) for v in box], radius=radius * self.scale, fill=fill, outline=stroke, width=width * self.scale)

    def text(self, xy, s, size=28, fill=None, bold=False, anchor="la"):
        x, y = xy
        color = fill or COL["ink"]
        self.svg.append(
            f'<text x="{x}" y="{y}" fill="{color}" font-family="Arial, Helvetica, sans-serif" '
            f'font-size="{size}" font-weight="{"700" if bold else "400"}">{esc(s)}</text>'
        )
        font = self.font_bold if bold else (self.font_small if size < 28 else self.font)
        self.draw.text((x * self.scale, (y - size) * self.scale), s, fill=color, font=font)

    def arrow_marker(self):
        self.svg.append(
            '<defs>'
            '<marker id="arrowInk" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto" markerUnits="strokeWidth">'
            f'<path d="M0,0 L0,6 L9,3 z" fill="{COL["ink"]}"/></marker>'
            '<marker id="arrowMag" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto" markerUnits="strokeWidth">'
            f'<path d="M0,0 L0,6 L9,3 z" fill="{COL["magenta"]}"/></marker>'
            '<marker id="arrowBlue" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto" markerUnits="strokeWidth">'
            f'<path d="M0,0 L0,6 L9,3 z" fill="{COL["blue"]}"/></marker>'
            '<marker id="arrowGreen" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto" markerUnits="strokeWidth">'
            f'<path d="M0,0 L0,6 L9,3 z" fill="{COL["green"]}"/></marker>'
            '</defs>'
        )

    def arrow_path(self, d, color, width=4, marker="arrowInk", dash=None):
        dash_attr = f' stroke-dasharray="{dash}"' if dash else ""
        self.svg.append(
            f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
            f'stroke-linecap="round" stroke-linejoin="round" marker-end="url(#{marker})"{dash_attr}/>'
        )

    def save(self, name):
        svg = (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}">\n'
            f'<rect width="100%" height="100%" fill="white"/>\n'
            + "\n".join(self.svg)
            + "\n</svg>\n"
        )
        (OUT / f"{name}.svg").write_text(svg, encoding="utf-8")
        self.img.save(OUT / f"{name}.png", dpi=(300, 300))


def draw_palm_arches(c, ox=0, oy=0, title=True):
    c.text((40 + ox, 52 + oy), "(a)", size=34, bold=True)
    if title:
        c.text((90 + ox, 52 + oy), "Human palmar arches", size=34, bold=True)

    # Palm silhouette
    palm = [
        (230 + ox, 535 + oy), (190 + ox, 455 + oy), (175 + ox, 360 + oy), (185 + ox, 270 + oy),
        (225 + ox, 220 + oy), (285 + ox, 208 + oy), (342 + ox, 222 + oy), (405 + ox, 214 + oy),
        (470 + ox, 235 + oy), (526 + ox, 292 + oy), (550 + ox, 380 + oy), (535 + ox, 480 + oy),
        (486 + ox, 565 + oy), (388 + ox, 612 + oy), (294 + ox, 590 + oy)
    ]
    c.poly(palm, COL["skin2"], COL["ink"], width=3)

    # Wrist
    c.curve((255 + ox, 590 + oy), (292 + ox, 665 + oy), (395 + ox, 665 + oy), (438 + ox, 592 + oy), COL["ink"], 3)

    # Fingers as simple rounded capsules
    fingers = [
        ((207 + ox, 178 + oy, 255 + ox, 350 + oy), -8),
        ((278 + ox, 118 + oy, 330 + ox, 340 + oy), -2),
        ((356 + ox, 114 + oy, 408 + ox, 344 + oy), 2),
        ((435 + ox, 153 + oy, 486 + ox, 360 + oy), 8),
    ]
    for box, _ in fingers:
        c.rect(box, COL["skin2"], COL["ink"], width=3, radius=26)
        x0, y0, x1, y1 = box
        c.line([(x0 + 7, y0 + 78), (x1 - 7, y0 + 78)], COL["joint"], 2)
        c.line([(x0 + 6, y0 + 140), (x1 - 6, y0 + 140)], COL["joint"], 2)

    # Thumb
    thumb = [(520 + ox, 358 + oy), (620 + ox, 300 + oy), (660 + ox, 330 + oy), (570 + ox, 445 + oy), (520 + ox, 420 + oy)]
    c.poly(thumb, COL["skin2"], COL["ink"], width=3)
    c.line([(570 + ox, 330 + oy), (615 + ox, 358 + oy)], COL["joint"], 2)

    # Palm crease hints
    c.curve((255 + ox, 475 + oy), (320 + ox, 515 + oy), (430 + ox, 510 + oy), (500 + ox, 462 + oy), COL["joint"], 2, opacity=0.8)
    c.curve((237 + ox, 422 + oy), (307 + ox, 445 + oy), (410 + ox, 440 + oy), (490 + ox, 410 + oy), COL["joint"], 2, opacity=0.8)

    # Arch curves
    c.curve((230 + ox, 365 + oy), (315 + ox, 322 + oy), (445 + ox, 322 + oy), (535 + ox, 365 + oy), COL["magenta"], 7, dash="16,12")
    c.arrow_path(f"M {230+ox} {365+oy} C {315+ox} {322+oy}, {445+ox} {322+oy}, {535+ox} {365+oy}", COL["magenta"], 0, "arrowMag")
    c.curve((352 + ox, 575 + oy), (344 + ox, 470 + oy), (345 + ox, 300 + oy), (352 + ox, 145 + oy), COL["blue"], 7, dash="18,12")
    c.curve((222 + ox, 510 + oy), (305 + ox, 430 + oy), (465 + ox, 405 + oy), (632 + ox, 330 + oy), COL["green"], 7, dash="18,12")

    # Labels and leader lines
    c.text((585 + ox, 255 + oy), "Distal transverse arch", size=25, fill=COL["magenta"], bold=True)
    c.line([(560 + ox, 278 + oy), (500 + ox, 335 + oy)], COL["magenta"], 3)
    c.text((460 + ox, 150 + oy), "Longitudinal arch", size=25, fill=COL["blue"], bold=True)
    c.line([(448 + ox, 162 + oy), (370 + ox, 230 + oy)], COL["blue"], 3)
    c.text((82 + ox, 612 + oy), "Oblique arch", size=25, fill=COL["green"], bold=True)
    c.line([(208 + ox, 595 + oy), (275 + ox, 500 + oy)], COL["green"], 3)


def draw_enveloping_grasps(c, ox=0, oy=0, title=True):
    c.text((40 + ox, 52 + oy), "(b)", size=34, bold=True)
    if title:
        c.text((90 + ox, 52 + oy), "Concave palm in enveloping grasps", size=34, bold=True)

    labels = ["spherical", "cylindrical", "power-palm"]
    centers = [(210 + ox, 355 + oy), (500 + ox, 355 + oy), (790 + ox, 355 + oy)]
    for idx, (cx, cy) in enumerate(centers):
        c.text((cx - 80, 655 + oy), labels[idx], size=25, fill=COL["gray"])
        # Forearm/wrist
        c.rect((cx - 95, cy + 165, cx + 95, cy + 220), COL["skin2"], COL["ink"], 3, radius=24)
        # Concave palm cup highlight
        cup = [
            (cx - 150, cy + 85), (cx - 120, cy - 20), (cx - 58, cy - 85),
            (cx, cy - 105), (cx + 58, cy - 85), (cx + 120, cy - 20), (cx + 150, cy + 85),
            (cx + 96, cy + 136), (cx + 32, cy + 154), (cx - 32, cy + 154), (cx - 96, cy + 136)
        ]
        c.poly(cup, COL["skin2"], COL["ink"], 3, opacity=1)
        inner = [
            (cx - 110, cy + 70), (cx - 82, cy - 6), (cx - 36, cy - 44),
            (cx, cy - 56), (cx + 36, cy - 44), (cx + 82, cy - 6), (cx + 110, cy + 70),
            (cx + 68, cy + 95), (cx, cy + 110), (cx - 68, cy + 95)
        ]
        c.poly(inner, COL["cyan"], None, 1, opacity=0.36)
        c.text((cx - 72, cy + 128), "concave\npalm", size=22, fill=COL["blue"])

        # Objects
        if idx == 0:
            c.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), COL["orange"], COL["ink"], 3)
            c.curve((cx - 45, cy - 50), (cx - 10, cy - 75), (cx + 40, cy - 58), (cx + 58, cy - 20), "#F8C98B", 5)
        elif idx == 1:
            c.rect((cx - 60, cy - 95, cx + 60, cy + 75), COL["orange"], COL["ink"], 3, radius=36)
            c.ellipse((cx - 60, cy - 105, cx + 60, cy - 65), "#F8C98B", COL["ink"], 3)
            c.ellipse((cx - 60, cy + 55, cx + 60, cy + 95), "#E78F4F", COL["ink"], 3)
        else:
            c.poly([(cx - 82, cy - 60), (cx + 76, cy - 82), (cx + 104, cy + 48), (cx - 45, cy + 92), (cx - 100, cy + 20)], COL["orange"], COL["ink"], 3)

        # Fingers wrapping over object
        for k, off in enumerate([-115, -55, 5, 65]):
            start = (cx + off, cy + 88)
            p1 = (cx + off * 0.96, cy - 40 - abs(off) * 0.16)
            p2 = (cx + off * 0.48, cy - 122)
            end = (cx + off * 0.08, cy - 92 + k * 8)
            c.curve(start, p1, p2, end, COL["skin"], 17)
            c.curve(start, p1, p2, end, COL["ink"], 3)
        # Thumb on side
        c.curve((cx + 142, cy + 85), (cx + 202, cy + 28), (cx + 198, cy - 44), (cx + 82, cy - 62), COL["skin"], 22)
        c.curve((cx + 142, cy + 85), (cx + 202, cy + 28), (cx + 198, cy - 44), (cx + 82, cy - 62), COL["ink"], 3)
        c.curve((cx - 142, cy + 85), (cx - 200, cy + 30), (cx - 192, cy - 40), (cx - 82, cy - 58), COL["skin"], 15)
        c.curve((cx - 142, cy + 85), (cx - 200, cy + 30), (cx - 192, cy - 40), (cx - 82, cy - 58), COL["ink"], 3)

        # Contact patches
        c.curve((cx - 92, cy + 52), (cx - 48, cy + 104), (cx + 48, cy + 104), (cx + 92, cy + 52), COL["blue"], 6, dash="12,10")

    # Shared annotation arrow
    if title:
        c.text((258 + ox, 118 + oy), "larger palm-object contact region", size=26, fill=COL["blue"], bold=True)
    else:
        c.text((310 + ox, 92 + oy), "larger palm-object contact region", size=22, fill=COL["blue"], bold=True)
    c.arrow_path(f"M {412+ox} {126+oy} C {470+ox} {168+oy}, {545+ox} {210+oy}, {623+ox} {277+oy}", COL["blue"], 4, "arrowBlue")


def make_panel_a():
    c = Canvas(820, 760, SCALE)
    c.arrow_marker()
    draw_palm_arches(c, 0, 0)
    c.save("Fig1a_human_palmar_arches_original")


def make_panel_b():
    c = Canvas(980, 760, SCALE)
    c.arrow_marker()
    draw_enveloping_grasps(c, 0, 0)
    c.save("Fig1b_enveloping_grasps_original")


def make_combined():
    c = Canvas(W, H, SCALE)
    c.arrow_marker()
    draw_palm_arches(c, 0, 0)
    c.line([(820, 95), (820, 700)], "#D7DCE2", 3)
    draw_enveloping_grasps(c, 820, 0)
    c.save("Fig1_palm_arches_and_enveloping_grasps_original")


def make_combined_clean():
    c = Canvas(W, H, SCALE)
    c.arrow_marker()
    draw_palm_arches(c, 0, 0, title=False)
    c.line([(820, 95), (820, 700)], "#D7DCE2", 3)
    draw_enveloping_grasps(c, 820, 0, title=False)
    c.save("Fig1_palm_arches_and_enveloping_grasps_clean")


if __name__ == "__main__":
    make_panel_a()
    make_panel_b()
    make_combined()
    make_combined_clean()
    print(OUT / "Fig1_palm_arches_and_enveloping_grasps_original.svg")
