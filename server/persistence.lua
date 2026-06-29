--========================================================--
-- Standalone Hotel Framework
-- server/persistence.lua
--========================================================--

Hotel = Hotel or {}
Hotel.Persistence = Hotel.Persistence or {}

function Hotel.Persistence.ReadJson(path)
    local raw = LoadResourceFile(GetCurrentResourceName(), path)

    if not raw or raw == "" then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)

    if not ok then
        print(("^1[HOTEL]^7 Failed to decode JSON: %s"):format(path))
        return nil
    end

    return decoded
end

function Hotel.Persistence.WriteJson(path, data)
    local encoded = json.encode(data, { indent = true })

    SaveResourceFile(
        GetCurrentResourceName(),
        path,
        encoded,
        -1
    )

    return true
end

function Hotel.Persistence.LoadLayouts()
    local layouts = Hotel.Persistence.ReadJson("data/layouts.json") or {}

    for hotelId, layout in pairs(layouts) do
        if Hotel.RegisterHotel then
            Hotel.RegisterHotel(hotelId, layout)
        end
    end

    return layouts
end

function Hotel.Persistence.SaveLayouts(layouts)
    return Hotel.Persistence.WriteJson("data/layouts.json", layouts or {})
end

function Hotel.Persistence.SaveRuntimeHotel(hotelId, data)
    local layouts = Hotel.Persistence.ReadJson("data/layouts.json") or {}

    layouts[hotelId] = data

    Hotel.Persistence.SaveLayouts(layouts)

    if Hotel.RegisterHotel then
        Hotel.RegisterHotel(hotelId, data)
    end

    return true
end

CreateThread(function()
    Wait(3000)

    Hotel.Persistence.LoadLayouts()

    print("^2[HOTEL]^7 Persistent layouts loaded.")
end)

RegisterNetEvent("hotel:saveRuntimeHotel", function(hotelId, data)
    local src = source

    if Hotel.IsAdmin and not Hotel.IsAdmin(src) then
        return Hotel.Notify(src, "No permission.", "error")
    end

    if not hotelId or type(data) ~= "table" then
        return Hotel.Notify(src, "Invalid hotel data.", "error")
    end

    Hotel.Persistence.SaveRuntimeHotel(hotelId, data)

    Hotel.Notify(src, "Hotel layout saved.", "success")
end)

exports("HotelReadJson", Hotel.Persistence.ReadJson)
exports("HotelWriteJson", Hotel.Persistence.WriteJson)
exports("HotelLoadLayouts", Hotel.Persistence.LoadLayouts)
exports("HotelSaveLayouts", Hotel.Persistence.SaveLayouts)
exports("HotelSaveRuntimeHotel", Hotel.Persistence.SaveRuntimeHotel)
