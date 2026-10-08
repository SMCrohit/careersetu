from PIL import Image
import math

width = 1080
height = 1920

# Define colors
c1 = (15, 23, 42)    # 0xFF0F172A
c2 = (30, 58, 138)   # 0xFF1E3A8A
c3 = (6, 182, 212)   # 0xFF06b6d4

def interpolate(color1, color2, factor):
    return (
        int(color1[0] + (color2[0] - color1[0]) * factor),
        int(color1[1] + (color2[1] - color1[1]) * factor),
        int(color1[2] + (color2[2] - color1[2]) * factor)
    )

image = Image.new("RGB", (width, height))
pixels = image.load()

# Diagonal gradient from top-left to bottom-right
max_dist = math.sqrt(width**2 + height**2)

for y in range(height):
    for x in range(width):
        dist = math.sqrt(x**2 + y**2)
        factor = dist / max_dist
        
        # We have 3 colors, so color1 -> color2 is 0.0 -> 0.5, color2 -> color3 is 0.5 -> 1.0
        if factor < 0.5:
            # Map factor from 0-0.5 to 0-1
            f = factor * 2
            pixels[x, y] = interpolate(c1, c2, f)
        else:
            # Map factor from 0.5-1 to 0-1
            f = (factor - 0.5) * 2
            pixels[x, y] = interpolate(c2, c3, f)

image.save("assets/images/splash_bg.png")
