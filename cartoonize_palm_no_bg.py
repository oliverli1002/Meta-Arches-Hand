from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageOps
import numpy as np


WORKDIR = Path(r"C:\Users\Oliver.OLIVER-LI-DESKT\Desktop\变胞手论文绘图")
SRC = WORKDIR / "人手掌弓照片-无背景.png"
TMP_SRC = Path(r"C:\Users\Oliver.OLIVER-LI-DESKT\Desktop\palm_no_bg.png")
OUT_SOFT_TMP = Path(r"C:\Users\Oliver.OLIVER-LI-DESKT\Desktop\palm_no_bg_cartoon_soft.png")
OUT_LINE_TMP = Path(r"C:\Users\Oliver.OLIVER-LI-DESKT\Desktop\palm_no_bg_cartoon_line.png")
OUT_SOFT = WORKDIR / "人手掌弓照片-无背景-动画风格-保留掌纹.png"
OUT_LINE = WORKDIR / "人手掌弓照片-无背景-动画风格-线稿增强.png"


def copy_to_ascii():
    # Pillow in this bundled Python can choke on non-ASCII paths, so use a temp ASCII path.
    import shutil
    shutil.copyfile(SRC, TMP_SRC)


def dilate(mask, radius=2):
    h, w = mask.shape
    padded = np.pad(mask, radius, mode="edge")
    out = np.zeros_like(mask, dtype=bool)
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy <= radius * radius:
                out |= padded[radius + dy: radius + dy + h, radius + dx: radius + dx + w]
    return out


def erode(mask, radius=2):
    h, w = mask.shape
    padded = np.pad(mask, radius, mode="edge")
    out = np.ones_like(mask, dtype=bool)
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy <= radius * radius:
                out &= padded[radius + dy: radius + dy + h, radius + dx: radius + dx + w]
    return out


def quantize_skin(rgb, alpha, levels=5):
    arr = np.asarray(rgb).astype(np.float32)
    a = np.asarray(alpha).astype(np.float32) / 255.0
    # Smooth color but keep geometry. Median suppresses photo noise; Gaussian softens transitions.
    smooth = Image.fromarray(np.uint8(np.clip(arr, 0, 255))).filter(ImageFilter.MedianFilter(5)).filter(ImageFilter.GaussianBlur(1.15))
    s = np.asarray(smooth).astype(np.float32)

    # Push toward a clean warm illustration palette while retaining local luminance.
    lum = 0.299 * s[..., 0] + 0.587 * s[..., 1] + 0.114 * s[..., 2]
    valid = a > 0.05
    if valid.any():
        lo, hi = np.percentile(lum[valid], [4, 96])
    else:
        lo, hi = 0, 255
    t = np.clip((lum - lo) / max(hi - lo, 1), 0, 1)
    tq = np.round(t * (levels - 1)) / (levels - 1)

    shadow = np.array([196, 105, 86], dtype=np.float32)
    mid = np.array([239, 163, 140], dtype=np.float32)
    light = np.array([255, 212, 184], dtype=np.float32)
    base = np.empty_like(s)
    low = tq < 0.5
    base[low] = shadow * (1 - tq[low][..., None] * 2) + mid * (tq[low][..., None] * 2)
    base[~low] = mid * (1 - (tq[~low][..., None] - 0.5) * 2) + light * ((tq[~low][..., None] - 0.5) * 2)

    # Blend a little original hue back in so it still looks like the source hand.
    cartoon = 0.78 * base + 0.22 * s
    return np.uint8(np.clip(cartoon, 0, 255))


def make_texture_lines(rgb, alpha, mask, strong=False):
    gray = ImageOps.grayscale(rgb)
    gray_arr = np.asarray(gray).astype(np.float32)
    blur = np.asarray(gray.filter(ImageFilter.GaussianBlur(4.0))).astype(np.float32)
    # Dark creases are where original is darker than local average.
    dark_detail = np.clip(blur - gray_arr, 0, 255)
    if mask.any():
        scale = np.percentile(dark_detail[mask], 96)
    else:
        scale = 40
    scale = max(scale, 18)
    detail = np.clip(dark_detail / scale, 0, 1)

    # Keep meaningful palm lines and joint wrinkles, not all photo grain.
    threshold = 0.27 if strong else 0.34
    line = np.clip((detail - threshold) / max(1 - threshold, 1e-6), 0, 1)
    line *= (np.asarray(alpha).astype(np.float32) / 255.0)
    line_img = Image.fromarray(np.uint8(line * 255), "L").filter(ImageFilter.GaussianBlur(0.35 if strong else 0.55))
    return np.asarray(line_img).astype(np.float32) / 255.0


def compose_variant(strong=False):
    img = Image.open(TMP_SRC).convert("RGBA")
    rgb = img.convert("RGB")
    alpha = img.getchannel("A")
    a = np.asarray(alpha)
    mask = a > 20

    base = quantize_skin(rgb, alpha, levels=5 if strong else 6).astype(np.float32)

    # Outline from alpha boundary.
    outer = dilate(mask, 2 if not strong else 3) & ~erode(mask, 2 if not strong else 3)
    outer_soft = np.asarray(Image.fromarray(np.uint8(outer) * 255, "L").filter(ImageFilter.GaussianBlur(0.65))).astype(np.float32) / 255.0

    # Internal palm textures / wrinkles.
    line = make_texture_lines(rgb, alpha, mask, strong=strong)

    # Slight cel-shaded edge map to make fingers read as illustration.
    edges = ImageOps.grayscale(rgb).filter(ImageFilter.FIND_EDGES)
    edges = ImageEnhance.Contrast(edges).enhance(1.6 if strong else 1.25).filter(ImageFilter.GaussianBlur(0.45))
    edge_arr = np.asarray(edges).astype(np.float32) / 255.0
    edge_arr *= (a.astype(np.float32) / 255.0)
    edge_arr = np.clip((edge_arr - (0.18 if strong else 0.24)) / 0.7, 0, 1)

    result = base.copy()
    # Dark reddish contour and crease color, closer to anatomical illustration than black ink.
    crease_color = np.array([118, 58, 50], dtype=np.float32)
    edge_color = np.array([86, 49, 45], dtype=np.float32)

    line_alpha = np.clip(line * (0.60 if not strong else 0.82), 0, 0.88)
    result = result * (1 - line_alpha[..., None]) + crease_color * line_alpha[..., None]

    edge_alpha = np.clip(edge_arr * (0.20 if not strong else 0.34), 0, 0.55)
    result = result * (1 - edge_alpha[..., None]) + edge_color * edge_alpha[..., None]

    outline_alpha = np.clip(outer_soft * (0.75 if not strong else 0.90), 0, 1)
    result = result * (1 - outline_alpha[..., None]) + edge_color * outline_alpha[..., None]

    # Add subtle warm highlight so the thumb and palm are not too flat.
    orig = np.asarray(rgb).astype(np.float32)
    lum = 0.299 * orig[..., 0] + 0.587 * orig[..., 1] + 0.114 * orig[..., 2]
    highlight = np.clip((lum - 150) / 105, 0, 1) * (a.astype(np.float32) / 255.0)
    result = result * (1 - 0.10 * highlight[..., None]) + np.array([255, 226, 205], dtype=np.float32) * (0.10 * highlight[..., None])

    out = np.dstack([np.uint8(np.clip(result, 0, 255)), a])
    # Make fully transparent pixels clean.
    out[a == 0, :3] = 0
    return Image.fromarray(out, "RGBA")


def main():
    copy_to_ascii()
    soft = compose_variant(strong=False)
    line = compose_variant(strong=True)
    soft.save(OUT_SOFT_TMP)
    line.save(OUT_LINE_TMP)
    import shutil
    shutil.copyfile(OUT_SOFT_TMP, OUT_SOFT)
    shutil.copyfile(OUT_LINE_TMP, OUT_LINE)
    print(OUT_SOFT)
    print(OUT_LINE)


if __name__ == "__main__":
    main()
