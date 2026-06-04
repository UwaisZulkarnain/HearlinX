import qrcode
from PIL import Image, ImageDraw, ImageFont

qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_H,
    box_size=10,
    border=4,
)
qr.add_data('https://dengartrackwebdashboard.vercel.app/')
qr.make(fit=True)

img = qr.make_image(fill_color="#0F766E", back_color="white").convert('RGB')

draw = ImageDraw.Draw(img)
text = "DengarTrack Web Dashboard"
try:
    font = ImageFont.truetype("arial.ttf", 30)
except:
    font = ImageFont.load_default()

new_img = Image.new('RGB', (img.size[0], img.size[1] + 60), "white")
new_img.paste(img, (0, 0))
draw = ImageDraw.Draw(new_img)
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
draw.text(((new_img.size[0] - text_width) // 2, img.size[1] + 15), text, fill="#0F766E", font=font)

new_img.save('misc\\Qr_generators\\dengartrack_Web_Dashboard.png')