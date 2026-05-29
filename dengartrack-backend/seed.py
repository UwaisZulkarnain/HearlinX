from sqlalchemy import text
from db.database import SessionLocal
from auth.auth import hash_password
import uuid
from dotenv import load_dotenv
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

# Load environment variables from dtbackend.env
env_path = Path(__file__).parent / "dtbackend.env"
load_dotenv(dotenv_path=env_path)


def get_or_create_hospital(db, hospital):
    existing = db.execute(
        text("SELECT id FROM hospitals WHERE code = :code LIMIT 1"),
        {"code": hospital["code"]},
    ).fetchone()

    if existing:
        db.execute(
            text("UPDATE hospitals SET name = :name, state = :state WHERE code = :code"),
            hospital,
        )
        return existing[0]

    hospital_id = str(uuid.uuid4())
    db.execute(
        text(
            """
            INSERT INTO hospitals (id, name, code, state)
            VALUES (:id, :name, :code, :state)
            """
        ),
        {
            "id": hospital_id,
            "name": hospital["name"],
            "code": hospital["code"],
            "state": hospital["state"],
        },
    )
    return hospital_id


def seed_user(db, user, hospital_ids, user_ids):
    existing_user = db.execute(
        text("SELECT id FROM users WHERE staff_id = :staff_id LIMIT 1"),
        {"staff_id": user["staff_id"]},
    ).fetchone()

    if existing_user:
        hospital_id = None
        if user.get("hospital_code"):
            hospital_id = hospital_ids[user["hospital_code"]]

        db.execute(
            text(
                """
                UPDATE users
                SET full_name = :name,
                    email = :email,
                    role = :role,
                    hospital_id = :hospital_id,
                    pin_hash = :pin_hash,
                    is_active = true
                WHERE staff_id = :staff_id
                """
            ),
            {
                "name": user["name"],
                "email": f"{user['staff_id'].lower()}@test.com",
                "role": user["role"],
                "hospital_id": hospital_id,
                "staff_id": user["staff_id"],
                "pin_hash": hash_password(user["pin"]),
            },
        )
        user_ids[user["staff_id"]] = existing_user[0]
        return

    hospital_id = None
    if user.get("hospital_code"):
        hospital_id = hospital_ids[user["hospital_code"]]

    user_id = str(uuid.uuid4())
    db.execute(
        text(
            """
            INSERT INTO users (
                id, full_name, email, role, hospital_id, is_active, staff_id, pin_hash
            )
            VALUES (
                :id, :name, :email, :role, :hospital_id, true, :staff_id, :pin_hash
            )
            """
        ),
        {
            "id": user_id,
            "name": user["name"],
            "email": f"{user['staff_id'].lower()}@test.com",
            "role": user["role"],
            "hospital_id": hospital_id,
            "staff_id": user["staff_id"],
            "pin_hash": hash_password(user["pin"]),
        },
    )
    user_ids[user["staff_id"]] = user_id


def seed_baby(db, baby, hospital_ids, baby_ids):
    existing_baby = db.execute(
        text("SELECT id FROM babies WHERE system_id = :system_id LIMIT 1"),
        {"system_id": baby["system_id"]},
    ).fetchone()

    if existing_baby:
        baby_ids[baby["system_id"]] = existing_baby[0]
        return

    baby_id = str(uuid.uuid4())
    db.execute(
        text(
            """
            INSERT INTO babies (
                id, system_id, hospital_id, full_name_enc, ic_number_enc,
                date_of_birth, gender, ward, gestational_age, birth_weight
            )
            VALUES (
                :id, :system_id, :hospital_id, :full_name_enc, :ic_number_enc,
                :dob, :gender, :ward, :gestational_age, :birth_weight
            )
            """
        ),
        {
            "id": baby_id,
            "system_id": baby["system_id"],
            "hospital_id": hospital_ids[baby["hospital_code"]],
            "full_name_enc": baby["full_name_enc"],
            "ic_number_enc": baby["ic_number_enc"],
            "dob": baby["dob"],
            "gender": baby["gender"],
            "ward": baby["ward"],
            "gestational_age": baby["gestational_age"],
            "birth_weight": baby["birth_weight"],
        },
    )
    baby_ids[baby["system_id"]] = baby_id


def make_babies(hospital_code, prefix, count, start_index=1):
    names = [
        "Aisyah Nur Binti Ahmad",
        "Muhammad Adam Bin Hafiz",
        "Nur Iman Binti Farid",
        "Harith Rayyan Bin Azman",
        "Sofia Humaira Binti Rahman",
        "Danish Hakim Bin Zulkifli",
        "Maryam Batrisya Binti Khairul",
        "Muhammad Irfan Bin Roslan",
        "Qistina Balqis Binti Amir",
        "Aiman Firdaus Bin Shahril",
        "Hana Aleesya Binti Nordin",
        "Umar Aqil Bin Syafiq",
        "Zara Medina Binti Faizal",
        "Luqman Hakimi Bin Kamal",
        "Maisarah Alya Binti Ridzuan",
        "Rizqi Haikal Bin Nazri",
        "Elina Sofea Binti Mazlan",
        "Arif Mikail Bin Jamal",
        "Nadia Insyirah Binti Salleh",
        "Yusuf Daniel Bin Ismail",
    ]
    wards = ["Postnatal Ward A", "Postnatal Ward B", "Postnatal Ward C", "NICU", "SCN"]
    babies = []

    for offset in range(count):
        index = start_index + offset
        gender = "F" if index % 2 else "M"
        gestational_age = [39, 38, 35, 37, 40, 36, 34, 41, 33, 32][offset % 10]
        birth_weight = [3120, 2950, 2260, 2740, 3380, 2450, 1980, 3560, 1820, 1690][offset % 10]
        babies.append(
            {
                "system_id": f"{prefix}-BABY{index:03d}",
                "hospital_code": hospital_code,
                "full_name_enc": names[offset % len(names)],
                "ic_number_enc": f"24{index:04d}-14-{index:04d}",
                "dob": f"2024-02-{((index - 1) % 28) + 1:02d}",
                "gender": gender,
                "ward": wards[offset % len(wards)],
                "gestational_age": gestational_age,
                "birth_weight": birth_weight,
            }
        )

    return babies


def seed_database():
    """Create test hospitals, users, and sample babies for testing."""
    db = SessionLocal()
    try:
        hospitals = [
            {
                "code": "HKL001",
                "name": "Hospital Kuala Lumpur",
                "state": "Kuala Lumpur",
            },
            {
                "code": "HPJ001",
                "name": "Hospital Putrajaya",
                "state": "Putrajaya",
            },
            {
                "code": "HSB001",
                "name": "Hospital Sungai Buloh",
                "state": "Selangor",
            },
        ]

        hospital_ids = {
            hospital["code"]: get_or_create_hospital(db, hospital)
            for hospital in hospitals
        }
        db.commit()

        users = [
            {"role": "screener", "staff_id": "SCR001HKL", "pin": "1234", "name": "Nur Aina Binti Rahman", "hospital_code": "HKL001"},
            {"role": "screener", "staff_id": "SCR002HKL", "pin": "1234", "name": "Muhammad Fahmi Bin Azlan", "hospital_code": "HKL001"},
            {"role": "screener", "staff_id": "SCR003HKL", "pin": "1234", "name": "Siti Hajar Binti Osman", "hospital_code": "HKL001"},
            {"role": "coordinator", "staff_id": "COO001HKL", "pin": "1234", "name": "Dr Nurul Izzah Binti Hamid", "hospital_code": "HKL001"},
            {"role": "coordinator", "staff_id": "COO002HKL", "pin": "1234", "name": "Ahmad Syafiq Bin Omar", "hospital_code": "HKL001"},
            {"role": "screener", "staff_id": "SCR001HPJ", "pin": "1234", "name": "Farah Nabila Binti Yusof", "hospital_code": "HPJ001"},
            {"role": "screener", "staff_id": "SCR002HPJ", "pin": "1234", "name": "Muhammad Hakim Bin Rosli", "hospital_code": "HPJ001"},
            {"role": "screener", "staff_id": "SCR003HPJ", "pin": "1234", "name": "Nor Idayu Binti Zainal", "hospital_code": "HPJ001"},
            {"role": "coordinator", "staff_id": "COO001HPJ", "pin": "1234", "name": "Dr Afiqah Binti Jalil", "hospital_code": "HPJ001"},
            {"role": "coordinator", "staff_id": "COO002HPJ", "pin": "1234", "name": "Mohd Rizal Bin Kamarudin", "hospital_code": "HPJ001"},
            {"role": "screener", "staff_id": "SCR001HSB", "pin": "1234", "name": "Amira Balqis Binti Salleh", "hospital_code": "HSB001"},
            {"role": "screener", "staff_id": "SCR002HSB", "pin": "1234", "name": "Ikhwan Danish Bin Mahmud", "hospital_code": "HSB001"},
            {"role": "screener", "staff_id": "SCR003HSB", "pin": "1234", "name": "Nadia Sofea Binti Ismail", "hospital_code": "HSB001"},
            {"role": "coordinator", "staff_id": "COO001HSB", "pin": "1234", "name": "Dr Liyana Binti Razak", "hospital_code": "HSB001"},
            {"role": "coordinator", "staff_id": "COO002HSB", "pin": "1234", "name": "Khairul Anwar Bin Saad", "hospital_code": "HSB001"},
            {"role": "unhs_coordinator", "staff_id": "ADM001", "pin": "1234", "name": "Test UNHS Coordinator"},
            {"role": "moh", "staff_id": "MOH001", "pin": "1234", "name": "Test MOH"},
        ]

        user_ids = {}
        for user in users:
            seed_user(db, user, hospital_ids, user_ids)
        db.commit()

        legacy_babies = [
            {
                **baby,
                "system_id": f"BABY{index:03d}",
                "hospital_code": "HKL001",
            }
            for index, baby in enumerate(make_babies("HKL001", "LEGACY", 20), start=1)
        ]

        babies = [
            *legacy_babies,
            *make_babies("HKL001", "HKL", 20),
            *make_babies("HPJ001", "HPJ", 10),
            *make_babies("HSB001", "HSB", 10),
        ]

        baby_ids = {}
        for baby in babies:
            seed_baby(db, baby, hospital_ids, baby_ids)
        db.commit()

        if "BABY001" in baby_ids and "SCR001HKL" in user_ids:
            existing_screening = db.execute(
                text(
                    """
                    SELECT id
                    FROM screenings
                    WHERE baby_id = :baby_id
                      AND screener_id = :screener_id
                      AND notes = :notes
                    LIMIT 1
                    """
                ),
                {
                    "baby_id": baby_ids["BABY001"],
                    "screener_id": user_ids["SCR001HKL"],
                    "notes": "Sample screening for testing",
                },
            ).fetchone()

            if not existing_screening:
                db.execute(
                    text(
                        """
                        INSERT INTO screenings (
                            id, baby_id, screener_id, hospital_id, screening_type,
                            ear_left, ear_right, attempt_number, notes
                        )
                        VALUES (
                            :id, :baby_id, :screener_id, :hospital_id, :screening_type,
                            :ear_left, :ear_right, :attempt_number, :notes
                        )
                        """
                    ),
                    {
                        "id": str(uuid.uuid4()),
                        "baby_id": baby_ids["BABY001"],
                        "screener_id": user_ids["SCR001HKL"],
                        "hospital_id": hospital_ids["HKL001"],
                        "screening_type": "TEOAE",
                        "ear_left": "pass",
                        "ear_right": "refer",
                        "attempt_number": 1,
                        "notes": "Sample screening for testing",
                    },
                )

        db.commit()
        print("✓ Seed complete:")
        print("  Hospitals: HKL001, HPJ001, HSB001")
        print("  Users (with hospital suffixes):")
        print("    HKL: SCR001HKL, SCR002HKL, SCR003HKL, COO001HKL, COO002HKL")
        print("    HPJ: SCR001HPJ, SCR002HPJ, SCR003HPJ, COO001HPJ, COO002HPJ")
        print("    HSB: SCR001HSB, SCR002HSB, SCR003HSB, COO001HSB, COO002HSB")
        print("    Admin: ADM001, MOH001 (unchanged)")
        print("  PIN for all demo users: 1234")
        print("  Babies: BABY001-020, HKL-BABY001-020, HPJ-BABY001-010, HSB-BABY001-010")
        print("  Screenings: sample screening preserved/created for BABY001")
    except Exception as e:
        db.rollback()
        print(f"✗ Seed failed: {e}")
        import traceback

        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
