local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Notify = require "client.notifications"

local Elevator = {
    open            = false,
    currentHotel    = nil,
    currentElevator = nil,
}

local function Teleport(coords)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = PlayerPedId()

    SetEntityCoords(
        ped,
        coords.x,
        coords.y,
        coords.z,
        false,
        false,
        false,
        true
    )

    if coords.w then
        SetEntityHeading(ped, coords.w)
    end

    Wait(300)
    DoScreenFadeIn(400)
end

local function OpenElevatorMenu(hotelId, elevatorId, floors)
    Elevator.open = true
    Elevator.currentHotel = hotelId
    Elevator.currentElevator = elevatorId

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "openElevator",
        data = {
            hotel = hotelId,
            elevator = elevatorId,
            floors = floors or {}
        }
    })
end

local function CloseElevatorMenu()
    Elevator.open = false
    Elevator.currentHotel = nil
    Elevator.currentElevator = nil

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "closeElevator"
    })
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
    local result = lib.callback.await("hotel:getElevatorFloors", false, args[1] or "main_hotel", args[2] or "main")
    if not result then return Notify.Error("Elevator not found.") end
    OpenElevatorMenu(result.id, result.floors)
end, false)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, hotel in pairs(Hotels) do
            if hotel.elevators then
                for _, elevator in pairs(hotel.elevators) do
                    local dist = #(coords - vector3(
                        elevator.coords.x,
                        elevator.coords.y,
                        elevator.coords.z
                    ))

                    if dist < 2.0 then
                        sleep = 0

                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("[E] Use Elevator")
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, Config.InteractKey or 38) then
                            local result = lib.callback.await("hotel:getElevatorFloors", false, hotel.id, elevator.id)
                            if result then OpenElevatorMenu(hotel.id, result.id, result.floors) end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if Elevator.open then
            Wait(0)

            if IsControlJustPressed(0, 322) then
                CloseElevatorMenu()
            end
        else
            Wait(1000)
        end
    end
end)

exports("OpenHotelElevator", OpenElevatorMenu)
exports("CloseHotelElevator", CloseElevatorMenu)
