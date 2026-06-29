local ActiveRentals = {}

local function getIdentifier(src)
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(v, "license:") then
            return v
        end
    end
end

RegisterNetEvent("hotel:rentRoom", function(data)
    local src = source
    local id = getIdentifier(src)

    if ActiveRentals[id] then return end

    ActiveRentals[id] = {
        hotel = data.hotelId,
        room = data.roomId,
        expires = os.time() + 86400
    }

    TriggerClientEvent("hotel:notify", src, "Room rented successfully")
end)

RegisterNetEvent("hotel:getRooms", function()
    local src = source
    TriggerClientEvent("hotel:sendRooms", src, {
        {id = 101, label = "Standard", price = 250},
        {id = 102, label = "Deluxe", price = 500}
    })
end)
