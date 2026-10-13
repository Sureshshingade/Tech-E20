import { useCallback, useEffect, useMemo, useState } from "react";
import "./App.css";

const API_BASE_URL = import.meta.env.VITE_API_URL || "http://127.0.0.1:8000/api";
const TOKEN_KEY = "tech_e20_access_token";
const THEME_KEY = "tech_e20_theme";
const OWNER = "OWNER";

function Icon({ name, size = 20 }) {
  const paths = {
    dashboard: <><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></>,
    fuel: <><path d="M7 21h10" /><path d="M8 21V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v16" /><path d="M8 9h8" /><path d="M16 7h1.5A2.5 2.5 0 0 1 20 9.5v7a2.5 2.5 0 0 0 2 2.45" /></>,
    chart: <><path d="M4 19V5" /><path d="M4 19h17" /><path d="m7 15 4-4 3 2 5-6" /></>,
    people: <><circle cx="9" cy="8" r="3" /><path d="M3 21a6 6 0 0 1 12 0" /><path d="M16 5a3 3 0 0 1 0 6" /><path d="M19 21a5.5 5.5 0 0 0-3-4.92" /></>,
    settings: <><circle cx="12" cy="12" r="3" /><path d="M4 12h16" /><path d="M12 4v16" /></>,
    plus: <><path d="M12 5v14" /><path d="M5 12h14" /></>, refresh: <><path d="M20 11a8 8 0 0 0-14.9-4" /><path d="M4 3v4h4" /><path d="M4 13a8 8 0 0 0 14.9 4" /><path d="M20 21v-4h-4" /></>,
    alert: <><path d="M12 3 2.8 19a1.3 1.3 0 0 0 1.12 2h16.16A1.3 1.3 0 0 0 21.2 19L12 3Z" /><path d="M12 9v4" /><path d="M12 17h.01" /></>, menu: <><path d="M4 7h16" /><path d="M4 12h16" /><path d="M4 17h16" /></>,
    user: <><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></>, logout: <><path d="M10 17l5-5-5-5" /><path d="M15 12H3" /><path d="M21 19V5a2 2 0 0 0-2-2h-5" /></>, edit: <><path d="M12 20h9" /><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L9 17l-4 1 1-4Z" /></>, search: <><circle cx="11" cy="11" r="6" /><path d="m20 20-4.2-4.2" /></>, close: <><path d="m6 6 12 12" /><path d="m18 6-12 12" /></>, lock: <><rect x="4" y="10" width="16" height="11" rx="2" /><path d="M8 10V7a4 4 0 0 1 8 0v3" /></>, eye: <><path d="M2.5 12s3.4-6 9.5-6 9.5 6 9.5 6-3.4 6-9.5 6-9.5-6-9.5-6Z" /><circle cx="12" cy="12" r="2.5" /></>, eyeOff: <><path d="m3 3 18 18" /><path d="M10.6 6.2A10.8 10.8 0 0 1 12 6c6.1 0 9.5 6 9.5 6a17.8 17.8 0 0 1-3.1 3.8" /><path d="M6.2 6.2A17.6 17.6 0 0 0 2.5 12S5.9 18 12 18c1.2 0 2.3-.2 3.3-.6" /><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2" /></>, check: <path d="m5 12 4 4L19 6" />,
  };
  return <svg className="icon" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name]}</svg>;
}

function getErrorMessage(value, fallback = "The request could not be completed.") {
  if (typeof value === "string" && value.trim()) return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);

  if (Array.isArray(value)) {
    const messages = value
      .map((item) => getErrorMessage(item, ""))
      .filter(Boolean);
    return messages.length ? messages.join("; ") : fallback;
  }

  if (value && typeof value === "object") {
    if (typeof value.message === "string" && value.message.trim()) return value.message;
    if (typeof value.error === "string" && value.error.trim()) return value.error;
    if (typeof value.msg === "string" && value.msg.trim()) {
      const location = Array.isArray(value.loc)
        ? value.loc.filter((part) => part !== "body").join(".")
        : "";
      return location ? `${location}: ${value.msg}` : value.msg;
    }
    if ("detail" in value) return getErrorMessage(value.detail, fallback);
  }

  return fallback;
}

async function readResponse(response) {
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(getErrorMessage(body?.detail));
  return body;
}

const PAGES = new Set(["dashboard", "staff", "attendance", "tanks", "nozzles", "shifts", "reconciliation", "reports", "audit", "settings"]);
function getPageFromHash() { const page = window.location.hash.replace("#/", ""); return PAGES.has(page) ? page : "dashboard"; }

function LoginScreen({ onLogin }) {
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username_or_email: identifier, password }),
      });
      const data = await readResponse(response);
      onLogin(data.access_token, data.user);
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to sign in. Please try again."));
    } finally {
      setSubmitting(false);
    }
  }

  return <main className="login-page"><section className="login-card" aria-labelledby="login-heading"><div className="login-brand"><span className="brand-mark"><Icon name="fuel" size={22} /></span><span>Tech-E20</span></div><p className="section-kicker">SECURE OPERATIONS PORTAL</p><h1 id="login-heading">Sign in to Tech-E20</h1><p className="login-copy">Use the account provided by your station owner. Your access is based on your assigned role.</p><form onSubmit={submit}><label htmlFor="identifier">Username or email</label><input id="identifier" value={identifier} onChange={(event) => setIdentifier(event.target.value)} autoComplete="username" required /><label htmlFor="password">Password</label><div className="password-input"><input id="password" type={showPassword ? "text" : "password"} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" required /><button type="button" onClick={() => setShowPassword(!showPassword)} aria-label={showPassword ? "Hide password" : "Show password"}><Icon name={showPassword ? "eyeOff" : "eye"} size={18} /></button></div>{error && <div className="inline-error" role="alert"><Icon name="alert" size={17} />{error}</div>}<button className="primary-button" type="submit" disabled={submitting}><Icon name="lock" size={17} />{submitting ? "Signing in..." : "Sign in securely"}</button></form><p className="login-help">No account yet? Ask the station owner to run the documented one-time owner setup.</p></section></main>;
}

function FeaturePage({ page }) {
  const copy = {
    attendance: ["Calendar & attendance", "View schedules and record attendance by employee and shift."], tanks: ["Fuel & tank management", "Record calibrated tank dip readings, deliveries, and stock adjustments."], nozzles: ["Nozzle readings", "Record opening and closing meter readings by shift."], shifts: ["Shift management", "Plan, open, and close operational shifts."], reconciliation: ["Sales & reconciliation", "Compare calculated sales and actual payment collections."], reports: ["Reports", "Filter database-backed operational reports and export safe CSV files."], audit: ["Audit history", "Inspect authorised changes and their recorded reasons."], settings: ["Settings", "Station settings and access controls."],
  }[page] || ["Tech-E20", "Select a module."];
  return <main className="content-page"><section className="feature-page card"><p className="section-kicker">TECH-E20 OPERATIONS</p><h2>{copy[0]}</h2><p>{copy[1]}</p><div className="feature-note"><Icon name="alert" size={18} />This module is being connected to the new protected operational database schema. Existing login, staff and inventory functions remain available.</div></section></main>;
}

function ThemePicker({ theme, setTheme }) {
  return <div className="theme-picker" aria-label="Colour theme"><span>Theme</span>{[["ocean", "Ocean"], ["midnight", "Midnight"], ["ember", "Ember"]].map(([id, label]) => <button type="button" key={id} className={theme === id ? "selected" : ""} onClick={() => setTheme(id)} aria-pressed={theme === id}>{label}</button>)}</div>;
}

function StationSettings({ request, setNotice, stationName, setStationName }) {
  const [name, setName] = useState(stationName); const [saving, setSaving] = useState(false); const [error, setError] = useState("");
  useEffect(() => setName(stationName), [stationName]);
  async function submit(event) { event.preventDefault(); if (name.trim().length < 2) { setError("Enter a petrol pump name with at least 2 characters."); return; } setSaving(true); setError(""); try { const result = await request("/settings/station", { method: "PUT", body: JSON.stringify({ station_name: name.trim() }) }); setStationName(result.station_name); setNotice({ type: "success", text: "Petrol pump name updated." }); } catch (saveError) { setError(saveError.message || "Could not update the petrol pump name."); } finally { setSaving(false); } }
  return <main className="content-page"><section className="card settings-card"><p className="section-kicker">OWNER SETTINGS</p><h2>Station identity</h2><p className="subtitle">This appears below Tech-E20 throughout the application.</p><form className="fuel-form" onSubmit={submit}><label htmlFor="stationName">Petrol pump name</label><input id="stationName" value={name} onChange={(event) => setName(event.target.value)} maxLength="120" required />{error && <div className="inline-error" role="alert"><Icon name="alert" size={17} />{error}</div>}<button className="primary-button" type="submit" disabled={saving}>{saving ? "Saving..." : "Save petrol pump name"}</button></form></section></main>;
}

function AttendancePage({ request, setNotice }) {
  const [selectedDate, setSelectedDate] = useState(() => new Date().toISOString().slice(0, 10)); const [records, setRecords] = useState([]); const [loading, setLoading] = useState(true); const [editing, setEditing] = useState(false); const [drafts, setDrafts] = useState({}); const [error, setError] = useState(""); const [savingId, setSavingId] = useState(null);
  const load = useCallback(async () => { setLoading(true); setError(""); try { const data = await request(`/attendance?attendance_date=${selectedDate}`); setRecords(data.records); setDrafts(Object.fromEntries(data.records.filter((record) => record.template_id).map((record) => [record.user_id, record.attendance_status === "NOT_MARKED" ? "PRESENT" : record.attendance_status]))); } catch (loadError) { setError(loadError.message || "Attendance could not be loaded."); } finally { setLoading(false); } }, [request, selectedDate]);
  useEffect(() => { load(); }, [load]);
  async function save(record) { const attendanceStatus = drafts[record.user_id]; if (!record.template_id || !attendanceStatus) return; setSavingId(record.user_id); try { await request("/attendance", { method: "PUT", body: JSON.stringify({ user_id: record.user_id, attendance_date: selectedDate, template_id: record.template_id, status: attendanceStatus }) }); setNotice({ type: "success", text: `${record.full_name}'s attendance was saved.` }); await load(); } catch (saveError) { setError(saveError.message || "Attendance could not be saved."); } finally { setSavingId(null); } }
  const morning = records.filter((record) => record.default_shift === "Morning"); const evening = records.filter((record) => record.default_shift === "Evening"); const unassigned = records.filter((record) => !record.default_shift);
  function group(title, staff) { return <section className="card attendance-group"><h2>{title}</h2>{!staff.length ? <p className="empty-inline">No employees assigned to this shift.</p> : staff.map((record) => <div className="attendance-row" key={record.user_id}><div><strong>{record.full_name}</strong><span>@{record.username} · {record.role === "MANAGER" ? "Manager" : "Employee"}</span></div>{editing ? <><select value={drafts[record.user_id] || "PRESENT"} onChange={(event) => setDrafts({ ...drafts, [record.user_id]: event.target.value })}><option value="PRESENT">Present</option><option value="ABSENT">Absent</option><option value="LEAVE">Leave</option></select><button className="edit-button" type="button" onClick={() => save(record)} disabled={savingId === record.user_id}>{savingId === record.user_id ? "Saving..." : "Save"}</button></> : <span className={`attendance-badge ${(record.attendance_status || "NOT_MARKED").toLowerCase().replace("_", "-")}`}>{record.attendance_status === "NOT_MARKED" ? "Not marked" : record.attendance_status}</span>}</div>)}</section>; }
  return <main className="content-page"><section className="page-heading"><div><p className="eyebrow">STAFF OPERATIONS</p><h1>Calendar & attendance</h1><p className="subtitle">Select any current or previous date to review and correct attendance.</p></div><button className="primary-button" type="button" onClick={() => setEditing(!editing)} disabled={loading}>{editing ? "Done editing" : "Edit attendance"}</button></section><section className="attendance-toolbar card"><label htmlFor="attendanceDate">Selected date<input id="attendanceDate" type="date" value={selectedDate} onChange={(event) => { setSelectedDate(event.target.value); setEditing(false); }} /></label><button className="secondary-button" type="button" onClick={load} disabled={loading}><Icon name="refresh" size={17} />Refresh</button><p>{loading ? "Loading attendance…" : records.some((record) => record.attendance_status !== "NOT_MARKED") ? "Recorded attendance is shown below." : "No attendance has been marked for this date yet."}</p></section>{error && <div className="inline-error attendance-error" role="alert"><Icon name="alert" size={17} />{error}</div>}<section className="attendance-grid">{group("Morning shift · 6 AM – 2 PM", morning)}{group("Afternoon / Evening shift · 2 PM – 10 PM", evening)}</section>{unassigned.length > 0 && <section className="card attendance-group"><h2>Shift not assigned</h2><p className="empty-inline">Assign a Morning or Afternoon/Evening shift in Employee Management before marking attendance: {unassigned.map((record) => record.full_name).join(", ")}.</p></section>}</main>;
}

function TankerDeliveries({ request, setNotice }) {
  const [fuels, setFuels] = useState([]); const [deliveries, setDeliveries] = useState([]); const [fuelId, setFuelId] = useState(""); const [quantity, setQuantity] = useState(""); const [supplier, setSupplier] = useState(""); const [challan, setChallan] = useState(""); const [saving, setSaving] = useState(false); const [error, setError] = useState("");
  const load = useCallback(async () => { try { const [fuelData, deliveryData] = await Promise.all([request("/fuels"), request("/inventory/deliveries")]); setFuels(fuelData); setDeliveries(deliveryData); if (!fuelId && fuelData[0]) setFuelId(String(fuelData[0].id)); } catch (loadError) { setError(loadError.message || "Delivery history could not be loaded."); } }, [request, fuelId]);
  useEffect(() => { load(); }, [load]);
  async function submit(event) { event.preventDefault(); if (!fuelId || !Number.isFinite(Number(quantity)) || Number(quantity) <= 0) { setError("Choose a fuel and enter a quantity above zero."); return; } if (!window.confirm("Record this tanker delivery? Recorded stock and the audit trail will be updated.")) return; setSaving(true); setError(""); try { const result = await request("/inventory/deliveries", { method: "POST", body: JSON.stringify({ fuel_id: Number(fuelId), quantity_litres: quantity, received_at: new Date().toISOString(), supplier_name: supplier || null, challan_number: challan || null }) }); setQuantity(""); setSupplier(""); setChallan(""); setNotice({ type: "success", text: `${result.message} Stock is now ${Number(result.stock_after_litres).toLocaleString("en-IN")} L.` }); load(); } catch (saveError) { setError(saveError.message || "Could not record the delivery."); } finally { setSaving(false); } }
  return <main className="content-page"><section className="page-heading"><div><p className="eyebrow">SECURE INVENTORY</p><h1>Fuel & tanker deliveries</h1><p className="subtitle">Owner and Manager can record deliveries. Every receipt retains its before-and-after stock values.</p></div></section><section className="workspace"><article className="card add-card"><div className="section-heading"><p className="section-kicker">TANKER RECEIPT</p><h2>Add delivered stock</h2><p>This updates only the selected fuel’s recorded stock and creates an audit entry.</p></div><form className="fuel-form" onSubmit={submit}><label htmlFor="deliveryFuel">Fuel type</label><select id="deliveryFuel" value={fuelId} onChange={(e) => setFuelId(e.target.value)} required><option value="">Choose fuel</option>{fuels.map((fuel) => <option key={fuel.id} value={fuel.id}>{fuel.name} — current {Number(fuel.stock_litres).toLocaleString("en-IN")} L</option>)}</select><label htmlFor="deliveryQuantity">Delivered quantity (litres)</label><input id="deliveryQuantity" type="number" min="0.01" step="0.01" value={quantity} onChange={(e) => setQuantity(e.target.value)} required /><label htmlFor="deliverySupplier">Supplier (optional)</label><input id="deliverySupplier" maxLength="120" value={supplier} onChange={(e) => setSupplier(e.target.value)} /><label htmlFor="deliveryChallan">Challan / invoice number (optional)</label><input id="deliveryChallan" maxLength="80" value={challan} onChange={(e) => setChallan(e.target.value)} />{error && <div className="inline-error" role="alert"><Icon name="alert" size={17} />{error}</div>}<button className="primary-button" type="submit" disabled={saving}>{saving ? "Recording..." : "Record tanker delivery"}</button></form></article><article className="card records-card"><div className="records-heading"><div><p className="section-kicker">AUDITABLE HISTORY</p><h2>Previous deliveries</h2><p>Previous entries cannot be altered from this screen.</p></div><button className="secondary-button" type="button" onClick={load}><Icon name="refresh" size={17} />Refresh</button></div><div className="table-wrap"><table><thead><tr><th>Received</th><th>Fuel</th><th>Quantity</th><th>Stock change</th><th>Supplier / challan</th><th>Recorded by</th></tr></thead><tbody>{deliveries.map((item) => <tr key={item.id}><td data-label="Received">{new Date(item.received_at).toLocaleString("en-IN")}</td><td data-label="Fuel"><strong>{item.fuel_name}</strong></td><td data-label="Quantity">{Number(item.quantity_litres).toLocaleString("en-IN")} L</td><td data-label="Stock change">{Number(item.stock_before_litres).toLocaleString("en-IN")} → {Number(item.stock_after_litres).toLocaleString("en-IN")} L</td><td data-label="Supplier">{item.supplier_name || "—"}{item.challan_number ? <span className="sub-label">{item.challan_number}</span> : null}</td><td data-label="Recorded by">{item.recorded_by_name}</td></tr>)}{!deliveries.length && <tr><td className="empty-state" colSpan="6">No tanker deliveries have been recorded yet.</td></tr>}</tbody></table></div></article></section></main>;
}

function FuelForm({ fuel, onSaved, onCancel, request }) {
  const [name, setName] = useState(fuel?.name || "Petrol");
  const [price, setPrice] = useState(fuel ? String(fuel.price) : "");
  const [stock, setStock] = useState(fuel ? String(fuel.stock_litres) : "");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const editing = Boolean(fuel);
  async function submit(event) {
    event.preventDefault();
    const priceNumber = Number(price); const stockNumber = Number(stock);
    if (!name.trim() || !Number.isFinite(priceNumber) || priceNumber <= 0 || !Number.isFinite(stockNumber) || stockNumber < 0) { setError("Enter a name, a price above Rs. 0, and stock of 0 litres or more."); return; }
    if (editing && !window.confirm("Save these inventory changes? This action will be recorded in the audit log.")) return;
    setSaving(true); setError("");
    try { await request(editing ? `/fuels/${fuel.id}` : "/fuels", { method: editing ? "PUT" : "POST", body: JSON.stringify({ name: name.trim(), price: priceNumber, stock_litres: stockNumber }) }); onSaved(editing ? "Fuel record updated successfully." : "Fuel record added successfully."); } catch (requestError) { setError(requestError.message || "Could not save this fuel record."); } finally { setSaving(false); }
  }
  return <form className="fuel-form" onSubmit={submit}><label htmlFor="fuelName">Fuel name</label><input id="fuelName" value={name} onChange={(event) => setName(event.target.value)} required maxLength="50" /><label htmlFor="fuelPrice">Rate per litre (Rs.)</label><input id="fuelPrice" type="number" min="0.01" step="0.01" inputMode="decimal" value={price} onChange={(event) => setPrice(event.target.value)} required /><label htmlFor="fuelStock">Recorded stock (litres)</label><input id="fuelStock" type="number" min="0" step="0.01" inputMode="decimal" value={stock} onChange={(event) => setStock(event.target.value)} required />{error && <div className="inline-error" role="alert"><Icon name="alert" size={17} />{error}</div>}<div className="form-actions"><button className="primary-button" type="submit" disabled={saving}>{saving ? "Saving..." : editing ? "Save changes" : "Add fuel record"}</button>{onCancel && <button className="text-button" type="button" onClick={onCancel}>Cancel</button>}</div></form>;
}

function StaffForm({ staffMember, request, onSaved, onCancel }) {
  const editing = Boolean(staffMember);
  const editingOwner = staffMember?.role === OWNER;
  const [username, setUsername] = useState(staffMember?.username || "");
  const [fullName, setFullName] = useState(staffMember?.full_name || "");
  const [email, setEmail] = useState(staffMember?.email || "");
  const [role, setRole] = useState(staffMember?.role || "EMPLOYEE");
  const [defaultShift, setDefaultShift] = useState(staffMember ? (staffMember.default_shift || "") : "Morning");
  const [isActive, setIsActive] = useState(staffMember?.is_active ?? true);
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  async function submit(event) {
    event.preventDefault();
    if (!fullName.trim() || (!editing && username.trim().length < 3)) { setError("Enter a full name and a username with at least 3 characters."); return; }
    if (!editing && password.length < 3) { setError("Set an initial password with at least 3 characters."); return; }
    if (editing && password && password.length < 3) { setError("A reset password must have at least 3 characters."); return; }
    const sensitiveChange = editing && (password || !isActive || role !== staffMember.role || (!editingOwner && defaultShift !== (staffMember.default_shift || "")));
    if (sensitiveChange && !window.confirm("Confirm this staff change. Role, access, and password changes are recorded in the audit log.")) return;
    setSaving(true); setError("");
    try {
      const payload = editing
        ? { username: username.trim(), full_name: fullName.trim(), email: email.trim() || null, ...(!editingOwner ? { role, is_active: isActive, default_shift: defaultShift || null } : {}), ...(password ? { password } : {}) }
        : { username: username.trim(), full_name: fullName.trim(), email: email.trim() || null, password, role, default_shift: defaultShift || null };
      await request(editing ? `/users/${staffMember.id}` : "/users", { method: editing ? "PUT" : "POST", body: JSON.stringify(payload) });
      setPassword("");
      onSaved(editing ? "Staff account updated successfully." : "Staff account created successfully.");
    } catch (requestError) { setError(requestError.message || "Could not save this staff account."); } finally { setSaving(false); }
  }

  return <form className="staff-form" onSubmit={submit}><div className="staff-form-grid"><div><label htmlFor="staffName">Full name</label><input id="staffName" value={fullName} onChange={(event) => setFullName(event.target.value)} required maxLength="100" /></div><div><label htmlFor="staffUsername">Username</label><input id="staffUsername" value={username} onChange={(event) => setUsername(event.target.value)} required minLength="3" maxLength="50" autoComplete="username" /></div><div><label htmlFor="staffEmail">Email (optional)</label><input id="staffEmail" type="email" value={email} onChange={(event) => setEmail(event.target.value)} maxLength="100" /></div><div><label htmlFor="staffRole">Role</label><select id="staffRole" value={role} onChange={(event) => setRole(event.target.value)} disabled={editingOwner}>{editingOwner ? <option value="OWNER">Owner</option> : <><option value="MANAGER">Manager</option><option value="EMPLOYEE">Employee</option></>}</select></div>{!editingOwner && <div><label htmlFor="staffShift">Pump shift</label><select id="staffShift" value={defaultShift} onChange={(event) => setDefaultShift(event.target.value)}><option value="Morning">Morning (6 AM – 2 PM)</option><option value="Evening">Afternoon / Evening (2 PM – 10 PM)</option><option value="">Not assigned yet</option></select></div>}<div className="password-field"><label htmlFor="staffPassword">{editing ? "Reset password (optional)" : "Initial password"}</label><div className="password-input"><input id="staffPassword" type={showPassword ? "text" : "password"} value={password} onChange={(event) => setPassword(event.target.value)} minLength="3" autoComplete="new-password" placeholder={editing ? "Leave blank to keep unchanged" : "At least 3 characters"} required={!editing} /><button type="button" onClick={() => setShowPassword(!showPassword)} aria-label={showPassword ? "Hide password" : "Show password"}><Icon name={showPassword ? "eyeOff" : "eye"} size={18} /></button></div><p>Passwords are sent only for this request and are never displayed or retained.</p></div>{editing && !editingOwner && <label className="toggle-row" htmlFor="staffActive"><input id="staffActive" type="checkbox" checked={isActive} onChange={(event) => setIsActive(event.target.checked)} /><span><strong>Account active</strong><small>Disabled staff cannot sign in.</small></span></label>}</div>{error && <div className="inline-error" role="alert"><Icon name="alert" size={17} />{error}</div>}<div className="form-actions"><button className="primary-button" type="submit" disabled={saving}>{saving ? "Saving..." : editing ? "Save staff changes" : "Create staff account"}</button>{onCancel && <button className="text-button" type="button" onClick={onCancel}>Cancel</button>}</div></form>;
}

function StaffManagement({ request, setNotice }) {
  const [staff, setStaff] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [formMode, setFormMode] = useState(null);
  const loadStaff = useCallback(async () => { setLoading(true); try { setStaff(await request("/users")); } catch (error) { setNotice({ type: "error", text: error.message || "Staff accounts could not be loaded." }); } finally { setLoading(false); } }, [request, setNotice]);
  useEffect(() => { loadStaff(); }, [loadStaff]);
  const visibleStaff = useMemo(() => staff.filter((member) => `${member.full_name} ${member.username} ${member.role}`.toLowerCase().includes(search.toLowerCase())), [staff, search]);
  function saved(message) { setFormMode(null); setNotice({ type: "success", text: message }); loadStaff(); }
  return <main className="content-page" id="staff-management"><section className="page-heading"><div><p className="eyebrow">OWNER ADMINISTRATION</p><h1>Staff management</h1><p className="subtitle">Manage your own profile and all Manager and Employee access securely.</p></div><button className="primary-button" type="button" onClick={() => setFormMode({ type: "create" })}><Icon name="plus" size={17} />Add staff member</button></section><section className="card staff-card"><div className="records-heading"><div><p className="section-kicker">STAFF ACCOUNTS</p><h2>Accounts and access</h2><p>Passwords and password hashes are never shown.</p></div><button className="secondary-button" type="button" onClick={loadStaff} disabled={loading}><Icon name="refresh" size={17} />{loading ? "Loading" : "Refresh"}</button></div><div className="table-controls"><label className="search-field"><Icon name="search" size={17} /><span className="sr-only">Search staff accounts</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search name or username" /></label><span className="staff-count">{loading ? "Loading accounts" : `${staff.length} total account${staff.length === 1 ? "" : "s"}`}</span></div><div className="table-wrap"><table><thead><tr><th>Staff member</th><th>Role</th><th>Status</th><th>Email</th><th><span className="sr-only">Actions</span></th></tr></thead><tbody>{loading && <tr><td className="empty-state" colSpan="5">Loading staff accounts...</td></tr>}{!loading && visibleStaff.map((member) => <tr key={member.id}><td data-label="Staff member"><strong className="fuel-name">{member.full_name}</strong><span className="sub-label">@{member.username}</span></td><td data-label="Role"><span className={`role-badge ${member.role.toLowerCase()}`}>{member.role === "MANAGER" ? "Manager" : member.role === "OWNER" ? "Owner" : "Employee"}</span></td><td data-label="Status"><span className={`status-badge ${member.is_active ? "active" : "inactive"}`}>{member.is_active ? "Active" : "Disabled"}</span></td><td data-label="Email">{member.email || "Not provided"}</td><td className="action-cell"><button className="edit-button" type="button" onClick={() => setFormMode({ type: "edit", member })}><Icon name="edit" size={16} />Edit</button></td></tr>)}{!loading && visibleStaff.length === 0 && <tr><td className="empty-state" colSpan="5">{staff.length ? "No staff accounts match your search." : "No Manager or Employee accounts yet. Add the first staff member."}</td></tr>}</tbody></table></div></section>{formMode && <div className="modal-backdrop" role="presentation"><section className="modal staff-modal" role="dialog" aria-modal="true" aria-labelledby="staff-form-title"><div className="modal-heading"><div><p className="section-kicker">OWNER ADMINISTRATION</p><h2 id="staff-form-title">{formMode.type === "edit" ? "Edit account" : "Add staff member"}</h2></div><button className="icon-button" type="button" onClick={() => setFormMode(null)} aria-label="Close staff form"><Icon name="close" /></button></div><StaffForm staffMember={formMode.member} request={request} onSaved={saved} onCancel={() => setFormMode(null)} /></section></div>}</main>;
}

function Dashboard({ isOwner, request, setNotice }) {
  const [fuels, setFuels] = useState([]); const [loading, setLoading] = useState(true); const [search, setSearch] = useState(""); const [sort, setSort] = useState("name"); const [editingFuel, setEditingFuel] = useState(null);
  const loadFuels = useCallback(async () => { setLoading(true); try { setFuels(await request("/fuels")); } catch (error) { setNotice({ type: "error", text: error.message || "Fuel records could not be loaded." }); } finally { setLoading(false); } }, [request, setNotice]);
  useEffect(() => { loadFuels(); }, [loadFuels]);
  const metrics = useMemo(() => ({ totalStock: fuels.reduce((sum, fuel) => sum + Number(fuel.stock_litres || 0), 0), averagePrice: fuels.length ? fuels.reduce((sum, fuel) => sum + Number(fuel.price || 0), 0) / fuels.length : 0 }), [fuels]);
  const displayedFuels = useMemo(() => fuels.filter((fuel) => fuel.name.toLowerCase().includes(search.toLowerCase())).sort((a, b) => sort === "price" ? Number(b.price) - Number(a.price) : sort === "stock" ? Number(b.stock_litres) - Number(a.stock_litres) : a.name.localeCompare(b.name)), [fuels, search, sort]);
  function saved(message) { setEditingFuel(null); setNotice({ type: "success", text: message }); loadFuels(); }
  return <main><section className="metrics" aria-label="Inventory summary"><article className="metric-card"><div className="metric-icon blue"><Icon name="fuel" /></div><p>Fuel records</p><strong>{loading ? "-" : fuels.length}</strong><span>Types currently listed</span></article><article className="metric-card"><div className="metric-icon teal"><Icon name="dashboard" /></div><p>Recorded stock</p><strong>{loading ? "-" : `${metrics.totalStock.toLocaleString("en-IN", { maximumFractionDigits: 2 })} L`}</strong><span>Combined available quantity</span></article><article className="metric-card"><div className="metric-icon amber"><Icon name="chart" /></div><p>Average listed price</p><strong>{loading ? "-" : `Rs. ${metrics.averagePrice.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}</strong><span>Average per litre</span></article><article className="metric-card muted-metric"><div className="metric-icon slate"><Icon name="alert" /></div><p>Sales today</p><strong>Not available</strong><span>Sales module has not been built yet</span></article></section><section className="workspace">{isOwner && <article className="card add-card"><div className="section-heading"><p className="section-kicker">OWNER ACTION</p><h2>Add fuel record</h2><p>Add a fuel type, its selling rate, and recorded opening stock.</p></div><FuelForm request={request} onSaved={saved} /></article>}<article className="card records-card" id="fuel-records"><div className="records-heading"><div><p className="section-kicker">LIVE DATA</p><h2>Fuel inventory</h2><p>Data returned from the protected MySQL fuel records.</p></div><button className="secondary-button" type="button" onClick={loadFuels} disabled={loading}><Icon name="refresh" size={17} />{loading ? "Loading" : "Refresh"}</button></div><div className="table-controls"><label className="search-field"><Icon name="search" size={17} /><span className="sr-only">Search fuel records</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search fuel type" /></label><label className="sort-field">Sort by<select value={sort} onChange={(event) => setSort(event.target.value)}><option value="name">Name</option><option value="price">Highest price</option><option value="stock">Highest stock</option></select></label></div><div className="table-wrap"><table><thead><tr><th>Fuel type</th><th>Rate / litre</th><th>Recorded stock</th><th>Record ID</th>{isOwner && <th><span className="sr-only">Actions</span></th>}</tr></thead><tbody>{loading && <tr><td className="empty-state" colSpan={isOwner ? "5" : "4"}>Loading fuel records...</td></tr>}{!loading && displayedFuels.map((fuel) => <tr key={fuel.id}><td data-label="Fuel type"><span className="fuel-name">{fuel.name}</span></td><td data-label="Rate / litre">Rs. {Number(fuel.price).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td><td data-label="Recorded stock"><strong>{Number(fuel.stock_litres || 0).toLocaleString("en-IN", { maximumFractionDigits: 2 })} L</strong></td><td data-label="Record ID">#{fuel.id}</td>{isOwner && <td className="action-cell"><button className="edit-button" type="button" onClick={() => setEditingFuel(fuel)}><Icon name="edit" size={16} />Edit</button></td>}</tr>)}{!loading && displayedFuels.length === 0 && <tr><td className="empty-state" colSpan={isOwner ? "5" : "4"}>{fuels.length ? "No fuel records match your search." : "No fuel records have been saved yet."}</td></tr>}</tbody></table></div><p className="data-note">Scope: inventory records only. Revenue, sales, and low-stock alerts remain unavailable until their database-backed modules are implemented.</p></article></section>{editingFuel && <div className="modal-backdrop" role="presentation"><section className="modal" role="dialog" aria-modal="true" aria-labelledby="edit-title"><div className="modal-heading"><div><p className="section-kicker">OWNER ACTION</p><h2 id="edit-title">Edit fuel record</h2></div><button className="icon-button" type="button" onClick={() => setEditingFuel(null)} aria-label="Close edit form"><Icon name="close" /></button></div><FuelForm fuel={editingFuel} request={request} onSaved={saved} onCancel={() => setEditingFuel(null)} /></section></div>}</main>;
}

function App() {
  const [token, setToken] = useState(() => sessionStorage.getItem(TOKEN_KEY)); const [user, setUser] = useState(null); const [notice, setNotice] = useState(null); const [page, setPage] = useState(getPageFromHash); const [menuOpen, setMenuOpen] = useState(false);
  const [theme, setTheme] = useState(() => localStorage.getItem(THEME_KEY) || "ocean");
  const [stationName, setStationName] = useState("My Petrol Pump");
  const isOwner = user?.role === OWNER;
  const canManageAttendance = isOwner || user?.role === "MANAGER";
  const clearSession = useCallback((message = "Your session has ended. Please sign in again.") => { sessionStorage.removeItem(TOKEN_KEY); setToken(null); setUser(null); setNotice({ type: "error", text: message }); }, []);
  const request = useCallback(async (path, options = {}) => { const response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", ...options.headers } }); if (response.status === 401) { clearSession(); throw new Error("Your session has ended. Please sign in again."); } return readResponse(response); }, [token, clearSession]);
  useEffect(() => { const updatePage = () => setPage(getPageFromHash()); window.addEventListener("hashchange", updatePage); return () => window.removeEventListener("hashchange", updatePage); }, []);
  useEffect(() => { if (!token) return; request("/auth/me").then(setUser).catch(() => {}); }, [token, request]);
  useEffect(() => { if (!token) return; request("/settings/station").then((settings) => setStationName(settings.station_name)).catch(() => {}); }, [token, request]);
  useEffect(() => { document.documentElement.dataset.theme = theme; localStorage.setItem(THEME_KEY, theme); }, [theme]);
  useEffect(() => { if (user && page === "staff" && !isOwner) { window.location.hash = "#/dashboard"; setNotice({ type: "error", text: "Staff management is available only to the owner." }); } }, [user, page, isOwner]);
  function navigate(nextPage) { setNotice(null); window.location.hash = `#/${nextPage}`; setMenuOpen(false); }
  function onLogin(newToken, profile) { sessionStorage.setItem(TOKEN_KEY, newToken); setToken(newToken); setUser(profile); setNotice({ type: "success", text: `Welcome back, ${profile.full_name}.` }); }
  async function logout() { try { await request("/auth/logout", { method: "POST" }); } catch { /* Clear this browser session even if the request cannot finish. */ } finally { clearSession("You have signed out securely."); } }
  if (!token || !user) return <LoginScreen onLogin={onLogin} />;
  const staffPage = page === "staff" && isOwner;
  const navigation = [{ id: "dashboard", label: "Dashboard", icon: "dashboard" }, ...(isOwner ? [{ id: "staff", label: "Employee management", icon: "people" }] : []), ...(canManageAttendance ? [{ id: "attendance", label: "Calendar & attendance", icon: "people" }] : []), { id: "tanks", label: "Fuel & tanks", icon: "fuel" }, { id: "nozzles", label: "Nozzle readings", icon: "fuel" }, { id: "shifts", label: "Shift management", icon: "dashboard" }, { id: "reconciliation", label: "Sales & reconciliation", icon: "chart" }, ...(isOwner || user.role === "MANAGER" ? [{ id: "reports", label: "Reports", icon: "chart" }] : []), ...(isOwner ? [{ id: "audit", label: "Audit history", icon: "chart" }, { id: "settings", label: "Settings", icon: "settings" }] : [])];
  const heading = staffPage ? ["OWNER ADMINISTRATION", "Manage your station staff", "Control Manager and Employee account access securely."] : ["TECH-E20 OPERATIONS", page === "dashboard" ? `Welcome, ${user.full_name.split(" ")[0]}` : navigation.find((item) => item.id === page)?.label || "Tech-E20", "Secure, role-aware station operations."];
  const content = staffPage ? <StaffManagement request={request} setNotice={setNotice} /> : page === "dashboard" ? <Dashboard isOwner={isOwner} request={request} setNotice={setNotice} /> : page === "attendance" && canManageAttendance ? <AttendancePage request={request} setNotice={setNotice} /> : page === "tanks" ? <TankerDeliveries request={request} setNotice={setNotice} /> : page === "settings" && isOwner ? <StationSettings request={request} setNotice={setNotice} stationName={stationName} setStationName={setStationName} /> : <FeaturePage page={page} />;
  return <div className="app-shell"><aside className={`sidebar ${menuOpen ? "is-open" : ""}`} aria-label="Primary navigation"><div className="brand"><span className="brand-mark"><Icon name="fuel" size={22} /></span><span>Tech-E20<small>{stationName}</small></span></div><nav>{navigation.map((item) => <button key={item.id} className={`nav-item ${page === item.id ? "active" : ""}`} type="button" onClick={() => navigate(item.id)}><Icon name={item.icon} />{item.label}</button>)}</nav><div className="sidebar-user"><Icon name="user" size={18} /><div><strong>{user.full_name}</strong><span>{user.role}</span></div><button type="button" className="icon-button" onClick={logout} aria-label="Sign out"><Icon name="logout" size={18} /></button></div></aside><div className="page-content"><header className="topbar"><button className="menu-button" type="button" onClick={() => setMenuOpen(!menuOpen)} aria-label="Toggle navigation" aria-expanded={menuOpen}><Icon name="menu" /></button><div><p className="eyebrow">{heading[0]}</p><h1>{heading[1]}</h1><p className="subtitle">{heading[2]}</p></div><div className="topbar-tools"><ThemePicker theme={theme} setTheme={setTheme} /><div className="topbar-status"><span className="status-dot" />Signed in as {user.role}</div></div></header>{notice && <div className={`notice page-notice ${notice.type}`} role="status"><Icon name={notice.type === "error" ? "alert" : "check"} size={18} /><span>{notice.text}</span><button className="notice-close" onClick={() => setNotice(null)} aria-label="Dismiss message"><Icon name="close" size={16} /></button></div>}{content}<footer className="developer-credit">Built by <strong>Suresh Shingade</strong> · <a href="mailto:sureshshingade38700@gmail.com?subject=Web%20application%20development%20enquiry">Contact for web application development</a> · <a href="https://portfolio-chi-six-67.vercel.app/" target="_blank" rel="noreferrer">Portfolio</a></footer></div></div>;
}

export default App;
