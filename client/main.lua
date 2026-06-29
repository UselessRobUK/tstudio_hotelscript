CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, h in pairs(Config.Hotels) do
            local dist = #(coords - vector3(h.entrance.x, h.entrance.y, h.entrance.z))

            if dist < 2.0 then
                DrawText3D(h.entrance.x, h.entrance.y, h.entrance.z, "[E] Hotel")

                if IsControlJustPressed(0, Config.InteractKey) then
                    SetNuiFocus(true, true)
                    SendNUIMessage({action = "open"})
                end
            end
        end
    end
end)

function DrawText3D(x,y,z,text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z,0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
