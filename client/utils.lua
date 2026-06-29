--========================================================--
-- Standalone Hotel Framework
-- client/utils.lua
--========================================================--

HotelUtils = {}

function HotelUtils.Notify(msg)
    TriggerEvent("hotel:notify", msg)
end

function HotelUtils.LoadModel(model)
    local hash = type(model) == "number" and model or joaat(model)

    if not IsModelInCdimage(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(10)

        if GetGameTimer() > timeout then
            return nil
        end
    end

    return hash
end

function HotelUtils.LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        Wait(10)

        if GetGameTimer() > timeout then
            return false
        end
    end

    return true
end

function HotelUtils.DrawText3D(coords, text, scale)
    scale = scale or 0.35

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function HotelUtils.FadeTeleport(coords, heading)
    DoScreenFadeOut(500)
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

    if heading then
        SetEntityHeading(ped, heading)
    elseif coords.w then
        SetEntityHeading(ped, coords.w)
    end

    Wait(300)
    DoScreenFadeIn(500)
end

function HotelUtils.Distance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

function HotelUtils.IsNear(coords, target, distance)
    return HotelUtils.Distance(coords, target) <= distance
end

function HotelUtils.FindHotel(hotelId)
    for _, hotel in pairs(Config.Hotels or {}) do
        if hotel.id == hotelId then
            return hotel
        end
    end

    return nil
end

function HotelUtils.FindRoom(hotelId, roomId)
    local hotel = HotelUtils.FindHotel(hotelId)

    if hotel and hotel.rooms then
        for _, room in pairs(hotel.rooms) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, hotel
            end
        end
    end

    if Config.Rooms and Config.Rooms[hotelId] then
        for _, room in pairs(Config.Rooms[hotelId]) do
            if tonumber(room.id) == tonumber(roomId) then
                return room, hotel
            end
        end
    end

    return nil, hotel
end

function HotelUtils.GetClosestHotel(maxDistance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local closestHotel = nil
    local closestDistance = maxDistance or 999999.0

    for _, hotel in pairs(Config.Hotels or {}) do
        local point = hotel.entrance or hotel.npc and hotel.npc.coords

        if point then
            local dist = HotelUtils.Distance(coords, point)

            if dist < closestDistance then
                closestHotel = hotel
                closestDistance = dist
            end
        end
    end

    return closestHotel, closestDistance
end

function HotelUtils.AttachPropToPed(ped, model, bone, offset, rotation)
    local hash = HotelUtils.LoadModel(model)
    if not hash then return nil end

    local coords = GetEntityCoords(ped)

    local prop = CreateObject(
        hash,
        coords.x,
        coords.y,
        coords.z,
        true,
        true,
        false
    )

    AttachEntityToEntity(
        prop,
        ped,
        GetPedBoneIndex(ped, bone),
        offset.x,
        offset.y,
        offset.z,
        rotation.x,
        rotation.y,
        rotation.z,
        true,
        true,
        false,
        true,
        1,
        true
    )

    SetModelAsNoLongerNeeded(hash)

    return prop
end

function HotelUtils.DeleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

function HotelUtils.ToVector3(data)
    if not data then return nil end

    if type(data) == "vector3" then
        return data
    end

    if type(data) == "vector4" then
        return vector3(data.x, data.y, data.z)
    end

    if data.coords then
        return HotelUtils.ToVector3(data.coords)
    end

    if data.x and data.y and data.z then
        return vector3(data.x, data.y, data.z)
    end

    return nil
end

function HotelUtils.ToVector4(data, heading)
    if not data then return nil end

    if type(data) == "vector4" then
        return data
    end

    if type(data) == "vector3" then
        return vector4(data.x, data.y, data.z, heading or 0.0)
    end

    if data.coords then
        return HotelUtils.ToVector4(data.coords, data.heading)
    end

    if data.x and data.y and data.z then
        return vector4(data.x, data.y, data.z, data.w or data.heading or heading or 0.0)
    end

    return nil
end

function HotelUtils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function HotelUtils.FormatMoney(amount)
    amount = tonumber(amount) or 0
    return ("£%s"):format(amount)
end

RegisterCommand("hotel_closest", function()
    local hotel, dist = HotelUtils.GetClosestHotel(50.0)

    if not hotel then
        HotelUtils.Notify("No hotel nearby.")
        return
    end

    HotelUtils.Notify(
        ("Closest hotel: %s %.2fm"):format(
            hotel.name or hotel.id,
            dist
        )
    )
end)

exports("HotelNotify", HotelUtils.Notify)
exports("LoadHotelModel", HotelUtils.LoadModel)
exports("LoadHotelAnimDict", HotelUtils.LoadAnimDict)
exports("DrawHotelText3D", HotelUtils.DrawText3D)
exports("FadeHotelTeleport", HotelUtils.FadeTeleport)
exports("FindHotel", HotelUtils.FindHotel)
exports("FindHotelRoom", HotelUtils.FindRoom)
exports("GetClosestHotel", HotelUtils.GetClosestHotel)
exports("ToHotelVector3", HotelUtils.ToVector3)
exports("ToHotelVector4", HotelUtils.ToVector4)
exports("FormatHotelMoney", HotelUtils.FormatMoney)
