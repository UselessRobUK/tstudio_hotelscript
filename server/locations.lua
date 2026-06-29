local HotelLocations = {}

function RegisterHotelLocation(hotelId, data)
    HotelLocations[hotelId] = {
        name = data.name,
        entrance = data.entrance,
        floors = data.floors or {},
        doors = data.doors or {},
        stashes = data.stashes or {},
        wardrobes = data.wardrobes or {}
    }
end

function GetHotelLocation(hotelId)
    return HotelLocations[hotelId]
end
