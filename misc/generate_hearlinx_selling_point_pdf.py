from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.platypus import (
    Flowable,
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Project_documents" / "DengarTrack_Selling_Point_Brief.pdf"
LOGO = ROOT / "Project_documents" / "DengarTrack Logo.png"

TEAL = colors.HexColor("#0F766E")
DARK_TEAL = colors.HexColor("#115E59")
MINT = colors.HexColor("#ECFDF5")
INK = colors.HexColor("#0F172A")
SLATE = colors.HexColor("#475569")
LIGHT = colors.HexColor("#F8FAFC")
BORDER = colors.HexColor("#CBD5E1")
AMBER = colors.HexColor("#F59E0B")
RED = colors.HexColor("#DC2626")
GREEN = colors.HexColor("#16A34A")


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="Kicker",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=11,
        textColor=TEAL,
        spaceAfter=4,
        uppercase=True,
    )
)
styles.add(
    ParagraphStyle(
        name="TitleBig",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=25,
        leading=30,
        textColor=INK,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="Subtitle",
        parent=styles["Normal"],
        fontSize=11,
        leading=16,
        textColor=SLATE,
        spaceAfter=10,
    )
)
styles.add(
    ParagraphStyle(
        name="SectionTitle",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=15,
        leading=18,
        textColor=INK,
        spaceBefore=8,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="BodyTight",
        parent=styles["BodyText"],
        fontSize=9.5,
        leading=13.5,
        textColor=SLATE,
    )
)
styles.add(
    ParagraphStyle(
        name="BodyBold",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=9.5,
        leading=13,
        textColor=INK,
    )
)
styles.add(
    ParagraphStyle(
        name="Quote",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=12,
        leading=17,
        textColor=DARK_TEAL,
        alignment=TA_CENTER,
    )
)
styles.add(
    ParagraphStyle(
        name="Small",
        parent=styles["Normal"],
        fontSize=7.6,
        leading=10,
        textColor=SLATE,
    )
)


class HeaderBand(Flowable):
    def __init__(self, width, height=23 * mm):
        super().__init__()
        self.width = width
        self.height = height

    def draw(self):
        self.canv.setFillColor(TEAL)
        self.canv.roundRect(0, 0, self.width, self.height, 6, fill=1, stroke=0)
        self.canv.setFillColor(colors.white)
        self.canv.setFont("Helvetica-Bold", 11)
        self.canv.drawString(9 * mm, 13 * mm, "DengarTrack")
        self.canv.setFont("Helvetica", 8)
        self.canv.drawString(9 * mm, 8 * mm, "Conference Selling Point Brief | UNHS Digital Workflow Platform")
        self.canv.setFont("Helvetica-Bold", 8)
        self.canv.drawRightString(self.width - 9 * mm, 10 * mm, "Malaysia")


class PipelineGraphic(Flowable):
    def __init__(self, width, height=36 * mm):
        super().__init__()
        self.width = width
        self.height = height
        self.steps = [
            ("QR scan", "Baby ID"),
            ("Screening", "LULUS / RUJUK"),
            ("Follow-up", "Queue + urgency"),
            ("Audit", "Traceable record"),
            ("Report", "Hospital / KKM"),
        ]

    def draw(self):
        box_w = (self.width - 24 * mm) / 5
        y = 8 * mm
        for i, (title, sub) in enumerate(self.steps):
            x = i * (box_w + 6 * mm)
            self.canv.setFillColor(MINT if i != 2 else colors.HexColor("#FEF3C7"))
            self.canv.setStrokeColor(TEAL if i != 2 else AMBER)
            self.canv.roundRect(x, y, box_w, 19 * mm, 5, fill=1, stroke=1)
            self.canv.setFillColor(INK)
            self.canv.setFont("Helvetica-Bold", 8.5)
            self.canv.drawCentredString(x + box_w / 2, y + 12 * mm, title)
            self.canv.setFillColor(SLATE)
            self.canv.setFont("Helvetica", 7.2)
            self.canv.drawCentredString(x + box_w / 2, y + 7 * mm, sub)
            if i < len(self.steps) - 1:
                ax = x + box_w + 1.7 * mm
                ay = y + 9.5 * mm
                self.canv.setStrokeColor(TEAL)
                self.canv.setLineWidth(1.2)
                self.canv.line(ax, ay, ax + 3.5 * mm, ay)
                self.canv.line(ax + 3.5 * mm, ay, ax + 2 * mm, ay + 1.5 * mm)
                self.canv.line(ax + 3.5 * mm, ay, ax + 2 * mm, ay - 1.5 * mm)
        self.canv.setFillColor(SLATE)
        self.canv.setFont("Helvetica", 7.5)
        self.canv.drawCentredString(
            self.width / 2,
            1.8 * mm,
            "One bedside entry flows into operational action, governance evidence, and programme reporting.",
        )


class MetricCard(Flowable):
    def __init__(self, width, label, value, color=TEAL):
        super().__init__()
        self.width = width
        self.height = 25 * mm
        self.label = label
        self.value = value
        self.color = color

    def draw(self):
        self.canv.setFillColor(colors.white)
        self.canv.setStrokeColor(BORDER)
        self.canv.roundRect(0, 0, self.width, self.height, 5, fill=1, stroke=1)
        self.canv.setFillColor(self.color)
        self.canv.roundRect(0, 0, 3 * mm, self.height, 2, fill=1, stroke=0)
        self.canv.setFillColor(INK)
        self.canv.setFont("Helvetica-Bold", 15)
        self.canv.drawString(8 * mm, 12.5 * mm, self.value)
        self.canv.setFillColor(SLATE)
        self.canv.setFont("Helvetica", 7.5)
        max_w = self.width - 15 * mm
        label = self.label
        while stringWidth(label, "Helvetica", 7.5) > max_w and len(label) > 8:
            label = label[:-4] + "..."
        self.canv.drawString(8 * mm, 7 * mm, label)


def p(text, style="BodyTight"):
    return Paragraph(text, styles[style])


def table(data, widths, header=True):
    t = Table(data, colWidths=widths, hAlign="LEFT")
    commands = [
        ("BOX", (0, 0), (-1, -1), 0.6, BORDER),
        ("INNERGRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#E2E8F0")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]
    if header:
        commands.extend(
            [
                ("BACKGROUND", (0, 0), (-1, 0), TEAL),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ]
        )
    t.setStyle(TableStyle(commands))
    return t


def bullet(text):
    return p(f"<b>-</b> {text}")


def build_pdf():
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=14 * mm,
        bottomMargin=13 * mm,
        title="DengarTrack Selling Point Brief",
        author="Uwais",
        subject="Conference selling point brief for DengarTrack",
    )

    width = A4[0] - doc.leftMargin - doc.rightMargin
    story = []

    story.append(HeaderBand(width))
    story.append(Spacer(1, 10))

    if LOGO.exists():
        logo = Image(str(LOGO), width=32 * mm, height=32 * mm)
        title_block = [
            p("CORE SELLING POINT", "Kicker"),
            p("From bedside screening to national programme visibility", "TitleBig"),
            p(
                "DengarTrack is a Malaysia-ready digital workflow platform for Universal Newborn Hearing Screening (UNHS). It replaces fragmented paper cards, Excel files, WhatsApp coordination, and manual reports with one connected, auditable workflow.",
                "Subtitle",
            ),
        ]
        story.append(Table([[title_block, logo]], colWidths=[width - 38 * mm, 34 * mm]))
    else:
        story.append(p("CORE SELLING POINT", "Kicker"))
        story.append(p("From bedside screening to national programme visibility", "TitleBig"))
        story.append(
            p(
                "DengarTrack is a Malaysia-ready digital workflow platform for Universal Newborn Hearing Screening (UNHS). It replaces fragmented paper cards, Excel files, WhatsApp coordination, and manual reports with one connected, auditable workflow.",
                "Subtitle",
            )
        )

    story.append(Spacer(1, 6))
    story.append(
        KeepTogether(
            [
                table(
                    [
                        [
                            p(
                                '"DengarTrack is not just a screening app. It is a complete UNHS digital care pathway: QR bedside screening, offline capture, follow-up tracking, audit documentation, and KKM-ready reporting in one scalable platform."',
                                "Quote",
                            )
                        ]
                    ],
                    [width],
                    header=False,
                )
            ]
        )
    )
    story.append(Spacer(1, 10))
    story.append(PipelineGraphic(width))
    story.append(Spacer(1, 8))

    card_w = (width - 10 * mm) / 3
    story.append(
        Table(
            [
                [
                    MetricCard(card_w, "Malaysia household internet access, 2025", "97.1%", GREEN),
                    MetricCard(card_w, "AWS Malaysia Region available", "Local cloud", TEAL),
                    MetricCard(card_w, "PDPA amendments strengthen governance", "2024+", AMBER),
                ]
            ],
            colWidths=[card_w, card_w, card_w],
        )
    )
    story.append(Spacer(1, 11))

    story.append(p("The Best Conference Angle", "SectionTitle"))
    story.append(
        table(
            [
                [p("Angle", "BodyBold"), p("What to emphasize", "BodyBold")],
                [
                    p("Workflow transformation", "BodyBold"),
                    p("The project digitises the whole UNHS journey, not only the screening form. One cot-side action becomes a record, follow-up task, audit trail, and report."),
                ],
                [
                    p("LTFU reduction", "BodyBold"),
                    p("The follow-up queue makes RUJUK cases visible, prioritised, and accountable instead of being scattered across paper, Excel, or informal messaging."),
                ],
                [
                    p("Malaysia-ready design", "BodyBold"),
                    p("BM default, Android-first, offline-capable, QR-based, and built around public hospital realities where WiFi and staff workload can be inconsistent."),
                ],
                [
                    p("Scalable backend foundation", "BodyBold"),
                    p("FastAPI, PostgreSQL, JWT/RBAC, audit logs, report APIs, and structured modules make future integration with i-Jejak, HIS, FHIR/HL7, reminders, and multi-hospital rollout practical."),
                ],
            ],
            [42 * mm, width - 42 * mm],
        )
    )

    story.append(PageBreak())
    story.append(HeaderBand(width))
    story.append(Spacer(1, 10))
    story.append(p("What Makes This Strong", "SectionTitle"))

    story.append(
        table(
            [
                [p("Component", "BodyBold"), p("Current project value", "BodyBold"), p("Conference message", "BodyBold")],
                [
                    p("Flutter mobile app", "BodyBold"),
                    p("QR baby lookup, bedside screening entry, BM/EN toggle, secure token login, offline pending screening storage."),
                    p("Fast and practical for ward use."),
                ],
                [
                    p("Coordinator workflow", "BodyBold"),
                    p("Hospital dashboard, follow-up queue, urgency filtering, status actions, monthly reports, Excel export."),
                    p("Turns RUJUK cases into tracked action."),
                ],
                [
                    p("UNHS dashboard", "BodyBold"),
                    p("All-hospital aggregate view, programme summary, recent audit monitoring, no individual baby records."),
                    p("Programme oversight without overexposing patient data."),
                ],
                [
                    p("MOH / KKM view", "BodyBold"),
                    p("National aggregate dashboard, trends, hospital breakdown, policy attention signals, aggregate-only access."),
                    p("Supports population-level monitoring and policy decisions."),
                ],
                [
                    p("Backend + data model", "BodyBold"),
                    p("Role-based API enforcement, PostgreSQL schema, audit logs, anonymised baby system IDs, report endpoints."),
                    p("The foundation is the product's real strength."),
                ],
            ],
            [33 * mm, 82 * mm, width - 115 * mm],
        )
    )
    story.append(Spacer(1, 10))

    story.append(p("Why It Fits Malaysia's Digital Landscape", "SectionTitle"))
    story.append(
        table(
            [
                [p("Malaysia dynamic", "BodyBold"), p("How DengarTrack answers it", "BodyBold")],
                [
                    p("High digital readiness", "BodyBold"),
                    p("Malaysia already has very high internet access, and hospital staff are familiar with mobile-first workflows. A QR + Android-first app is easier to adopt than a heavy desktop-only system."),
                ],
                [
                    p("Healthcare digitalisation is still uneven", "BodyBold"),
                    p("MOH's Health White Paper notes that EMR has not been fully rolled out and databases/registries still have limited linkages. DengarTrack addresses one focused clinical workflow while remaining integration-ready."),
                ],
                [
                    p("Data governance pressure is increasing", "BodyBold"),
                    p("PDPA 2024 changes and public sensitivity around health data make RBAC, audit logs, anonymised IDs, and aggregate-only ministry views important selling points."),
                ],
                [
                    p("Local cloud/data residency is now more realistic", "BodyBold"),
                    p("AWS Malaysia Region supports lower-latency, in-country cloud deployment for future pilot or rollout phases."),
                ],
            ],
            [45 * mm, width - 45 * mm],
        )
    )
    story.append(Spacer(1, 10))

    story.append(p("The One-Line Pitch", "SectionTitle"))
    story.append(
        table(
            [
                [
                    p(
                        "<b>English:</b> DengarTrack turns newborn hearing screening from a fragmented paper-based task into a complete digital care pathway: QR bedside screening, offline capture, follow-up tracking, audit documentation, and KKM-ready reporting.",
                    )
                ],
                [
                    p(
                        "<b>BM:</b> DengarTrack bukan sekadar aplikasi saringan, tetapi platform workflow digital UNHS yang menghubungkan saringan di katil bayi kepada susulan, dokumentasi audit, pemantauan hospital, dan pelaporan KKM dalam satu sistem yang scalable.",
                    )
                ],
            ],
            [width],
            header=False,
        )
    )

    story.append(PageBreak())
    story.append(HeaderBand(width))
    story.append(Spacer(1, 10))
    story.append(p("Recommended Emphasis for Conference", "SectionTitle"))

    story.append(
        table(
            [
                [p("Priority", "BodyBold"), p("Talking point", "BodyBold"), p("Why it lands", "BodyBold")],
                [
                    p("1", "BodyBold"),
                    p("Full digital pipeline, not isolated app screens."),
                    p("Shows the project has system-level value."),
                ],
                [
                    p("2", "BodyBold"),
                    p("Follow-up visibility for RUJUK and LTFU risk."),
                    p("Connects technology to child health outcomes."),
                ],
                [
                    p("3", "BodyBold"),
                    p("Offline-capable QR workflow for real ward conditions."),
                    p("Makes the solution practical, not just idealistic."),
                ],
                [
                    p("4", "BodyBold"),
                    p("Backend, RBAC, audit logs, and reports create a scalable foundation."),
                    p("Shows readiness for pilot expansion and future integration."),
                ],
                [
                    p("5", "BodyBold"),
                    p("Aggregate-only UNHS/MOH views protect individual baby data."),
                    p("Matches governance and PDPA expectations."),
                ],
            ],
            [18 * mm, 76 * mm, width - 94 * mm],
        )
    )
    story.append(Spacer(1, 10))

    story.append(p("What Not To Over-Emphasize", "SectionTitle"))
    story.append(bullet("Do not pitch it as only a dashboard. The dashboard is monitoring; the real value is the full workflow and backend pipeline."))
    story.append(bullet("Do not oversell it as a complete national deployment yet. Stronger wording: pilot-ready foundation with clear scalability path."))
    story.append(bullet("Do not focus only on UI. The strongest technical asset is data flow, RBAC, auditability, reporting, and integration readiness."))
    story.append(Spacer(1, 8))

    story.append(p("Future Add-On Path", "SectionTitle"))
    story.append(
        table(
            [
                [p("Near term", "BodyBold"), p("Mid term", "BodyBold"), p("Long term", "BodyBold")],
                [
                    p("More seed data, wristbands, smoother offline sync, baby registration, pilot deployment."),
                    p("SMS/WhatsApp Business reminders without transmitting clinical data, richer analytics, multi-hospital rollout."),
                    p("i-Jejak/HIS integration, FHIR/HL7 interoperability, national UNHS registry and policy dashboard."),
                ],
            ],
            [width / 3, width / 3, width / 3],
        )
    )
    story.append(Spacer(1, 10))

    story.append(p("Source Notes", "SectionTitle"))
    story.append(
        p(
            "Malaysia context referenced from: MOH Health White Paper; DOSM ICT Use and Access by Individuals and Households Survey Report 2025; AWS announcement for Asia Pacific (Malaysia) Region; Malaysia Personal Data Protection Department page for PDPA 2010 and Personal Data Protection (Amendment) Act 2024.",
            "Small",
        )
    )
    story.append(Spacer(1, 5))
    story.append(
        p(
            "Prepared as a general conference selling point brief. Core message: workflow transformation, LTFU reduction, compliance-aware governance, and scalable backend foundation.",
            "Small",
        )
    )

    doc.build(story)


if __name__ == "__main__":
    build_pdf()
    print(OUT)
