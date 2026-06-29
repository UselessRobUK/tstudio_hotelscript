function BindRoomSystems(hotelId)
    local loc = GetHotelLocation(hotelId)
    if not loc then return end

    for _, door in pairs(loc.doors) do
        if GetResourceState("ox_doorlock") == "started" then
            exports.ox_doorlock:addDoor({
                coords = door.coords,
                locked = true
            })
        end
    end
end
