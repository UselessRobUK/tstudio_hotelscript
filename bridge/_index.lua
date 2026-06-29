if IsDuplicityVersion() then
    local banking      = require "bridge.banking"
    local inventory    = require "bridge.inventory"
    local doorlock     = require "bridge.doorlock"
    local notifications = require "bridge.notifications"
    local phone        = require "bridge.phone"
    local stash        = require "bridge.stash"
    local wardrobe     = require "bridge.wardrobe"

    return {
        banking      = banking,
        inventory    = inventory,
        doorlock     = doorlock,
        notifications = notifications,
        phone        = phone,
        stash        = stash,
        wardrobe     = wardrobe,
    }
else
    local target = require "bridge.target"

    return {
        target = target,
    }
end
