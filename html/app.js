window.addEventListener("message", function(e) {
    if (e.data.action === "open") {
        fetch(`https://hotel-system/getRooms`, {
            method: "POST"
        });
    }
});
