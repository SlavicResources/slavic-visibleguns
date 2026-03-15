local attachedWeapons = {}

local usingOx = GetResourceState('ox_inventory') == 'started'
local usingQB = GetResourceState('qb-inventory') == 'started'

local QBCore = nil
if usingQB then
    QBCore = exports['qb-core']:GetCoreObject()
end


local function HasWeaponInInventory(weapon)
    if usingOx then
        local count = exports.ox_inventory:Search('count', weapon)
        return count and count > 0
    end

    if usingQB and QBCore then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.items then
            for _, item in pairs(PlayerData.items) do
                if item and item.name == weapon then
                    return true
                end
            end
        end
    end

    return false
end


local function AttachWeapon(weapon, type)
    local ped = PlayerPedId()

    if attachedWeapons[weapon] then return end

    local pos = Config.Positions[type]
    if not pos then return end

    local hash = GetHashKey(weapon)
    local model = GetWeapontypeModel(hash)

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    local obj = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)

    AttachEntityToEntity(
        obj,
        ped,
        GetPedBoneIndex(ped, pos.bone),
        pos.x, pos.y, pos.z,
        pos.xr, pos.yr, pos.zr,
        true, true, false, true, 1, true
    )

    attachedWeapons[weapon] = obj
end


local function RemoveWeapon(weapon)
    if attachedWeapons[weapon] then
        DeleteEntity(attachedWeapons[weapon])
        attachedWeapons[weapon] = nil
    end
end


CreateThread(function()
    while true do
        Wait(1500)

        local ped = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(ped)

        for weapon, type in pairs(Config.WeaponTypes) do

            local weaponHash = GetHashKey(weapon)
            local hasWeapon = HasWeaponInInventory(weapon)

            if hasWeapon then

                if currentWeapon ~= weaponHash then
                    AttachWeapon(weapon, type)
                else
                    RemoveWeapon(weapon)
                end

            else
                RemoveWeapon(weapon)
            end

        end
    end
end)