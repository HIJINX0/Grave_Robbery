-- client.lua
---/// Script Made By HIJINX \\\---
local playerGraveCount = {}
local nearGrave = false
local currentGrave = nil
local DigPrompt = nil
local PromptGroup = GetRandomIntInRange(0, 0xffffff)

-- Function to apply a cooldown to the player
local function startCooldown(playerId, cooldownDuration)
    playerGraveCount[playerId].cooldown = true
    Citizen.SetTimeout(cooldownDuration, function()
        playerGraveCount[playerId].cooldown = false
    end)
end

-- Set up the dig prompt (the "E" prompt)
local function setUpPrompt()
    DigPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(DigPrompt, 0xCEFD9220) -- E key
    local label = VarString(10, 'LITERAL_STRING', "Dig Grave")
    UiPromptSetText(DigPrompt, label)
    UiPromptSetEnabled(DigPrompt, true)
    UiPromptSetVisible(DigPrompt, true)
    UiPromptSetStandardMode(DigPrompt, true)
    UiPromptSetGroup(DigPrompt, PromptGroup, 0)
    UiPromptRegisterEnd(DigPrompt)
end

-- Show the prompt on screen
local function showPrompt(label, action)
    local labelToDisplay = VarString(10, 'LITERAL_STRING', label)
    UiPromptSetActiveGroupThisFrame(PromptGroup, labelToDisplay, 0, 0, 0, 0)

    if UiPromptHasStandardModeCompleted(DigPrompt, 0) then
        Wait(100)
        return action
    end
end

Citizen.CreateThread(function()
    setUpPrompt()
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        nearGrave = false

        -- Loop through the graves in Config.Graves
        for i, grave in pairs(Config.Graves) do
            local gravePos = vector3(grave.x, grave.y, grave.z)
            local distance = #(coords - gravePos)

            if distance < 10.0 then
                sleep = 0
                -- Draw a marker at the grave location
                DrawMarker(2, grave.x, grave.y, grave.z - 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 0.5, 255, 255, 255, 150, false, true, 2, false, nil, nil, false)
            end

            -- Check if the player is near enough to the grave to dig
            if distance < Config.DigDistance then
                nearGrave = true
                currentGrave = grave
                showPrompt(Config.Prompts.DigGrave, true)
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Handle when the player presses the "E" key to dig a grave
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerId = PlayerId()

        if nearGrave and IsControlJustReleased(0, 0xCEFD9220) then -- E key
            -- Check if the player is on cooldown
            if playerGraveCount[playerId] and playerGraveCount[playerId].cooldown then
                TriggerEvent("vorp:TipBottom", "You need to wait before digging again.", 4000)
                return
            end

            -- Increment grave count for the player
            if not playerGraveCount[playerId] then
                playerGraveCount[playerId] = { count = 0, cooldown = false }
            end

            playerGraveCount[playerId].count = playerGraveCount[playerId].count + 1

            -- Generate a random grave limit within the range defined in config.lua
            local randomGraveLimit = math.random(Config.GraveLimitRange.Min, Config.GraveLimitRange.Max)

            -- If the player has dug enough graves, apply the cooldown
            if playerGraveCount[playerId].count >= randomGraveLimit then
                startCooldown(playerId, Config.CooldownDuration) -- Apply cooldown from config
                TriggerEvent("vorp:TipBottom", Config.Messages.CoolDownMessage, 4000)
                playerGraveCount[playerId].count = 0  -- Reset grave count after cooldown
            else
                -- Proceed with the grave digging process
                TriggerServerEvent("grave_robbery:checkForShovel", currentGrave)
            end
        end
    end
end)

-- Start the digging action with a progress bar
RegisterNetEvent("grave_robbery:startDigging")
AddEventHandler("grave_robbery:startDigging", function(grave)
    local playerPed = PlayerPedId()
    local animDict = "amb_work@world_human_gravedig@working@male_b@base"
    local animName = "base"
    local digTime = Config.TimeToDig

    -- Load animation dictionary
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

    -- Freeze player so they can't move
    FreezeEntityPosition(playerPed, true)

    -- Play looping animation
    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 1, 0, false, false, false)

    -- Start progress bar
    exports['progressBars']:startUI(digTime, Config.Messages.DiggingGrave)

    -- Disable controls during the digging 
    local endTime = GetGameTimer() + digTime
    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(0)
            -- Basic movement & interaction controls are disabled
            DisableControlAction(0, 30, true) -- Move left/right
            DisableControlAction(0, 31, true) -- Move forward/back
            DisableControlAction(0, 32, true) -- Move up
            DisableControlAction(0, 33, true) -- Move down
            DisableControlAction(0, 34, true) -- Turn left
            DisableControlAction(0, 35, true) -- Turn right
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 20, true) -- Z
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 37, true) -- Select weapon
            DisableControlAction(0, 140, true) -- Melee attack 1
            DisableControlAction(0, 141, true) -- Melee attack 2
            DisableControlAction(0, 142, true) -- Melee attack 3
        end
    end)

    -- Wait for animation to finish
    Wait(digTime)

    -- Stop animation and unfreeze
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
    RemoveAnimDict(animDict)

    -- Trigger reward after digging
    TriggerServerEvent("grave_robbery:finishDigging", grave)
end)

-- Handle the case when the player doesn't have a shovel
RegisterNetEvent("grave_robbery:noShovel")
AddEventHandler("grave_robbery:noShovel", function()
    TriggerEvent("vorp:TipBottom", Config.Messages.ShovelRequired, 4000)
end)

-- Handle reward notification after successful digging
RegisterNetEvent("grave_robbery:rewardNotification")
AddEventHandler("grave_robbery:rewardNotification", function(itemName, amount)
    print("RECEIVED rewardNotification with", itemName, amount) -- Debug line

    local message = "You found " .. amount .. "x " .. itemName .. " in the grave!"
    TriggerEvent("vorp:TipBottom", message, 5000)
end)
