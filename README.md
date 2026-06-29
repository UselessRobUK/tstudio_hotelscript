Ultimate Hotel Framework


Overview


Ultimate Hotel Framework is a premium standalone hotel management system for FiveM designed for roleplay servers of any size. It provides a complete hotel experience with room rentals, hotel ownership, staff management, custom MLO support, a modern NUI, and extensive bridge compatibility—all without requiring ESX or QBCore.


The framework has been built with modularity in mind, allowing server owners to enable or disable optional integrations while keeping the core resource fully standalone.



Features


Hotel Management




Unlimited hotels


Unlimited rooms


Runtime hotel builder


Custom MLO support


Multi-floor hotels


Elevator system


Hotel ownership


Reception NPCs


Animated key handover


Room rental system


Booking system


Automatic rental expiry


Room extensions


Eviction system


Fine system


Complaint system


Employee management


Boss dashboard


Revenue tracking


Hotel analytics


Discord webhook logging





Room Features




Secure room access


Physical or digital room keys


Personal room stash


Wardrobe integration


Instance support


Room cleaning system


Room status tracking


Configurable prices


Configurable rental durations


Individual room permissions





Staff Features




Receptionist


Cleaner


Security


Manager


Hotel Owner




Staff can:




Rent rooms


Extend rentals


Evict tenants


Issue fines


Manage complaints


Hire employees


Fire employees


Change room prices


View analytics





Builder System


Create hotels directly in-game.


Builder supports:




Reception placement


NPC placement


Room placement


Door placement


Wardrobes


Stashes


Elevators


Custom interiors


Custom MLOs


Runtime saving




No server restart required.



Supported Resources


Inventory




ox_inventory


qb-inventory


qs-inventory


lj-inventory


Standalone





Door Locks




ox_doorlock


cd_doorlock


nui_doorlock


Standalone





Target Systems




ox_target


qb-target


interact


Standalone interaction





Wardrobe




illenium-appearance


fivem-appearance


qb-clothing


esx_skin


rcore_clothing


Standalone





Phone




lb-phone


qb-phone


qs-smartphone


gksphone


gcPhone


Standalone





Banking




Renewed Banking


qb-banking


okokBanking


Standalone





Installation




Import sql/hotel.sql into your MySQL database.


Copy the resource into your resources folder.


Ensure the resource name matches your server configuration.


Ensure oxmysql is started before this resource.


Add the resource to your server.cfg:




ensure tstudio_hotelscript





Configure hotels in:




shared/config.lua
shared/hotels.lua
shared/rooms.lua





Restart your server.





Folder Structure


ultimate_hotel/

bridge/
client/
server/
shared/
html/
sql/

fxmanifest.lua
README.md




Configuration


Main configuration:


shared/config.lua



Hotels:


shared/hotels.lua



Rooms:


shared/rooms.lua



Language:


shared/locale.lua




Exports


Examples:


exports["ultimate_hotel"]:CreateRental(...)
exports["ultimate_hotel"]:CancelRental(...)
exports["ultimate_hotel"]:GiveKey(...)
exports["ultimate_hotel"]:HasKey(...)
exports["ultimate_hotel"]:Notify(...)
exports["ultimate_hotel"]:GetHotel(...)
exports["ultimate_hotel"]:GetRoom(...)
exports["ultimate_hotel"]:GetEmployees(...)




Commands


Example administrator commands:


/hotel_reload



Builder commands can be configured to suit your server.



Permissions


Administrator ACE:


hotel.admin



Boss permissions can also be configured through:


Config.BossIdentifiers




Performance


Designed for OneSync Infinity.


Typical performance:




Idle: ~0.00 ms


Near Hotel: ~0.01–0.03 ms


Builder Mode: ~0.02 ms




Performance will vary depending on the number of hotels, enabled integrations, and server hardware.



Requirements




FiveM (Latest Recommended Artifact)


Lua 5.4


oxmysql




Optional resources are automatically detected when configured.



Compatibility




Standalone


OneSync


Legacy Maps


Custom MLOs


Infinity




No ESX or QBCore required.



Support


If you encounter issues:




Confirm all required dependencies are installed.


Verify your configuration files.


Check the server console for errors.


Enable debug mode in shared/config.lua if troubleshooting is required.





License


This resource is intended for use under the license supplied by the author. Redistribution, resale, or modification rights depend on the terms of your license.



Credits


Developed for the FiveM community with a focus on performance, modularity, and compatibility.


Hotel Management by TSTUDIO 


Version 1.0.0

