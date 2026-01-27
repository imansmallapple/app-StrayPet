"""
Generate StrayPet app icon with paw print design
"""
from PIL import Image, ImageDraw
import os
import math

def draw_rounded_rect(draw, xy, radius, fill):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = xy
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    draw.pieslice([x1, y1, x1 + 2*radius, y1 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x2 - 2*radius, y1, x2, y1 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x1, y2 - 2*radius, x1 + 2*radius, y2], 90, 180, fill=fill)
    draw.pieslice([x2 - 2*radius, y2 - 2*radius, x2, y2], 0, 90, fill=fill)

def draw_paw_print(draw, center_x, center_y, scale=1.0, color='white'):
    """Draw a paw print at the specified position"""
    # Main pad (larger ellipse at bottom)
    main_pad_w = int(60 * scale)
    main_pad_h = int(50 * scale)
    main_pad_y = center_y + int(20 * scale)
    draw.ellipse([
        center_x - main_pad_w//2, 
        main_pad_y - main_pad_h//2,
        center_x + main_pad_w//2, 
        main_pad_y + main_pad_h//2
    ], fill=color)
    
    # Toe pads (4 smaller ellipses at top)
    toe_size = int(22 * scale)
    toe_y = center_y - int(25 * scale)
    toe_spacing = int(28 * scale)
    
    # Left outer toe
    draw.ellipse([
        center_x - toe_spacing - toe_size//2 - int(5*scale), 
        toe_y - toe_size//2 + int(8*scale),
        center_x - toe_spacing + toe_size//2 - int(5*scale), 
        toe_y + toe_size//2 + int(8*scale)
    ], fill=color)
    
    # Left inner toe
    draw.ellipse([
        center_x - toe_spacing//2 - toe_size//2 + int(2*scale), 
        toe_y - toe_size//2 - int(5*scale),
        center_x - toe_spacing//2 + toe_size//2 + int(2*scale), 
        toe_y + toe_size//2 - int(5*scale)
    ], fill=color)
    
    # Right inner toe
    draw.ellipse([
        center_x + toe_spacing//2 - toe_size//2 - int(2*scale), 
        toe_y - toe_size//2 - int(5*scale),
        center_x + toe_spacing//2 + toe_size//2 - int(2*scale), 
        toe_y + toe_size//2 - int(5*scale)
    ], fill=color)
    
    # Right outer toe
    draw.ellipse([
        center_x + toe_spacing - toe_size//2 + int(5*scale), 
        toe_y - toe_size//2 + int(8*scale),
        center_x + toe_spacing + toe_size//2 + int(5*scale), 
        toe_y + toe_size//2 + int(8*scale)
    ], fill=color)

def create_foreground(size=1024):
    """Create the foreground icon with paw print"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw paw print in white
    scale = size / 256
    draw_paw_print(draw, size//2, size//2, scale=scale, color='white')
    
    return img

def create_background(size=1024):
    """Create the background with orange gradient-like color"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # StrayPet orange color: #FF6B35
    orange = (255, 107, 53, 255)
    
    # Fill entire background with orange
    draw.rectangle([0, 0, size, size], fill=orange)
    
    return img

def create_app_icon(size=1024):
    """Create complete app icon for preview"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # StrayPet orange
    orange = (255, 107, 53, 255)
    
    # Draw rounded rectangle background
    corner_radius = size // 5
    draw_rounded_rect(draw, [0, 0, size, size], corner_radius, orange)
    
    # Draw paw print
    scale = size / 256
    draw_paw_print(draw, size//2, size//2, scale=scale, color='white')
    
    return img

def main():
    output_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    media_dir = os.path.join(output_dir, 'AppScope', 'resources', 'base', 'media')
    
    print(f"Output directory: {media_dir}")
    
    # Create images
    print("Creating foreground.png...")
    foreground = create_foreground(1024)
    foreground.save(os.path.join(media_dir, 'foreground.png'), 'PNG')
    
    print("Creating background.png...")
    background = create_background(1024)
    background.save(os.path.join(media_dir, 'background.png'), 'PNG')
    
    # Also create a preview icon
    print("Creating app_icon_preview.png...")
    preview = create_app_icon(512)
    preview.save(os.path.join(media_dir, 'app_icon_preview.png'), 'PNG')
    
    print("Done! Icon files have been generated.")
    print(f"  - {os.path.join(media_dir, 'foreground.png')}")
    print(f"  - {os.path.join(media_dir, 'background.png')}")
    print(f"  - {os.path.join(media_dir, 'app_icon_preview.png')}")

if __name__ == '__main__':
    main()
