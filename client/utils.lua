local Config = require "configs.shared.main"
local Hotels = require "configs.shared.hotels"
local Rooms  = require "configs.shared.rooms"

local Notify = require "client.notifications"

---@param model string|number
---@return number|nil
local function LoadModel(model)
    local hash = type(model) == "number" and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() > timeout then return nil end
    end
    return hash
end

---@param dict string
---@return boolean
local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        if GetGameTimer() > timeout then return false end
    end
    return true
end

---@param coords vector3
---@param text string
---@param scale? number
local function DrawText3D(coords, text, scale)
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

---@param coords vector3|vector4
---@param heading? number
local function FadeTeleport(coords, heading)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    if heading then
        SetEntityHeading(ped, heading)
    elseif coords.w then
        SetEntityHeading(ped, coords.w)
    end
    Wait(300)
    DoScreenFadeIn(500)
end

---@param a vector3
---@param b vector3
---@return number
local function Distance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

---@param hotelId string
---@return table|nil
local function FindHotel(hotelId)
    for _, hotel in pairs(Hotels) do
        if hotel.id == hotelId then return hotel end
    end
    return nil
end

---@param hotelId string
---@param roomId number
---@return table|nil, table|nil
local function FindRoom(hotelId, roomId)
    local hotel = FindHotel(hotelId)
    if hotel and hotel.rooms then
        for _, room in pairs(hotel.rooms) do
            if tonumber(room.id) == tonumber(roomId) then return room, hotel end
        end
    end
    if Rooms[hotelId] then
        for _, room in pairs(Rooms[hotelId]) do
            if tonumber(room.id) == tonumber(roomId) then return room, hotel end
        end
    end
    return nil, hotel
end

---@param maxDistance? number
---@return table|nil, number
local function GetClosestHotel(maxDistance)
    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local closest = nil
    local closestDist = maxDistance or 999999.0
    for _, hotel in pairs(Hotels) do
        local point = hotel.reception and hotel.reception.coords
        if point then
            local dist = Distance(coords, point)
            if dist < closestDist then
                closest = hotel
                closestDist = dist
            end
        end
    end
    return closest, closestDist
end

---@param data any
---@return vector3|nil
local function ToVector3(data)
    if not data then return nil end
    if type(data) == "vector3" then return data end
    if type(data) == "vector4" then return vector3(data.x, data.y, data.z) end
    if data.coords then return ToVector3(data.coords) end
    if data.x and data.y and data.z then return vector3(data.x, data.y, data.z) end
    return nil
end

---@param data any
---@param heading? number
---@return vector4|nil
local function ToVector4(data, heading)
    if not data then return nil end
    if type(data) == "vector4" then return data end
    if type(data) == "vector3" then return vector4(data.x, data.y, data.z, heading or 0.0) end
    if data.coords then return ToVector4(data.coords, data.heading) end
    if data.x and data.y and data.z then return vector4(data.x, data.y, data.z, data.w or data.heading or heading or 0.0) end
    return nil
end

RegisterCommand("hotel_closest", function()
    local hotel, dist = GetClosestHotel(50.0)
    if not hotel then Notify.Info("No hotel nearby.") return end
    Notify.Info(("Closest hotel: %s %.2fm"):format(hotel.name or hotel.id, dist))
end)

exports("LoadHotelModel",       LoadModel)
exports("LoadHotelAnimDict",    LoadAnimDict)
exports("DrawHotelText3D",      DrawText3D)
exports("FadeHotelTeleport",    FadeTeleport)
exports("FindHotel",            FindHotel)
exports("FindHotelRoom",        FindRoom)
exports("GetClosestHotel",      GetClosestHotel)
exports("ToHotelVector3",       ToVector3)
exports("ToHotelVector4",       ToVector4)

return {
    LoadModel       = LoadModel,
    LoadAnimDict    = LoadAnimDict,
    DrawText3D      = DrawText3D,
    FadeTeleport    = FadeTeleport,
    Distance        = Distance,
    FindHotel       = FindHotel,
    FindRoom        = FindRoom,
    GetClosestHotel = GetClosestHotel,
    ToVector3       = ToVector3,
    ToVector4       = ToVector4,
}
