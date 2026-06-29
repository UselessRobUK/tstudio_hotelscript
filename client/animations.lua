--========================================================--
-- Standalone Hotel Framework
-- client/animations.lua
--========================================================--

local Anim = {}

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end

    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        Wait(10)

        if GetGameTimer() > timeout then
            print(("[Hotel] Failed to load anim dict: %s"):format(dict))
            return false
        end
    end

    return true
end

local function LoadModel(model)
    local hash = type(model) == "number" and model or joaat(model)

    if not IsModelInCdimage(hash) then return nil end

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

local function AttachPropToPed(ped, model, bone, offset, rotation)
    local hash = LoadModel(model)
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

local function DeleteProp(prop)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
end

function Anim.PlayKeyFob()
    local ped = PlayerPedId()
    local dict = "anim@mp_player_intmenu@key_fob@"
    local clip = "fob_click"

    if not LoadAnimDict(dict) then return end

    TaskPlayAnim(
        ped,
        dict,
        clip,
        8.0,
        -8.0,
        1600,
        49,
        0.0,
        false,
        false,
        false
    )
end

function Anim.PlayReceiveKey()
    local ped = PlayerPedId()
    local dict = "mp_common"
    local clip = "givetake1_b"

    if not LoadAnimDict(dict) then return end

    TaskPlayAnim(
        ped,
        dict,
        clip,
        8.0,
        -8.0,
        2200,
        48,
        0.0,
        false,
        false,
        false
    )
end

function Anim.PlayGiveKey(npc)
    if not npc or not DoesEntityExist(npc) then return end

    local dict = "mp_common"
    local clip = "givetake1_a"

    if not LoadAnimDict(dict) then return end

    TaskPlayAnim(
        npc,
        dict,
        clip,
        8.0,
        -8.0,
        2200,
        48,
        0.0,
        false,
        false,
        false
    )
end

function Anim.PlayClipboard(npc)
    if not npc or not DoesEntityExist(npc) then return end

    TaskStartScenarioInPlace(
        npc,
        "WORLD_HUMAN_CLIPBOARD",
        0,
        true
    )
end

function Anim.PlayKnockDoor()
    local ped = PlayerPedId()
    local dict = "timetable@jimmy@doorknock@"
    local clip = "knockdoor_idle"

    if not LoadAnimDict(dict) then return end

    TaskPlayAnim(
        ped,
        dict,
        clip,
        8.0,
        -8.0,
        2500,
        48,
        0.0,
        false,
        false,
        false
    )
end

function Anim.PlayCleaning()
    local ped = PlayerPedId()

    TaskStartScenarioInPlace(
        ped,
        "WORLD_HUMAN_MAID_CLEAN",
        0,
        true
    )
end

function Anim.Stop()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

RegisterNetEvent("hotel:anim:keyFob", Anim.PlayKeyFob)
RegisterNetEvent("hotel:anim:receiveKey", Anim.PlayReceiveKey)
RegisterNetEvent("hotel:anim:knockDoor", Anim.PlayKnockDoor)
RegisterNetEvent("hotel:anim:cleaning", Anim.PlayCleaning)
RegisterNetEvent("hotel:anim:stop", Anim.Stop)

RegisterNetEvent("hotel:anim:keyHandover", function(npcNetId)
    local player = PlayerPedId()
    local npc = NetToPed(npcNetId)

    if not npc or not DoesEntityExist(npc) then
        Anim.PlayReceiveKey()
        return
    end

    local keyPropPlayer = nil
    local keyPropNpc = nil

    local dict = "mp_common"

    if not LoadAnimDict(dict) then return end

    keyPropNpc = AttachPropToPed(
        npc,
        "prop_cuff_keys_01",
        57005,
        vector3(0.10, 0.02, 0.0),
        vector3(90.0, 0.0, 0.0)
    )

    TaskTurnPedToFaceEntity(player, npc, 1000)
    TaskTurnPedToFaceEntity(npc, player, 1000)

    Wait(800)

    TaskPlayAnim(
        npc,
        dict,
        "givetake1_a",
        8.0,
        -8.0,
        1800,
        48,
        0.0,
        false,
        false,
        false
    )

    TaskPlayAnim(
        player,
        dict,
        "givetake1_b",
        8.0,
        -8.0,
        1800,
        48,
        0.0,
        false,
        false,
        false
    )

    Wait(900)

    DeleteProp(keyPropNpc)

    keyPropPlayer = AttachPropToPed(
        player,
        "prop_cuff_keys_01",
        57005,
        vector3(0.10, 0.02, 0.0),
        vector3(90.0, 0.0, 0.0)
    )

    Wait(900)

    DeleteProp(keyPropPlayer)

    ClearPedTasks(player)
    ClearPedTasks(npc)

    Anim.PlayClipboard(npc)
end)

exports("PlayKeyFob", Anim.PlayKeyFob)
exports("PlayReceiveKey", Anim.PlayReceiveKey)
exports("PlayGiveKey", Anim.PlayGiveKey)
exports("PlayClipboard", Anim.PlayClipboard)
exports("PlayKnockDoor", Anim.PlayKnockDoor)
exports("PlayCleaning", Anim.PlayCleaning)
exports("StopHotelAnim", Anim.Stop)
