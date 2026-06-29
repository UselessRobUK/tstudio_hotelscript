local function Registry() return require "server.registry" end
local function Main()     return require "server.main" end
local function Security() return require "server.security" end

---@param path string
---@return any
local function ReadJson(path)
    local raw = LoadResourceFile(GetCurrentResourceName(), path)
    if not raw or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if not ok then
        print(("^1[HOTEL]^7 Failed to decode JSON: %s"):format(path))
        return nil
    end
    return decoded
end

---@param path string
---@param data any
---@return boolean
local function WriteJson(path, data)
    SaveResourceFile(GetCurrentResourceName(), path, json.encode(data, { indent = true }), -1)
    return true
end

---@return table
local function LoadLayouts()
    local layouts = ReadJson("data/layouts.json") or {}
    for hotelId, layout in pairs(layouts) do
        Registry().RegisterHotel(hotelId, layout)
    end
    return layouts
end

---@param layouts? table
---@return boolean
local function SaveLayouts(layouts)
    return WriteJson("data/layouts.json", layouts or {})
end

---@param hotelId string
---@param data table
---@return boolean
local function SaveRuntimeHotel(hotelId, data)
    local layouts = ReadJson("data/layouts.json") or {}
    layouts[hotelId] = data
    SaveLayouts(layouts)
    Registry().RegisterHotel(hotelId, data)
    return true
end

CreateThread(function()
    Wait(3000)
    LoadLayouts()
    print("^2[HOTEL]^7 Persistent layouts loaded.")
end)

RegisterNetEvent("hotel:saveRuntimeHotel", function(hotelId, data)
    local src = source
    if not Security().IsAdmin(src) then return Main().Notify(src, "No permission.", "error") end
    if not hotelId or type(data) ~= "table" then return Main().Notify(src, "Invalid hotel data.", "error") end
    SaveRuntimeHotel(hotelId, data)
    Main().Notify(src, "Hotel layout saved.", "success")
end)

exports("HotelReadJson",            ReadJson)
exports("HotelWriteJson",           WriteJson)
exports("HotelLoadLayouts",         LoadLayouts)
exports("HotelSaveLayouts",         SaveLayouts)
exports("HotelSaveRuntimeHotel",    SaveRuntimeHotel)

return { ReadJson = ReadJson, WriteJson = WriteJson, LoadLayouts = LoadLayouts, SaveLayouts = SaveLayouts, SaveRuntimeHotel = SaveRuntimeHotel }
