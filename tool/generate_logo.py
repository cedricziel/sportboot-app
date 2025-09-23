#!/usr/bin/env python3
"""
Generate a simple logo for the Sportboot app
Creates a logo.png file in assets/images/
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_logo(size=512):
    # Create a new image with a blue gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw rounded rectangle background
    corner_radius = int(size * 0.2)
    # Main blue color
    main_color = (25, 118, 210, 255)  # Material Blue 700
    
    # Draw rounded rectangle
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=main_color
    )
    
    # Draw a simple boat shape (triangle for sail)
    white_color = (255, 255, 255, 230)
    
    # Sail 1 (left)
    sail1_points = [
        (size * 0.5, size * 0.25),  # top
        (size * 0.35, size * 0.6),   # bottom left
        (size * 0.5, size * 0.6),    # bottom right
    ]
    draw.polygon(sail1_points, fill=white_color)
    
    # Sail 2 (right)
    white_color_2 = (255, 255, 255, 180)
    sail2_points = [
        (size * 0.5, size * 0.3),   # top
        (size * 0.65, size * 0.6),  # bottom right
        (size * 0.5, size * 0.6),   # bottom left
    ]
    draw.polygon(sail2_points, fill=white_color_2)
    
    # Draw boat hull (simple line)
    hull_color = (255, 255, 255, 200)
    draw.line(
        [(size * 0.3, size * 0.6), (size * 0.7, size * 0.6)],
        fill=hull_color,
        width=int(size * 0.02)
    )
    
    # Draw wave lines
    wave_color = (255, 255, 255, 80)
    wave_y = size * 0.7
    # Wave 1
    draw.arc(
        [(size * 0.2, wave_y - 10), (size * 0.4, wave_y + 10)],
        start=0, end=180,
        fill=wave_color,
        width=int(size * 0.015)
    )
    # Wave 2
    draw.arc(
        [(size * 0.4, wave_y - 10), (size * 0.6, wave_y + 10)],
        start=0, end=180,
        fill=wave_color,
        width=int(size * 0.015)
    )
    # Wave 3
    draw.arc(
        [(size * 0.6, wave_y - 10), (size * 0.8, wave_y + 10)],
        start=0, end=180,
        fill=wave_color,
        width=int(size * 0.015)
    )
    
    # Add "SBF" text
    try:
        # Try to use a bold font if available
        font_size = int(size * 0.2)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    text = "SBF"
    text_color = (255, 255, 255, 255)
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text horizontally, place at bottom
    text_x = (size - text_width) // 2
    text_y = int(size * 0.75)
    
    draw.text((text_x, text_y), text, fill=text_color, font=font)
    
    return img

def main():
    # Create assets/images directory if it doesn't exist
    os.makedirs('assets/images', exist_ok=True)
    
    # Generate logo at different sizes
    logo = create_logo(512)
    logo.save('assets/images/logo.png')
    print("Generated assets/images/logo.png (512x512)")
    
    logo_2x = create_logo(1024)
    logo_2x.save('assets/images/logo@2x.png')
    print("Generated assets/images/logo@2x.png (1024x1024)")
    
    # Also create a smaller version for app icons
    logo_small = create_logo(256)
    logo_small.save('assets/images/logo_small.png')
    print("Generated assets/images/logo_small.png (256x256)")

if __name__ == "__main__":
    main()