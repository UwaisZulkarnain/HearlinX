DengarTrack Project

Exec Summary of the project (DengarTrack) 
					- a Digital Newborn Hearing Screening Management platform.
:DengarTrack is a purpose built mobile digital workflow platform designed to replaced fragmented paper-based management system currently used in Universal Newborn hearing Screening(UNHS) programmes across Malaysian public hospitals. No equivalent MOH-sanctioned platform currently exists.

*Product Overview*
What it does: DengarTrack replaces the current UNHS workflow -- Paper cards, Excel, Whatsapp groups, and manual MoH reports -- with a single Intergrated mobile platform. Every screener action at the cot side, flows automatically into the coordinator dashboard, follow-up queue and national reporting system.

*Concept - Design priciples: Speed first(any screener action <60 seconds) offline-Capable (works without WiFi) | Bahasa Melayu/English bilingual | PDPA 2010 compliant | Android 9+ | One entry, many uses
(data entered once by screener auto-populates dashboard, follow-up queue, and MoH report)

***Technical Requirements
**Technology Stack
IMPORTANT: The technology stack below is the recommended architecture based on the PDPA
compliance requirements, KKM hospital device inventory, and offline-first design constraint. 

Layer Specification
Frontend -- Mobile React Native (cross-platform Android/iOS) OR Flutter -- Android
primary target, iOS secondary
Frontend -- Web React.js -- for coordinator portal and KKM reporting dashboard on
desktop/laptop
Backend Node.js with Express OR FastAPI (Python) -- RESTful API
architecture
Database PostgreSQL -- primary relational database for patient records,
screening results, follow-up tracking
Offline storage SQLite (mobile) + IndexedDB (web) -- offline-first with background
sync when connectivity restored
Authentication JWT tokens + Role-Based Access Control (RBAC) -- 4 roles:
Screener, Coordinator, Hospital Admin, MoH/KKM
Cloud hosting AWS Malaysia region (ap-southeast-1) OR Azure Malaysia --
data residency requirement for PDPA compliance
Messaging WhatsApp Business API (Twilio) + SMS fallback (Twilio or
Nexmo) -- for automated parent reminders
Barcode scanning ZXing.js (web) OR React Native Camera (mobile) -- for QR
wristband scanning at point of care
Report export SheetJS -- Excel (.xlsx) export for KKM reports
Health data standard HL7 FHIR R4 -- for KKM registry and HIS integration (Phase 2)
Encryption TLS 1.3 in transit + AES-256 at rest -- mandatory for PDPA
compliance

****User Roles and Access Control
Role Access level
Screener Can enter and view own screening results only. Cannot access
other wards, coordinator data, or reports.
Coordinator (Audiologist) Full access to their hospital -- dashboard, follow-up queue, MoH
reports, handover initiation and receipt.
Hospital Admin Hospital-level summary metrics and audit logs only. Cannot view
individual baby records.
MoH / KKM Aggregate national dashboard and national report download only.
Cannot access individual hospital or baby data.


***The following are non-negotiable requirements, not optional features:
* All patient data encrypted in transit (TLS 1.3) and at rest (AES-256)
* Baby identifiers anonymised at inter-hospital transfer level -- Baby System ID only, never
names or IC numbers transmitted externally
* Full immutable audit log -- every action timestamped with user ID. Append-only, cannot be
edited or deleted.
* Role-based access enforced at API level, not just front-end
* No clinical data transmitted via any external consumer platform (WhatsApp, email, etc.)
* Data residency in Malaysia -- no data stored outside Malaysia region
* PDPA Data Protection Officer consultation required before pilot deployment
* External cybersecurity penetration test required before hospital pilot
3.4 Device and Connectivity Requirements
Requirement Specification
Primary device Android tablet (8-10 inch) and Android smartphone -- Android 9 and above
(covers 94% of KKM ward devices)
iOS support Secondary -- required for full market coverage but not blocking for Pilot 1
Offline capability Full core screening entry and shift summary must work with zero internet
connectivity
Sync behaviour Auto-sync when WiFi or mobile data available. Show sync status indicator
to screener.
Screen resolution Must be readable and usable on 720p Android devices
Language Bahasa Melayu as default. English toggle. All system messages and
automated SMS in BM.
Accessibility WCAG AA contrast ratios -- critical for clinical environments with poor
lighting


****Scope of Work
**What the Developer Is Responsible For
* Full-stack mobile and web application development across all 6 modules
* Database design, setup, and migration scripts
* API development and documentation
* PDPA-compliant data architecture and security implementation
* AWS/Azure Malaysia region infrastructure setup and configuration
* WhatsApp Business API and SMS gateway integration
* QR barcode scanning integration
* Excel and PDF report export implementation
* Offline sync mechanism development
* Bug fixing and technical issue resolution throughout pilot studies




_______________________________________BEGIN______________________________

1)	Flutter mobile app — for screeners at the cot side. Enter screening results
	in under 60 seconds, works offline, syncs when WiFi available, BM/EN bilingual, QR wristband scanning.
2)	React web portal — for coordinators (audiologists) and KKM/MoH. Dashboard,
	follow-up queue, national report downloads, Excel export.
3)	FastAPI backend — the brain. All data flows here, enforces RBAC, immutable 
	audit logs, encrypted, hosted on AWS Malaysia (ap-southeast-1) for PDPA compliance.
	
(4)user roles, strictly enforced at API level:

Screener → enter own results only
Coordinator → full hospital access
Hospital Admin → summary + audit logs only
MoH/KKM → national aggregate only, no individual data

Requirements:

TLS 1.3 in transit + AES-256 at rest
Immutable audit log, every action
Baby identifiers anonymised at transfer level
Zero clinical data via WhatsApp/email
All data stays in Malaysia

______READ ME____ ISUES

SQL PostgreSQL not connected
