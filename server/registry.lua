local Registry = {}

function RegisterHotel(id, data)
    Registry[id] = data
end

function GetHotels()
    return Registry
end
