Config = {}

Config.Graves = {
    vector4(-1759.39, -240.93, 182.76, 2.89), -- Strawberry Graves -- Add more below.
    vector4(-1763.08, -242.06, 182.5, 342.67)
}

Config.DigDistance = 0.5 
Config.TimeToDig = 20000 -- This is in seconds 20000 = 20 seconds
Config.ShovelItem = "shovel"

Config.possibleLoot = {
    { item = "consumable_coffee", min = 1, max = 2 },
    { item = "consumable_coffee", min = 1, max = 3 },
    { item = "consumable_coffee", min = 1, max = 1 }
}

Config.Messages = {
    ShovelRequired = "You need a shovel to dig here.",
    DiggingGrave = "Digging up the dead!",
    CoolDownMessage = "You have exhumed too many dead. Come back when more have been buried!"
}

Config.GraveLimitRange = { Min = 5, Max = 10}  -- The range of graves a player can dig before a cooldown is triggered
Config.CooldownDuration = 10000  -- Cooldown duration in milliseconds (60,000 ms = 60 seconds)
Config.Prompts = {
    DigGrave = "DIG UP THE DEAD!"
}


---/// This script is made by HIJINX \\\ ---