local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Utils  = require "client.utils"
local Notify = require "client.notifications"

CreateThread(function()
    while true do
        Wait(0)
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, h in pairs(Hotels) do
            local dist = #(coords - vector3(h.entrance.x, h.entrance.y, h.entrance.z))
            if dist < 2.0 then
                Utils.DrawText3D(h.entrance, "[E] Hotel")
                if IsControlJustPressed(0, Config.InteractKey) then
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "open" })
                end
            end
        end
    end
end)
