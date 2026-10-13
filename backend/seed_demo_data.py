"""Create idempotent, clearly labelled Tech-E20 demonstration data for 13 October 2026."""

from datetime import datetime
from decimal import Decimal

from database import get_db_connection


DEMO_FUELS = (
    ("Petrol Demo", Decimal("104.50"), Decimal("12000.00"), "DEMO-PT-20261013"),
    ("Diesel Demo", Decimal("94.50"), Decimal("15000.00"), "DEMO-DI-20261013"),
)


def seed() -> None:
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE role = 'OWNER' AND is_active = TRUE ORDER BY id LIMIT 1")
        owner = cursor.fetchone()
        if not owner:
            raise RuntimeError("An active owner account is needed to create audited demo data.")

        for name, price, quantity, challan in DEMO_FUELS:
            cursor.execute("SELECT id, stock_litres FROM fuels WHERE name = %s ORDER BY id DESC LIMIT 1", (name,))
            fuel = cursor.fetchone()
            if not fuel:
                cursor.execute("INSERT INTO fuels (name, price, stock_litres) VALUES (%s, %s, %s)", (name, price, Decimal("0.00")))
                fuel = {"id": cursor.lastrowid, "stock_litres": Decimal("0.00")}

            cursor.execute("SELECT id FROM tanker_deliveries WHERE challan_number = %s", (challan,))
            if cursor.fetchone():
                continue

            stock_before = Decimal(fuel["stock_litres"])
            stock_after = stock_before + quantity
            cursor.execute("UPDATE fuels SET stock_litres = %s WHERE id = %s", (stock_after, fuel["id"]))
            cursor.execute(
                """INSERT INTO tanker_deliveries
                (fuel_id, quantity_litres, stock_before_litres, stock_after_litres, received_at, supplier_name, challan_number, notes, created_by)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (fuel["id"], quantity, stock_before, stock_after, datetime(2026, 10, 13, 9),
                 "Tech-E20 Demo Supplier", challan, "Clearly labelled demonstration record", owner["id"]),
            )
            delivery_id = cursor.lastrowid
            cursor.execute(
                """INSERT INTO inventory_transactions
                (fuel_id, transaction_type, quantity_litres, reference_type, reference_id, reason, created_by)
                VALUES (%s, 'DELIVERY', %s, 'TANKER_DELIVERY', %s, %s, %s)""",
                (fuel["id"], quantity, delivery_id, "Demo data for 13-10-2026", owner["id"]),
            )
            cursor.execute(
                """INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, details)
                VALUES (%s, 'DEMO_TANKER_DELIVERY_CREATED', 'tanker_delivery', %s, %s)""",
                (owner["id"], delivery_id, "Demo delivery created for 13-10-2026"),
            )
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    seed()
    print("Demo fuel and tanker-delivery data is present for 13 October 2026.")
