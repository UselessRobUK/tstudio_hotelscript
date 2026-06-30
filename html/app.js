// ── state ──────────────────────────────────────────────────────────
let currentHotel   = null;
let currentRooms   = [];
let isBoss         = false;
let pendingRentId  = null;
let pendingFineId  = null;

// ── NUI helper ─────────────────────────────────────────────────────
function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method:  "POST",
        headers: { "Content-Type": "application/json" },
        body:    JSON.stringify(data),
    });
}

// ── utils ──────────────────────────────────────────────────────────
function formatExpiry(ts) {
    const diff = ts - Math.floor(Date.now() / 1000);
    if (diff <= 0) return "Expired";
    const h = Math.floor(diff / 3600);
    const m = Math.floor((diff % 3600) / 60);
    return h > 0 ? `${h}h ${m}m remaining` : `${m}m remaining`;
}

function shortId(id) {
    const parts = id.split(":");
    const val   = parts[parts.length - 1] || id;
    return val.slice(-8).toUpperCase();
}

function escHtml(str) {
    return String(str)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
}

// ── open / close ───────────────────────────────────────────────────
function openApp() {
    document.getElementById("app").classList.remove("hidden");
}

function closeApp() {
    document.getElementById("app").classList.add("hidden");
    post("close");
    isBoss       = false;
    currentHotel = null;
    currentRooms = [];
    hideBossMenu();
}

function hideBossMenu() {
    document.querySelectorAll(".boss-only").forEach(el => el.classList.add("hidden"));
}

function showBossMenu() {
    document.querySelectorAll(".boss-only").forEach(el => el.classList.remove("hidden"));
}

// ── page nav ───────────────────────────────────────────────────────
function setPage(name) {
    document.querySelectorAll(".menu").forEach(b => b.classList.remove("active"));
    document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));

    const btn  = document.querySelector(`.menu[data-page="${name}"]`);
    const page = document.getElementById(name);
    if (btn)  btn.classList.add("active");
    if (page) page.classList.add("active");
}

document.querySelectorAll(".menu").forEach(btn => {
    btn.addEventListener("click", () => setPage(btn.dataset.page));
});

// ── boss sub-tabs ──────────────────────────────────────────────────
document.querySelectorAll(".boss-tab").forEach(btn => {
    btn.addEventListener("click", () => {
        document.querySelectorAll(".boss-tab").forEach(b => b.classList.remove("active"));
        document.querySelectorAll(".boss-panel").forEach(p => p.classList.remove("active"));
        btn.classList.add("active");
        document.getElementById(btn.dataset.btab).classList.add("active");
    });
});

// ── room search ────────────────────────────────────────────────────
document.getElementById("roomSearch").addEventListener("input", e => {
    const q = e.target.value.toLowerCase();
    renderRooms(currentRooms.filter(r =>
        (r.label || `Room ${r.id}`).toLowerCase().includes(q)
    ));
});

// ── render rooms ───────────────────────────────────────────────────
function renderRooms(rooms) {
    const grid = document.getElementById("roomGrid");
    grid.innerHTML = "";

    if (!rooms.length) {
        grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1">
            <span class="empty-icon">🏠</span><p>No rooms found.</p>
        </div>`;
        return;
    }

    rooms.forEach(room => {
        const mine     = !!room.myRoom;
        const occupied = !room.available && !mine;
        const floor    = Math.floor(room.id / 100);

        let badgeHtml = "";
        let cardClass = "available";
        if (mine) {
            badgeHtml = `<span class="badge badge-mine">Your Room</span>`;
            cardClass = "mine";
        } else if (occupied) {
            badgeHtml = `<span class="badge badge-occupied">Occupied</span>`;
            cardClass = "occupied";
        } else {
            badgeHtml = `<span class="badge badge-available">Available</span>`;
        }

        let stateHtml = "";
        if (room.state && room.state !== "clean") {
            stateHtml = `<span class="badge badge-dirty" style="margin-left:4px">${escHtml(room.state)}</span>`;
        }

        let expiryHtml = "";
        if (mine && room.expires) {
            expiryHtml = `<p class="room-expiry">${formatExpiry(room.expires)}</p>`;
        }

        let actionsHtml = "";
        if (!occupied && !mine) {
            actionsHtml = `<div class="room-actions">
                <button class="action" data-rent="${room.id}">Book Room</button>
            </div>`;
        }

        const card = document.createElement("div");
        card.className = `room-card ${cardClass}`;
        card.innerHTML = `
            <div class="room-card-header">
                <h3>${escHtml(room.label || `Room ${room.id}`)}</h3>
                <div>${badgeHtml}${stateHtml}</div>
            </div>
            <p class="room-floor">Floor ${floor}</p>
            <p class="price">$${room.price}<span style="font-size:12px;font-weight:400;color:#7878a0"> / ${room.duration}h</span></p>
            ${expiryHtml}
            ${actionsHtml}
        `;
        grid.appendChild(card);
    });
}

// ── render my booking ──────────────────────────────────────────────
function renderBooking(rooms) {
    const container = document.getElementById("bookingContent");
    const myRoom    = rooms.find(r => r.myRoom);

    if (!myRoom) {
        container.innerHTML = `<div class="empty-state">
            <span class="empty-icon">🛏️</span>
            <p>You don't have an active booking.</p>
        </div>`;
        return;
    }

    const floor = Math.floor(myRoom.id / 100);
    container.innerHTML = `<div class="my-room-panel">
        <h3>${escHtml(myRoom.label || `Room ${myRoom.id}`)}</h3>
        <p>Floor ${floor}</p>
        <p>$${myRoom.price} / ${myRoom.duration}h stay</p>
        ${myRoom.expires ? `<p class="expiry-label">⏱ ${formatExpiry(myRoom.expires)}</p>` : ""}
    </div>`;
}

// ── rent modal ─────────────────────────────────────────────────────
document.getElementById("roomGrid").addEventListener("click", e => {
    const rentId = e.target.dataset.rent;
    if (!rentId) return;

    const room = currentRooms.find(r => r.id === Number(rentId));
    if (!room) return;

    pendingRentId = room.id;
    document.getElementById("modalRoomName").textContent  = room.label || `Room ${room.id}`;
    document.getElementById("modalRoomPrice").textContent = `$${room.price}`;
    document.getElementById("modalRoomDuration").textContent = `${room.duration}-hour stay · non-refundable`;
    document.getElementById("rentModal").classList.remove("hidden");
});

document.getElementById("confirmRent").addEventListener("click", () => {
    if (pendingRentId == null) return;
    post("rentRoom", {
        roomId:  pendingRentId,
        payment: document.getElementById("paymentMethod").value || "cash",
    });
    document.getElementById("rentModal").classList.add("hidden");
    pendingRentId = null;
});

document.getElementById("cancelRent").addEventListener("click", () => {
    document.getElementById("rentModal").classList.add("hidden");
    pendingRentId = null;
});

// ── complaints (guest) ─────────────────────────────────────────────
document.getElementById("submitComplaint").addEventListener("click", () => {
    const message  = document.getElementById("complaintText").value.trim();
    const category = document.getElementById("complaintCategory").value;
    if (!message) return;

    const myRoom = currentRooms.find(r => r.myRoom);
    post("submitComplaint", { message, category, roomId: myRoom?.id });

    document.getElementById("complaintText").value = "";
    const success = document.getElementById("complaintSuccess");
    success.classList.remove("hidden");
    setTimeout(() => success.classList.add("hidden"), 3500);
});

// ── boss: render ───────────────────────────────────────────────────
function renderBoss(data) {
    const dashboard = data.dashboard || {};

    document.getElementById("revenue").textContent       = `$${(dashboard.revenue || 0).toLocaleString()}`;
    document.getElementById("occupiedRooms").textContent = dashboard.activeRooms || 0;
    const open = (dashboard.complaints || []).filter(c => c.status !== "resolved").length;
    document.getElementById("complaintCount").textContent = open;

    renderBossRooms(dashboard.rooms || [], dashboard.tenants || []);
    renderBossTenants(dashboard.tenants || [], dashboard.rooms || []);
    renderBossComplaints(dashboard.complaints || []);
}

function getRoomLabel(rooms, roomId) {
    const r = rooms.find(r => r.id === Number(roomId));
    return r ? (r.label || `Room ${r.id}`) : `Room ${roomId}`;
}

// ── boss: rooms tab ────────────────────────────────────────────────
function renderBossRooms(rooms, tenants) {
    const panel = document.getElementById("bossRooms");
    if (!rooms.length) {
        panel.innerHTML = `<div class="empty-state"><span class="empty-icon">🏠</span><p>No rooms.</p></div>`;
        return;
    }

    panel.innerHTML = rooms.map(room => {
        const tenant  = tenants.find(t => Number(t.room) === room.id);
        const occupied = !!tenant;
        const statusBadge = occupied
            ? `<span class="badge badge-occupied">Occupied</span>`
            : `<span class="badge badge-available">Free</span>`;
        const tenantRow = tenant
            ? `<div class="list-item-sub">Tenant: ${shortId(tenant.identifier)} · ${formatExpiry(tenant.expires)}</div>`
            : `<div class="list-item-sub">Vacant</div>`;
        const evictBtn = tenant
            ? `<button class="danger" style="padding:5px 12px;border-radius:8px;font-family:inherit;font-size:11px;font-weight:700;cursor:pointer;text-transform:uppercase;letter-spacing:.4px;transition:all .18s ease" data-evict="${escHtml(tenant.identifier)}">Evict</button>`
            : "";

        return `<div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${escHtml(room.label || `Room ${room.id}`)}</span>
                <div style="display:flex;gap:5px;align-items:center">
                    <span style="font-size:11px;color:#7878a0">$${room.price}/${room.duration}h</span>
                    ${statusBadge}
                </div>
            </div>
            ${tenantRow}
            <div class="list-item-actions">
                <button class="secondary" style="padding:5px 12px;border-radius:8px;font-family:inherit;font-size:11px;font-weight:700;cursor:pointer;text-transform:uppercase;letter-spacing:.4px;border:1px solid rgba(255,255,255,.1);background:rgba(255,255,255,.07);color:#aaa;transition:all .18s ease" data-editprice="${room.id}" data-currentprice="${room.price}">Edit Price</button>
                ${evictBtn}
            </div>
            <div id="priceedit-${room.id}" class="price-edit-row hidden">
                <input type="number" id="priceinput-${room.id}" placeholder="New price" value="${room.price}">
                <button class="action" style="flex:0;padding:5px 14px;height:36px" data-saveprice="${room.id}">Save</button>
                <button class="secondary" style="flex:0;padding:5px 14px;height:36px;border:1px solid rgba(255,255,255,.1);background:rgba(255,255,255,.07);color:#aaa" data-cancelprice="${room.id}">✕</button>
            </div>
        </div>`;
    }).join("");
}

// ── boss: tenants tab ──────────────────────────────────────────────
function renderBossTenants(tenants, rooms) {
    const panel = document.getElementById("bossTenants");
    if (!tenants.length) {
        panel.innerHTML = `<div class="empty-state"><span class="empty-icon">👤</span><p>No active tenants.</p></div>`;
        return;
    }

    panel.innerHTML = tenants.map(t => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${getRoomLabel(rooms, t.room)}</span>
                <span class="badge badge-available">${formatExpiry(t.expires)}</span>
            </div>
            <div class="list-item-sub">ID: ${shortId(t.identifier)}</div>
            <div class="list-item-actions">
                <button class="warn" style="padding:5px 12px;border-radius:8px;font-family:inherit;font-size:11px;font-weight:700;cursor:pointer;text-transform:uppercase;letter-spacing:.4px;background:rgba(245,158,11,.15);color:#f59e0b;border:1px solid rgba(245,158,11,.3);transition:all .18s ease" data-fine="${escHtml(t.identifier)}">Fine</button>
                <button class="danger" style="padding:5px 12px;border-radius:8px;font-family:inherit;font-size:11px;font-weight:700;cursor:pointer;text-transform:uppercase;letter-spacing:.4px;transition:all .18s ease" data-evict="${escHtml(t.identifier)}">Evict</button>
            </div>
        </div>
    `).join("");
}

// ── boss: complaints tab ───────────────────────────────────────────
function renderBossComplaints(complaints) {
    const panel = document.getElementById("bossComplaints");
    if (!complaints.length) {
        panel.innerHTML = `<div class="empty-state"><span class="empty-icon">✅</span><p>No complaints on record.</p></div>`;
        return;
    }

    const open     = complaints.filter(c => c.status !== "resolved");
    const resolved = complaints.filter(c => c.status === "resolved");

    let html = "";
    if (open.length) {
        html += `<p style="font-size:10px;font-weight:800;color:#3e3e60;text-transform:uppercase;letter-spacing:1px;margin:0 0 10px">Open (${open.length})</p>`;
        html += open.map(c => complaintRowHtml(c, true)).join("");
    }
    if (resolved.length) {
        html += `<p style="font-size:10px;font-weight:800;color:#3e3e60;text-transform:uppercase;letter-spacing:1px;margin:16px 0 10px">Resolved (${resolved.length})</p>`;
        html += resolved.map(c => complaintRowHtml(c, false)).join("");
    }
    panel.innerHTML = html;
}

function complaintRowHtml(c, showResolve) {
    const badge = c.status === "resolved"
        ? `<span class="badge badge-resolved">Resolved</span>`
        : `<span class="badge badge-open">Open</span>`;
    const resolveBtn = showResolve
        ? `<button class="action" style="flex:0;padding:5px 14px;height:32px;font-size:11px;font-family:inherit" data-resolve="${c.id}">Resolve</button>`
        : "";
    const meta = [
        c.identifier ? `ID: ${shortId(c.identifier)}` : null,
        c.room       ? `Room ${c.room}` : null,
        c.created_at ? new Date(c.created_at * 1000).toLocaleDateString() : null,
    ].filter(Boolean).join(" · ");

    return `<div class="complaint-row${c.status === 'resolved' ? ' resolved' : ''}">
        <div class="complaint-row-header">
            <span class="complaint-row-title">${escHtml(c.category || "General")}</span>
            ${badge}
        </div>
        <p class="complaint-row-body">${escHtml(c.message)}</p>
        <div style="display:flex;align-items:center;justify-content:space-between">
            <span class="complaint-row-meta">${escHtml(meta)}</span>
            ${resolveBtn}
        </div>
    </div>`;
}

// ── boss action delegation ─────────────────────────────────────────
document.getElementById("boss").addEventListener("click", e => {
    // Evict
    const evictId = e.target.dataset.evict;
    if (evictId) { post("bossEvict", { identifier: evictId }); return; }

    // Fine — open modal
    const fineId = e.target.dataset.fine;
    if (fineId) {
        pendingFineId = fineId;
        document.getElementById("fineTargetLabel").textContent = `Tenant: ${shortId(fineId)}`;
        document.getElementById("fineAmount").value = "";
        document.getElementById("fineReason").value = "";
        document.getElementById("fineModal").classList.remove("hidden");
        return;
    }

    // Edit price — show inline row
    const editPriceId = e.target.dataset.editprice;
    if (editPriceId) {
        document.getElementById(`priceedit-${editPriceId}`).classList.remove("hidden");
        return;
    }

    // Cancel price edit
    const cancelPriceId = e.target.dataset.cancelprice;
    if (cancelPriceId) {
        document.getElementById(`priceedit-${cancelPriceId}`).classList.add("hidden");
        return;
    }

    // Save price
    const savePriceId = e.target.dataset.saveprice;
    if (savePriceId) {
        const val = parseFloat(document.getElementById(`priceinput-${savePriceId}`).value);
        if (!isNaN(val) && val >= 0) {
            post("bossChangePrice", { roomId: Number(savePriceId), price: val });
        }
        document.getElementById(`priceedit-${savePriceId}`).classList.add("hidden");
        return;
    }

    // Resolve complaint
    const resolveId = e.target.dataset.resolve;
    if (resolveId) {
        post("resolveComplaint", { id: Number(resolveId) });
        // Optimistically mark resolved
        const row = e.target.closest(".complaint-row");
        if (row) {
            row.classList.add("resolved");
            row.querySelector(".badge").className = "badge badge-resolved";
            row.querySelector(".badge").textContent = "Resolved";
            e.target.remove();
        }
    }
});

// ── fine modal ─────────────────────────────────────────────────────
document.getElementById("confirmFine").addEventListener("click", () => {
    if (!pendingFineId) return;
    const amount = parseFloat(document.getElementById("fineAmount").value);
    const reason = document.getElementById("fineReason").value.trim() || "Hotel fine";
    if (isNaN(amount) || amount <= 0) return;
    post("bossFine", { identifier: pendingFineId, amount, reason });
    document.getElementById("fineModal").classList.add("hidden");
    pendingFineId = null;
});
document.getElementById("cancelFine").addEventListener("click", () => {
    document.getElementById("fineModal").classList.add("hidden");
    pendingFineId = null;
});

// ── close button ───────────────────────────────────────────────────
document.getElementById("closeButton").addEventListener("click", closeApp);

window.addEventListener("keydown", e => {
    if (e.key === "Escape") closeApp();
});

// ── NUI messages ───────────────────────────────────────────────────
window.addEventListener("message", event => {
    const msg  = event.data;
    const data = msg.data || {};

    if (msg.action === "openHotel") {
        isBoss        = false;
        currentHotel  = data.hotel;
        currentRooms  = data.rooms || [];
        document.getElementById("hotelName").textContent    = data.hotelName || data.hotel || "Hotel";
        document.getElementById("hotelSubtitle").textContent = "Premium Accommodation";
        hideBossMenu();
        renderRooms(currentRooms);
        renderBooking(currentRooms);
        setPage("rooms");
        openApp();
        return;
    }

    if (msg.action === "openBoss") {
        isBoss       = true;
        currentHotel = data.hotel;
        currentRooms = data.dashboard?.rooms || [];
        document.getElementById("hotelName").textContent    = data.hotelName || data.hotel || "Hotel";
        document.getElementById("hotelSubtitle").textContent = "Management Console";
        showBossMenu();
        renderBoss(data);
        setPage("boss");
        openApp();
        return;
    }

    if (msg.action === "openComplaints") {
        isBoss       = true;
        currentHotel = data.hotel;
        document.getElementById("hotelName").textContent    = data.hotelName || data.hotel || "Hotel";
        document.getElementById("hotelSubtitle").textContent = "Complaints Management";
        showBossMenu();
        renderBossComplaints(data.complaints || []);
        // Show boss page with complaints tab active
        document.querySelectorAll(".boss-tab").forEach(b => b.classList.remove("active"));
        document.querySelectorAll(".boss-panel").forEach(p => p.classList.remove("active"));
        document.querySelector('[data-btab="bossComplaints"]').classList.add("active");
        document.getElementById("bossComplaints").classList.add("active");
        setPage("boss");
        openApp();
        return;
    }

    if (msg.action === "updateRooms") {
        currentRooms = data.rooms || [];
        renderRooms(currentRooms);
        renderBooking(currentRooms);
        return;
    }

    if (msg.action === "close") {
        document.getElementById("app").classList.add("hidden");
    }
});
