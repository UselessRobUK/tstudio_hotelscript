const app = document.getElementById("app");
const closeButton = document.getElementById("closeButton");
const roomGrid = document.getElementById("roomGrid");
const hotelName = document.getElementById("hotelName");
const paymentMethod = document.getElementById("paymentMethod");

let currentHotel = null;
let currentRooms = [];

function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(data)
    });
}

function openApp(data) {
    currentHotel = data.hotel;
    currentRooms = data.rooms || [];

    hotelName.textContent = data.hotelName || data.hotel || "Hotel";

    renderRooms(currentRooms);

    app.classList.remove("hidden");
}

function closeApp() {
    app.classList.add("hidden");
    post("close");
}

function renderRooms(rooms) {
    roomGrid.innerHTML = "";

    rooms.forEach(room => {
        const card = document.createElement("div");
        card.className = "room-card";

        const floor = Math.floor(room.id / 100);

        card.innerHTML = `
            <h3>${room.label || `Room ${room.id}`}</h3>
            <p class="room-floor">Floor ${floor}</p>
            <p>Price: £${room.price || 0}</p>
            <p>Duration: ${room.duration || 24} hours</p>

            <div class="room-actions">
                <button class="action" data-rent="${room.id}">Rent</button>
            </div>
        `;

        roomGrid.appendChild(card);
    });
}

document.addEventListener("click", e => {
    const rent = e.target.dataset.rent;

    if (rent) {
        post("rentRoom", {
            roomId: Number(rent),
            payment: paymentMethod.value || "cash"
        });
    }
});

document.querySelectorAll(".menu").forEach(button => {
    button.addEventListener("click", () => {
        document.querySelectorAll(".menu").forEach(b => b.classList.remove("active"));
        document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));

        button.classList.add("active");
        document.getElementById(button.dataset.page).classList.add("active");
    });
});

document.getElementById("submitComplaint").addEventListener("click", () => {
    const message = document.getElementById("complaintText").value.trim();

    if (!message) return;

    post("submitComplaint", {
        message
    });

    document.getElementById("complaintText").value = "";
});

closeButton.addEventListener("click", closeApp);

window.addEventListener("keydown", e => {
    if (e.key === "Escape") {
        closeApp();
    }
});

window.addEventListener("message", event => {
    const msg = event.data;

    if (msg.action === "openHotel") {
        openApp(msg.data || {});
    }

    if (msg.action === "openBoss") {
        app.classList.remove("hidden");

        const data = msg.data?.dashboard || {};

        document.getElementById("revenue").textContent = `£${data.revenue || 0}`;
        document.getElementById("occupiedRooms").textContent = data.activeRooms || 0;
        document.getElementById("complaintCount").textContent =
            Array.isArray(data.complaints) ? data.complaints.length : 0;
    }

    if (msg.action === "close") {
        app.classList.add("hidden");
    }
});
