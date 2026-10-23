#!/usr/bin/env python3
"""Draw assets/cover.png (630x500) from the game's own sprite atlas and font.

Needs Pillow and a built build/web/art.png (tools/build.sh). The font is
Public Pixel (see the BOK's Tech/Public Pixel Font.md for the licence).
"""
from PIL import Image, ImageDraw, ImageFont
import sys

FONT = "/home/yermom/git/bok-of-splorr/splorr/Assets/PublicPixel.ttf"
W, H, S = 630, 500, 16
atlas = Image.open("build/web/art.png").convert("RGBA")
sprite = lambda i, k: atlas.crop((i * S, 0, i * S + S, S)).resize((S * k, S * k), Image.NEAREST)

img = Image.new("RGBA", (W, H), (0x1a, 0x1c, 0x2c, 255))
d = ImageDraw.Draw(img)
# A soft glow low on the horizon, then a meteor.
for r in range(260, 0, -4):
    a = int(40 * (1 - r / 260))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W // 2 - r * 2, 470 - r, W // 2 + r * 2, 470 + r), fill=(0xff, 0x77, 0xa8, a))
    img = Image.alpha_composite(img, glow)
d = ImageDraw.Draw(img)
for i in range(7):  # meteor trail
    x, y = 470 + i * 22, 40 + i * 4
    d.rectangle((x, y, x + 20, y + 10), fill=(0xff, 0xa3, 0x00, 255 - i * 30))
d.rectangle((440, 40, 468, 68), fill=(0xff, 0xec, 0x27, 255))
big = ImageFont.truetype(FONT, 40)
small = ImageFont.truetype(FONT, 18)
for text, y, fill, font in (("The End of", 120, "#f4f4f4", big), ("the World", 175, "#f4f4f4", big),
                            ("Was Nice", 230, "#ffec27", big)):
    w = d.textlength(text, font=font)
    d.text(((W - w) / 2 + 3, y + 3), text, font=font, fill="#000000")
    d.text(((W - w) / 2, y), text, font=font, fill=fill)
sub = "You have 20 seconds."
d.text(((W - d.textlength(sub, font=small)) / 2, 305), sub, font=small, fill="#94b0c2")
# The cast in a row.
k, gap = 5, 12
row = 6 * S * k + 5 * gap
x = (W - row) // 2
for i in range(6):
    img.alpha_composite(sprite(i, k), (x + i * (S * k + gap), 370))
img.convert("RGB").save("assets/cover.png")
print("assets/cover.png", img.size)
