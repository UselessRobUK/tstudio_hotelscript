local building = false
local tempHotel = {}

RegisterCommand("hotel_build", function()
    building = not building
    TriggerEvent("hotel:notify", "Hotel builder: " .. tostring(building))
end)

CreateThread(function()
    while true do
        Wait(0)

        if building then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0,0,0,0,0,0, 1.0,1.0,1.0, 0,255,0,150)

            if IsControlJustPressed(0, 38) then -- E
                table.insert(tempHotel, coords)
                TriggerEvent("hotel:notify", "Point saved")
            end
        end
    end
end)
