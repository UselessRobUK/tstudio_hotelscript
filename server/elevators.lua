--========================================================--
-- Standalone Hotel Framework
-- server/elevators.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Elevators = Hotel.Elevators or {}

function Hotel.Elevators.Get(hotelId, elevatorId)
    local hotel = Hotel.GetHotel(hotelId)
    if not hotel or not hotel.elevators then return nil end

    for _, elevator in pairs(hotel.elevators) do
        if tostring(elevator.id) == tostring(elevatorId) then
            return elevator
        end
    end

    return nil
end

RegisterNetEvent("hotel:getElevatorFloors", function(hotelId, elevatorId)
    local src = source

    local elevator = Hotel.Elevators.Get(hotelId, elevatorId)

    if not elevator then
        return Hotel.Notify(src, "Elevator not found.", "error")
    end

    TriggerClientEvent(
        "hotel:openElevator",
        src,
        hotelId,
        elevatorId,
        elevator.floors or {}
    )
end)

exports("GetHotelElevator", Hotel.Elevators.Get)
