from datetime import date
from io import BytesIO
from pathlib import Path

import qrcode
from reportlab.lib.colors import HexColor
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas


OUTPUT_FILE = Path(__file__).with_name("sample_wristbands.pdf")
WRISTBAND_DATE = date.today().strftime("%Y-%m-%d")
BABIES = [
    {"system_id": "HKL-BABY001", "ward": "Postnatal Ward A", "hospital_name": "Hospital Kuala Lumpur"},
    {"system_id": "HKL-BABY002", "ward": "Postnatal Ward B", "hospital_name": "Hospital Kuala Lumpur"},
    {"system_id": "HKL-BABY003", "ward": "NICU", "hospital_name": "Hospital Kuala Lumpur"},
    {"system_id": "HKL-BABY004", "ward": "SCN", "hospital_name": "Hospital Kuala Lumpur"},
    {"system_id": "HKL-BABY005", "ward": "Postnatal Ward A", "hospital_name": "Hospital Kuala Lumpur"},
    {"system_id": "HPJ-BABY001", "ward": "Postnatal Ward A", "hospital_name": "Hospital Putrajaya"},
    {"system_id": "HPJ-BABY002", "ward": "Postnatal Ward B", "hospital_name": "Hospital Putrajaya"},
    {"system_id": "HPJ-BABY003", "ward": "NICU", "hospital_name": "Hospital Putrajaya"},
    {"system_id": "HPJ-BABY004", "ward": "SCN", "hospital_name": "Hospital Putrajaya"},
    {"system_id": "HPJ-BABY005", "ward": "Postnatal Ward C", "hospital_name": "Hospital Putrajaya"},
    {"system_id": "HSB-BABY001", "ward": "Postnatal Ward A", "hospital_name": "Hospital Sungai Buloh"},
    {"system_id": "HSB-BABY002", "ward": "Postnatal Ward B", "hospital_name": "Hospital Sungai Buloh"},
    {"system_id": "HSB-BABY003", "ward": "NICU", "hospital_name": "Hospital Sungai Buloh"},
    {"system_id": "HSB-BABY004", "ward": "SCN", "hospital_name": "Hospital Sungai Buloh"},
    {"system_id": "HSB-BABY005", "ward": "Postnatal Ward C", "hospital_name": "Hospital Sungai Buloh"},
]

# Credit-card style dimensions.
CARD_WIDTH = 85.60 * mm
CARD_HEIGHT = 53.98 * mm
PAGE_MARGIN = 14 * mm
CARD_GAP = 8 * mm
QR_SIZE = 28 * mm


def build_qr_image(system_id: str) -> ImageReader:
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(system_id)
    qr.make(fit=True)

    image = qr.make_image(fill_color="black", back_color="white")
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    buffer.seek(0)
    return ImageReader(buffer)


def draw_card(pdf: canvas.Canvas, x: float, y: float, system_id: str, ward: str, hospital_name: str) -> None:
    pdf.setFillColor(HexColor("#FFFFFF"))
    pdf.setStrokeColor(HexColor("#1F2937"))
    pdf.roundRect(x, y, CARD_WIDTH, CARD_HEIGHT, 3 * mm, fill=1, stroke=1)

    qr_x = x + 6 * mm
    qr_y = y + (CARD_HEIGHT - QR_SIZE) / 2
    pdf.drawImage(build_qr_image(system_id), qr_x, qr_y, QR_SIZE, QR_SIZE, mask="auto")

    text_x = qr_x + QR_SIZE + 6 * mm
    top_y = y + CARD_HEIGHT - 10 * mm

    pdf.setFont("Helvetica-Bold", 10)
    pdf.setFillColor(HexColor("#111827"))
    pdf.drawString(text_x, top_y, hospital_name)

    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(text_x, top_y - 9 * mm, system_id)

    pdf.setFont("Helvetica", 8.5)
    pdf.setFillColor(HexColor("#4B5563"))
    pdf.drawString(text_x, top_y - 15 * mm, f"Ward: {ward}")
    pdf.drawString(text_x, top_y - 20 * mm, f"Date: {WRISTBAND_DATE}")

    pdf.setFont("Helvetica", 7)
    pdf.setFillColor(HexColor("#6B7280"))
    pdf.drawString(x + 6 * mm, y + 4 * mm, "Print at 100% scale")


def create_pdf() -> Path:
    page_width = CARD_WIDTH + (PAGE_MARGIN * 2)
    page_height = (CARD_HEIGHT * len(BABIES)) + (CARD_GAP * (len(BABIES) - 1)) + (PAGE_MARGIN * 2)

    pdf = canvas.Canvas(str(OUTPUT_FILE), pagesize=(page_width, page_height))

    current_y = page_height - PAGE_MARGIN - CARD_HEIGHT
    for baby in BABIES:
        draw_card(pdf, PAGE_MARGIN, current_y, baby["system_id"], baby["ward"], baby["hospital_name"])
        current_y -= CARD_HEIGHT + CARD_GAP

    pdf.save()
    return OUTPUT_FILE


if __name__ == "__main__":
    output_path = create_pdf()
    print(f"Created {output_path.name}")
