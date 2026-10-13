# Tech-E20: Product Requirements and Delivery Plan

## Product scope

Tech-E20 is a mobile-first operating system for a **single-location Indian petrol pump**. It helps the owner, manager, and pump operators safely record fuel operations without confusing sales revenue, collections, stock, or profit.

The first release supports Petrol and Diesel and keeps the data model open for future fuel types, pumps, and nozzles. It records money in Indian Rupees (for example, `₹1,25,000.00`), volume in litres, and dates/times in `DD-MM-YYYY` and IST.

## Staff workflow

The employee workflow is deliberately short and phone-friendly:

1. Log in.
2. Start an assigned shift.
3. Enter the opening meter reading for an assigned nozzle.
4. Record sales with Cash, UPI, or Card as the payment method.
5. Enter the closing meter reading.
6. Review the calculated litres, collection totals, and submit the shift for review.

Tech-E20 calculates `litres sold = closing reading - opening reading` and `sale amount = litres sold × saved rate per litre`. It rejects a closing reading below its opening reading, duplicate submissions, and silent changes to completed financial records.

## Experience and terminology

- Simple English, large touch targets, and minimal typing for 320–375 px screens.
- Deep navy, soft neutral backgrounds, green success states, amber warnings, and red errors.
- Accessible focus states, clear validation, loading and empty states, confirmation before financial submissions, and restrained motion.
- Use pump-staff terminology: **Nozzle**, **Opening Meter Reading**, **Closing Meter Reading**, **Litres Sold**, **Rate per Litre**, **Shift Closing**, **Cash Collection**, **UPI Collection**, and **Reconciliation**.
- UI must never present fake statistics or non-functional controls.

## Roles and enforced permissions

Backend authorization—not only frontend visibility—will enforce this matrix.

| Major action | Owner | Manager | Employee |
| --- | :---: | :---: | :---: |
| View business-wide dashboard and reports | Yes | Operational view | Own shift view |
| Manage owner accounts, roles, and critical settings | Yes | No | No |
| Manage employees | Yes | Assigned permissions only | No |
| Set fuel price and adjust inventory | Yes | View/report only initially | No |
| Record meter readings and sales | Yes | Yes | Own assigned shift only |
| Review reconciliations | Yes | Yes | View own status only |
| Approve own reconciliation | No | No | No |
| View audit logs | Yes | Relevant operational alerts | No |

## Financial and reporting rules

Cash, UPI, and Card are recorded payment methods only; the app will never store UPI PINs, card numbers, or CVVs. Reports will distinguish:

- **Sales revenue**: completed sale amounts.
- **Collections**: payments recorded by method.
- **Inventory/stock**: litres available and stock movements.
- **Profit**: shown only after valid cost and expense data exists.

Planned reports include daily and date-range sales, fuel-wise and employee/shift-wise sales, payment totals, meter readings, stock movements, low-stock history, and expected-versus-actual reconciliations with CSV export.

## Tech-E20 Intelligence (later milestone)

Tech-E20 Intelligence is explainable, rule-based operational assistance—not a claim of AI or proof of wrongdoing. It will flag unusual meter changes, likely duplicates, unexplained stock changes, payment variances, low stock, and unclosed shifts. Every alert will state the record involved, the rule that detected it, and a recommended human next action.

## Delivery milestones

1. **Foundation and dashboard — complete**: preserve fuel records and provide a responsive, database-backed inventory dashboard.
2. **Backend authentication foundation — complete**: repaired Python tooling, moved database credentials to environment variables, added additive user/audit migrations, Argon2 password hashing, JWT login/logout, token revocation, and role dependencies. Existing fuel routes now require authentication; all roles may read fuel data while only the owner may change it.
3. **Authenticated inventory UI — complete**: login screen, bearer-token API requests, protected dashboard state, role display, sign-out, session-expiry handling, searchable/sortable inventory, and owner-only add/edit controls.
4. **Owner user management API — complete**: owner-only endpoints create and manage manager/employee accounts, preserve password secrecy, block additional owner creation, and audit account changes.
5. **Owner staff-management UI — complete**: owner-only hash-routed screen lists, creates, edits, enables/disables, changes roles, and resets Manager/Employee account passwords through the existing protected APIs.
6. **Manager and employee workspaces — next**: add role-specific operations once their backend workflows exist.
7. **Inventory ledger**: auditable receipts, stock adjustments, price history, and low-stock thresholds.
8. **Nozzles, shifts, and sales**: meter validation, decimal calculations, sales snapshots, and payment recording.
9. **Reconciliation and audit workflow**: shift closing, manager review, collection differences, and immutable audit events.
10. **Reports and Intelligence**: filters, CSV exports, and explainable alert rules.
11. **Quality and demonstration**: API/frontend tests, responsive/accessibility checks, backup/recovery instructions, and a verified demonstration script.

## Authentication foundation: prerequisites

Before Milestone 2 code changes begin:

- MySQL must be reachable and backed up.
- The Python environment must work with FastAPI, MySQL Connector, a password hashing package, and JWT support.
- A `.env.example` must contain placeholders only; real credentials remain outside source control.
- Migrations must be additive and idempotent: existing `fuels` rows are preserved.

Current environment check on 12-10-2026:

- MySQL 8.0.45 is running, `fuel_station_db` exists, and `fuels` has 7 rows with `id`, `name`, `price DECIMAL(10,2)`, and `stock_litres DECIMAL(10,2)`.
- `backend/venv` was repaired using Python 3.12.14 and now runs FastAPI, MySQL Connector, Argon2 password hashing, JWT support, and pytest.
