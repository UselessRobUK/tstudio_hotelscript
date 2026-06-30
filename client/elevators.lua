local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Notify = require "client.notifications"

local Target    = Config.UseTarget and require "bridge.target" or nil
local useTarget = Target and Target.type ~= "standalone"

local Elevator = {
    open            = false,
    currentHotel    = nil,
    currentElevator = nil,
    pendingAction   = nil,
}

local function Teleport(coords)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = PlayerPedId()

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)

    if coords.w then
        SetEntityHeading(ped, coords.w)
    end

    Wait(300)
    DoScreenFadeIn(400)
end

local function OpenElevatorMenu(hotelId, elevatorId, floors)
    Elevator.open            = true
    Elevator.currentHotel    = hotelId
    Elevator.currentElevator = elevatorId

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openElevator",
        data   = { hotel = hotelId, elevator = elevatorId, floors = floors or {} }
    })
end

local function CloseElevatorMenu()
    Elevator.open            = false
    Elevator.currentHotel    = nil
    Elevator.currentElevator = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeElevator" })
end

RegisterNUICallback("elevatorClose", function(_, cb)
    CloseElevatorMenu()
    cb({ ok = true })
end)

RegisterNUICallback("elevatorSelectFloor", function(data, cb)
    if not data or not data.coords then
        cb({ ok = false })
        return
    end
    CloseElevatorMenu()
    Notify.Info("Using elevator...")
    Wait(800)
    Teleport(data.coords)
    cb({ ok = true })
end)

RegisterCommand("hotel_elevator", function(_, args)
    CreateThread(function()
        local result = lib.callback.await("hotel:getElevatorFloors", false, args[1] or "main_hotel", args[2] or "main")
        if not result then return Notify.Error("Elevator not found.") end
        OpenElevatorMenu(result.id, result.floors)
    end)
end, false)

local elevatorKey
if not useTarget then
    elevatorKey = lib.addKeybind({
        name        = 'hotel_elevator_interact',
        description = 'Use Elevator',
        defaultKey  = 'e',
        disabled    = true,
        onPressed   = function()
            if Elevator.pendingAction then
                CreateThread(Elevator.pendingAction)
            end
        end,
    })
end

for _, hotel in pairs(Hotels) do
    if hotel.elevators then
        for _, elevator in pairs(hotel.elevators) do
            local ecoords = vec3(elevator.coords.x, elevator.coords.y, elevator.coords.z)
            local zoneId  = ("hotel_elevator_%s_%s"):format(hotel.id, elevator.id)

            if useTarget then
                Target.AddBoxZone(zoneId, ecoords, vec3(1.0, 1.0, 2.0), {
                    distance = 2.0,
                    options  = {
                        {
                            label    = "Use Elevator",
                            icon     = "fas fa-elevator",
                            onSelect = function()
                                CreateThread(function()
                                    local result = lib.callback.await("hotel:getElevatorFloors", false, hotel.id, elevator.id)
                                    if result then OpenElevatorMenu(hotel.id, result.id, result.floors) end
                                end)
                            end,
                        },
                    },
                })
            else
                lib.zones.sphere({
                    coords  = ecoords,
                    radius  = 2.0,
                    debug   = Config.Debug,
                    onEnter = function()
                        Elevator.pendingAction = function()
                            local result = lib.callback.await("hotel:getElevatorFloors", false, hotel.id, elevator.id)
                            if result then OpenElevatorMenu(hotel.id, result.id, result.floors) end
                        end
                        lib.showTextUI("[E] Use Elevator", { position = 'right-center' })
                        elevatorKey:enable()
                    end,
                    onExit  = function()
                        Elevator.pendingAction = nil
                        lib.hideTextUI()
                        elevatorKey:disable()
                    end,
                })
            end
        end
    end
end

exports("OpenHotelElevator", OpenElevatorMenu)
exports("CloseHotelElevator", CloseElevatorMenu)
