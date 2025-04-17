local VORPcore = {}
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- Config
local shovelItem = Config.ShovelItem

RegisterServerEvent("grave_robbery:checkForShovel")
AddEventHandler("grave_robbery:checkForShovel", function(grave)
    local _source = source
    local inventory = exports.vorp_inventory:getUserInventoryItems(_source)


    local hasShovel = false
    for _, item in pairs(inventory) do
        if item.name == shovelItem and item.count > 0 then
            hasShovel = true
            break
        end
    end

    if hasShovel then
        TriggerClientEvent("grave_robbery:startDigging", _source, grave)
    else
        TriggerClientEvent("grave_robbery:noShovel", _source)
    end
end)

RegisterServerEvent("grave_robbery:finishDigging")
AddEventHandler("grave_robbery:finishDigging", function(grave)
    local _source = source

    -- Defensive check
    if not Config or not Config.possibleLoot then
        return
    end

    local reward = Config.possibleLoot[math.random(1, #Config.possibleLoot)]
    local amount = math.random(reward.min, reward.max)

    exports.vorp_inventory:addItem(_source, reward.item, amount)

    -- Notify the player
    TriggerClientEvent("vorp:TipBottom", _source, "You found " .. amount .. "x " .. reward.item, 5000)
end)

