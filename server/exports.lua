local Hotels = require "configs.shared.hotels"
local Stash  = require "bridge.stash"

local function Main()      return require "server.main" end
local function Rooms()     return require "server.rooms" end
local function Rentals()   return require "server.rentals" end
local function Keys()      return require "server.keys" end
local function Instances() return require "server.instances" end
local function Boss()      return require "server.boss" end
local function Employees() return require "server.employees" end
local function Ownership() return require "server.ownership" end
local function Analytics() return require "server.analytics" end
local function Webhooks()  return require "server.webhooks" end
local function Persist()   return require "server.persistence" end
local function Notifs()    return require "server.notifications" end

exports("GetHotel",       function(hotelId)            return Main().GetHotel(hotelId) end)
exports("GetHotels",      function()                   return Hotels end)
exports("GetRoom",        function(hotelId, roomId)    return Main().GetRoom(hotelId, tonumber(roomId)) end)
exports("GetRooms",       function(hotelId)            return Rooms().GetAll(hotelId) end)
exports("IsRoomAvailable",function(hotelId, roomId)    return Rooms().IsAvailable(hotelId, tonumber(roomId)) end)

exports("CreateRental",   function(src, hotelId, roomId, payment) return Rentals().CreateRental(src, hotelId, tonumber(roomId), payment) end)
exports("CancelRental",   function(src, hotelId, roomId)          return Rentals().CancelRental(src, hotelId, tonumber(roomId)) end)
exports("ExtendRental",   function(src, hotelId, roomId, h, pay)  return Rentals().ExtendRental(src, hotelId, tonumber(roomId), tonumber(h), pay) end)
exports("GetActiveRental",function(src)                           return Rentals().GetActiveRental(src) end)

exports("GiveKey",   function(src, hotelId, roomId, expires) return Keys().Give(src, hotelId, tonumber(roomId), expires) end)
exports("RemoveKey", function(src, hotelId, roomId)          return Keys().Remove(src, hotelId, tonumber(roomId)) end)
exports("HasKey",    function(src, hotelId, roomId)          return Keys().Has(Main().GetIdentifier(src), hotelId, tonumber(roomId)) end)
exports("HasRoomAccess", function(src, hotelId, roomId)
    local identifier = Main().GetIdentifier(src)
    if not identifier then return false end
    return Keys().Has(identifier, hotelId, tonumber(roomId))
end)

exports("CreateInstance", function(src, hotelId, roomId) return Instances().Create(src, hotelId, tonumber(roomId)) end)
exports("JoinInstance",   function(src, instanceId)      return Instances().Join(src, instanceId) end)
exports("LeaveInstance",  function(src, instanceId)      return Instances().Leave(src, instanceId) end)

exports("IsBoss",        function(src, hotelId) return Boss().IsBoss(src, hotelId) end)
exports("GetDashboard",  function(hotelId)      return Boss().GetDashboard(hotelId) end)
exports("GetEmployees",  function(hotelId)      return Employees().GetEmployees(hotelId) end)
exports("IsOwner",       function(src, hotelId) return Ownership().IsOwner(src, hotelId) end)
exports("GetOwner",      function(hotelId)      return Ownership().GetOwner(hotelId) end)

exports("GetStashId",    function(hotelId, roomId) return Stash.GetId(hotelId, tonumber(roomId)) end)
exports("Analytics",     function()               return Analytics().Get() end)
exports("Notify",        function(src, msg, t)    return Notifs().Notify(src, msg, t) end)
exports("Webhook",       function(...)             return Webhooks().Send(...) end)
exports("SaveLayout",    function(layout)
    if not layout or not layout.id then return false end
    return Persist().SaveRuntimeHotel(layout.id, layout)
end)
