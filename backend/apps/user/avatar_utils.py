"""
User avatar utilities
"""
import io
from PIL import Image, ImageDraw, ImageFont
from django.core.files.base import ContentFile
from django.contrib.auth import get_user_model
import random

User = get_user_model()


def generate_default_avatar(username: str, size: int = 200) -> ContentFile:
    """
    Generate a default avatar image with initials
    
    Args:
        username: The user's username
        size: Size of the avatar (default 200x200)
    
    Returns:
        ContentFile object that can be saved to ImageField
    """
    # Extract initials from username (first 2 characters or first character twice)
    initials = (username[:2] if len(username) >= 2 else username[0] * 2).upper()
    
    # Define a color palette for variety
    colors = [
        (255, 107, 107),  # Red
        (66, 165, 245),   # Blue
        (102, 187, 106),  # Green
        (255, 167, 38),   # Orange
        (171, 71, 188),   # Purple
        (29, 233, 182),   # Teal
        (255, 205, 86),   # Yellow
        (255, 138, 101),  # Deep Orange
        (103, 58, 183),   # Deep Purple
        (244, 67, 54),    # Crimson
    ]
    
    # Use username hash to get consistent color
    color = colors[sum(ord(c) for c in username) % len(colors)]
    
    # Create image
    image = Image.new('RGB', (size, size), color=color)
    draw = ImageDraw.Draw(image)
    
    # Try to use a nice font, fall back to default if not available
    try:
        # Try to find a nice font - this path works in most systems
        font_size = size // 3
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
    except:
        try:
            # Windows path
            font = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", size // 3)
        except:
            # Fall back to default font
            font = ImageFont.load_default()
    
    # Calculate text position (center)
    bbox = draw.textbbox((0, 0), initials, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    
    # Draw text
    draw.text((x, y), initials, fill=(255, 255, 255), font=font)
    
    # Convert to ContentFile
    img_io = io.BytesIO()
    image.save(img_io, format='PNG')
    img_io.seek(0)
    
    return ContentFile(img_io.getvalue(), name=f'{username}_avatar.png')


def get_avatar_url(user) -> str:
    """
    Get avatar URL for a user
    If user has custom avatar, return that URL
    Otherwise, return default avatar initials endpoint
    
    Args:
        user: User instance or user id
    
    Returns:
        Full URL to the avatar image
    """
    if isinstance(user, int):
        user = User.objects.get(id=user)
    
    if hasattr(user, 'profile') and user.profile.avatar:
        return user.profile.avatar.url
    
    # Return default avatar initials as a placeholder
    return f'/api/user/avatars/{user.id}/default/'
