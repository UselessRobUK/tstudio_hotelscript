local function Main() return require "server.main" end

---@param hotelId string
---@param elevatorId string|number
---@return table|nil
local function GetElevator(hotelId, elevatorId)
    local hotel = Main().GetHotel(hotelId)
    if not hotel or not hotel.elevators then return nil end
    for _, elevator in pairs(hotel.elevators) do
        if tostring(elevator.id) == tostring(elevatorId) then return elevator end
    end
    return nil
end

lib.callback.register("hotel:getElevatorFloors", function(_, hotelId, elevatorId)
    local elevator = GetElevator(hotelId, elevatorId)
    if not elevator then return nil end
    return { id = elevatorId, floors = elevator.floors or {} }
end)

exports("GetHotelElevator", GetElevator)

return { GetElevator = GetElevator }
