--[[
=====================================
| author: Nkfree                    |
| github: https://github.com/Nkfree |
================================================================================================================================================
| configurables:                                                                                                                               |
|   script.config.useRealTime - whether to use seconds as time for gold restocking or in-game days and hours                                   |
|   script.config.restockGoldSeconds - only if script.config.useRealTime is set to true; how many seconds until gold restocking                |
|   script.config.restockGoldDays - only if script.config.useRealTime is set to false; how many days until gold restocking                     |
|   script.config.restockGoldHours - only if script.config.useRealTime is set to false; how many hours until gold restocking                   |
| installation:                                                                                                                                |
|   1. For the initial gold pool to be set up correctly, please delete the contents of <tes3mp>/server/data/cells                              |
|   2. Create a folder restockMerchantsGold in <tes3mp>/server/scripts/custom                                                                  |
|   3. Add main.lua in that created folder                                                                                                     |
|   4. Open customScripts.lua and put there this line: require("custom.restockMerchantsGold.main")                                             |
|   5. Save customScripts.lua and launch the server                                                                                            |
|   6. To confirm the script is running fine, you should see "[RestockMerchantsGold] Running..." among the first few lines of server console   |
================================================================================================================================================
]]

local script = {}

script.config = {}
script.config.useRealTime = true -- true: restocks gold after n seconds; false: uses in-game days and hours to restock gold

-- REALTIME CONFIGURABLES
script.config.restockGoldSeconds = 20 -- how many realtime seconds should pass in order to restock gold; 3600 seconds = 1 hour

-- IN-GAME TIME CONFIGURABLES
script.config.restockGoldDays = 0 -- how many in-game days should pass in order to restock gold
script.config.restockGoldHours = 5 -- how many in-game hours should pass in order to restock gold

script.messages = {}
script.messages.restockedGold = "My gold is restocked."
script.messages.restockingGoldSoon = "My gold will soon be restocked."

-- Attributes and functions related to either realtime or in-game time choice
if script.config.useRealTime then
    script.messages.restockingGoldInMinutesSeconds = "I will be restocking gold in %s minutes and %s seconds."
    script.messages.restockingGoldInMinutesSecond = "I will be restocking gold in %s minutes and 1 second."
    script.messages.restockingGoldInMinuteSecond = "I will be restocking gold in 1 minute and 1 second."
    script.messages.restockingGoldInSeconds = "I will be restocking gold in %s seconds."
    script.messages.restockingGoldInSecond = "I will be restocking gold in 1 second."

    script.spellRecords = {}
    script.spellRecords.restockGold = {
        id = "restock_gold_signal",
        data = {
            name = "Restock Gold Signal",
            flags = 4,
            cost = 0,
            subtype = 0,
            effects = {
                {
                    attribute = -1,
                    area = 0,
                    duration = script.config.restockGoldSeconds,
                    id = 79, -- Fortify attribute
                    rangeType = 0,
                    skill = -1,
                    magnitudeMin = 0, -- Do not actually harm or buff the target
                    magnitudeMax = 0 -- Do not actually harm or buff the target
                }
            }
        }
    }

    function script.GetDisplayRestockGoldInfo(cell, uniqueIndex)
        local messages = script.messages

        if script.HasGoldRestocked(cell, uniqueIndex) then
            return messages.restockedGold
        end

        if not script.HasRestockGoldSpellActive(cell, uniqueIndex) then
            return ""
        end

        -- The restock spell should be active at this point at all times
        local restockGoldActiveSpell = script.GetRestockGoldActiveSpell(cell, uniqueIndex)
        local startTime = restockGoldActiveSpell.startTime

        local timeLeft = startTime + script.config.restockGoldSeconds - os.time()

        local minutesToRestock = math.floor(timeLeft / 60)
        local secondsToRestock = timeLeft % 60
        local minutesToRestockStr = tostring(minutesToRestock)
        local secondsToRestockStr = tostring(secondsToRestock)

        if timeLeft == 0 then
            return messages.restockingGoldSoon
        elseif minutesToRestock > 1 and secondsToRestock > 1 then
            return string.format(messages.restockingGoldInMinutesSeconds, minutesToRestockStr, secondsToRestockStr)
        elseif minutesToRestock > 1 and secondsToRestock == 1 then
            return string.format(messages.restockingGoldInMinutesSecond, minutesToRestockStr)
        elseif minutesToRestock == 1 and secondsToRestock == 1 then
            return messages.restockingGoldInMinuteSecond
        elseif secondsToRestock > 1 then
            return string.format(messages.restockingGoldInSeconds, secondsToRestockStr)
        else
            return messages.restockingGoldInSecond
        end
    end

    -- Determines whether the merchant's gold should be restocked
    function script.ShouldRestockGold(cell, uniqueIndex)

        -- Check if current gold amount is greater than or equal to initial
        if not script.HasGoldRestocked(cell, uniqueIndex) then
            return true
        end

        return false
    end

    function script.OnActorSpellsActiveHandler(eventStatus, pid, cellDescription, actors)
        local cell = LoadedCells[cellDescription]

        if cell == nil then return end

        for uniqueIndex, actor in pairs(actors) do
            for spellId, spell in pairs(actor.spellsActive) do
                if actor.spellActiveChangesAction == enumerations.spellbook.REMOVE then
                    if spellId == script.spellRecords.restockGold.id then
                        -- Restock gold if appropriate
                        if script.ShouldRestockGold(cell, uniqueIndex) then
                            script.RestockGold(pid, cell, uniqueIndex)
                        end
                    end
                end
            end
        end
    end
else
    script.messages.restockingGoldInDaysHours = "I will be restocking gold in %s days and %s hours."
    script.messages.restockingGoldInDaysHour = "I will be restocking gold in %s days and 1 hour."
    script.messages.restockingGoldInDayHours = "I will be restocking gold in 1 day and %s hours."
    script.messages.restockingGoldInDayHour = "I will be restocking gold in 1 day and 1 hour."
    script.messages.restockingGoldInHours = "I will be restocking gold in %s hours."
    script.messages.restockingGoldInHour = "I will be restocking gold in 1 hour."

    script.spellRecords = {}
    script.spellRecords.restockGold = {
        id = "restock_gold_signal",
        data = {
            name = "Restock Gold Signal",
            flags = 4,
            cost = 0,
            subtype = 0,
            effects = {
                {
                    attribute = -1,
                    area = 0,
                    duration = 1,
                    id = 79, -- Fortify attribute
                    rangeType = 0,
                    skill = -1,
                    magnitudeMin = 0, -- Do not actually harm or buff the target
                    magnitudeMax = 0 -- Do not actually harm or buff the target
                }
            }
        }
    }

    function script.GetDisplayRestockGoldInfo(cell, uniqueIndex)
        local messages = script.messages

        if script.HasGoldRestocked(cell, uniqueIndex) then
            return messages.restockedGold
        end

        local currentDay = script.GetCurrentDay()
        local currentHour = script.GetCurrentHour()
        local goldRestockDay, goldRestockHour = script.GetGoldRestockDayHour(cell, uniqueIndex)

        local hoursToRestockCount = (goldRestockDay - currentDay) * 24 - currentHour + goldRestockHour
        local daysToRestockCount = math.floor(hoursToRestockCount / 24)
        local hoursToRestockCountStr = tostring(hoursToRestockCount)
        local daysToRestockCountStr = tostring(daysToRestockCount)

        if currentDay == goldRestockDay and currentHour == goldRestockHour then
            return messages.restockingGoldSoon
        elseif daysToRestockCount == 1 and hoursToRestockCount == 1 then
            return messages.restockingGoldInDayHour
        elseif daysToRestockCount > 1 and hoursToRestockCount > 1 then
            return string.format(messages.restockingGoldInDaysHours, daysToRestockCountStr, hoursToRestockCountStr)
        elseif daysToRestockCount > 1 and hoursToRestockCount == 1 then
            return string.format(messages.restockingGoldInDaysHour, daysToRestockCountStr)
        elseif daysToRestockCount == 1 and hoursToRestockCount > 1 then
            return string.format(messages.restockingGoldInDayHours, hoursToRestockCountStr)
        elseif hoursToRestockCount > 1 then
            return string.format(messages.restockingGoldInHours, hoursToRestockCountStr)
        end

        return messages.restockingGoldInHour
    end

    function script.GetGoldRestockDayHour(cell, uniqueIndex)
        local goldRestockHour = math.floor(script.GetLastGoldRestockHour(cell, uniqueIndex) +
            script.config.restockGoldHours)
        local goldRestockDay = script.GetLastGoldRestockDay(cell, uniqueIndex) + script.config.restockGoldDays

        goldRestockDay = goldRestockDay + math.floor(goldRestockHour / 24)
        goldRestockHour = goldRestockHour % 24

        return goldRestockDay, goldRestockHour
    end

    -- Determines whether the merchant's gold should be restocked
    function script.ShouldRestockGold(cell, uniqueIndex)

        -- First check if current gold amount is greater than or equal to initial
        if not script.HasGoldRestocked(cell, uniqueIndex) then

            -- Second check if enough time has passed
            local currentDay = script.GetCurrentDay()
            local currentHour = script.GetCurrentHour()
            local restockDay, restockHour = script.GetGoldRestockDayHour(cell, uniqueIndex)

            if restockDay <= currentDay and restockHour <= currentHour then
                return true
            end
        end

        return false
    end

    function script.OnActorSpellsActiveHandler(eventStatus, pid, cellDescription, actors)
        local cell = LoadedCells[cellDescription]

        if cell == nil then return end

        for uniqueIndex, actor in pairs(actors) do
            for spellId, spell in pairs(actor.spellsActive) do
                if actor.spellActiveChangesAction == enumerations.spellbook.REMOVE then
                    if spellId == script.spellRecords.restockGold.id then
                        -- Restock gold if appropriate, otherwise re-apply the gold restock spell
                        if script.ShouldRestockGold(cell, uniqueIndex) then
                            script.RestockGold(pid, cell, uniqueIndex)
                        else
                            script.ApplyRestockGoldSpell(pid, cell, uniqueIndex)
                        end
                    end
                end
            end
        end
    end
end

function script.DelayDisplayRestockGoldInfo(pid, cell, uniqueIndex)

    local messageRestockGold = script.GetDisplayRestockGoldInfo(cell, uniqueIndex)

    local timerDelayedRestockInfo = tes3mp.CreateTimerEx("DisplayDelayedRestockGoldInfo", 100, "is", pid,
        messageRestockGold)
    tes3mp.StartTimer(timerDelayedRestockInfo)
end

function DisplayDelayedRestockGoldInfo(pid, messageRestockGold)
    if Players[pid] == nil or not Players[pid]:IsLoggedIn() then return end

    tes3mp.MessageBox(pid, -1, messageRestockGold)
end

-- Server record will be created at each OnServerInit, because this seems
-- as the simpliest way of keeping it up to date with config changes
function script.CreateSpellRecords()
    local recordStore = RecordStores["spell"]

    recordStore.data.permanentRecords[script.spellRecords.restockGold.id] = tableHelper.deepCopy(script.spellRecords.restockGold
        .data)
    recordStore:QuicksaveToDrive()
end

-- Add the restock spell to actor's active spell
function script.AddRestockGoldActorSpellActive(cell, uniqueIndex)
    local spellRecord = script.spellRecords.restockGold
    local spellEffect = spellRecord.data.effects[1]

    local actor = {}
    actor.uniqueIndex = uniqueIndex
    actor.spellsActive = {}

    local spellId = spellRecord.id
    actor.spellsActive[spellId] = {}
    actor.spellActiveChangesAction = enumerations.spellbook.ADD

    local spellInstance = {
        effects = {
            {
                arg = -1,
                duration = spellEffect.duration,
                id = spellEffect.id,
                timeLeft = spellEffect.duration,
                magnitude = 0
            }
        },
        displayName = spellRecord.data.name,
        stackingState = false,
        startTime = os.time(),
        caster = {
            uniqueIndex = uniqueIndex,
            refId = cell.data.objectData[uniqueIndex].refId
        }
    }

    table.insert(actor.spellsActive[spellId], spellInstance)

    cell:SaveActorSpellsActive({ [uniqueIndex] = actor })

    return spellInstance.effects[1]
end

-- Load the previously added spell also client-side
function script.LoadRestockGoldActorSpellActive(pid, cell, uniqueIndex, effectTable)
    local spellRecord = script.spellRecords.restockGold
    tes3mp.ClearActorList()
    tes3mp.SetActorListPid(pid)
    tes3mp.SetActorListCell(cell.description)

    local splitIndex = uniqueIndex:split("-")
    tes3mp.SetActorRefNum(splitIndex[1])
    tes3mp.SetActorMpNum(splitIndex[2])

    tes3mp.SetActorSpellsActiveAction(enumerations.spellbook.ADD)

    tes3mp.AddActorSpellActiveEffect(effectTable.id, effectTable.magnitude,
        effectTable.duration, effectTable.timeLeft, effectTable.arg)
    tes3mp.AddActorSpellActive(spellRecord.id, spellRecord.data.name, false)
    tes3mp.AddActor()

    tes3mp.SendActorSpellsActiveChanges()
end

-- Add restock spell to actor's active spells and load it for the clients
function script.ApplyRestockGoldSpell(pid, cell, uniqueIndex)
    local effectTable = script.AddRestockGoldActorSpellActive(cell, uniqueIndex)
    script.LoadRestockGoldActorSpellActive(pid, cell, uniqueIndex, effectTable)
end

-- Store the initialGoldPool attribute inside the object's data
function script.SaveInitialGoldPool(cell, uniqueIndex, goldPool)
    local merchantObjectData = cell.data.objectData[uniqueIndex]
    merchantObjectData.initialGoldPool = goldPool
    cell:QuicksaveToDrive()
end

function script.GetCurrentHour()
    return math.floor(WorldInstance.data.time.hour)
end

function script.GetCurrentDay()
    return WorldInstance.data.time.daysPassed
end

function script.GetLastGoldRestockDay(cell, uniqueIndex)
    return cell.data.objectData[uniqueIndex].lastGoldRestockDay
end

function script.GetLastGoldRestockHour(cell, uniqueIndex)
    return cell.data.objectData[uniqueIndex].lastGoldRestockHour
end

function script.GetInitialGoldPool(cell, uniqueIndex)
    return cell.data.objectData[uniqueIndex].initialGoldPool
end

function script.GetCurrentGoldPool(cell, uniqueIndex)
    return cell.data.objectData[uniqueIndex].goldPool
end

function script.HasInitialGoldPool(cell, uniqueIndex)
    return script.GetInitialGoldPool(cell, uniqueIndex) ~= nil
end

function script.HasGoldRestocked(cell, uniqueIndex)
    return script.GetCurrentGoldPool(cell, uniqueIndex) >= script.GetInitialGoldPool(cell, uniqueIndex)
end

function script.GetRestockGoldActiveSpell(cell, uniqueIndex)
    local merchantSpellsActive = cell.data.objectData[uniqueIndex].spellsActive
    local spellId = script.spellRecords.restockGold.id
    return merchantSpellsActive[spellId][1]
end

function script.HasRestockGoldSpellActive(cell, uniqueIndex)
    local merchantSpellsActive = cell.data.objectData[uniqueIndex].spellsActive
    local spellId = script.spellRecords.restockGold.id

    if merchantSpellsActive ~= nil and merchantSpellsActive[spellId] ~= nil and merchantSpellsActive[spellId][1] ~= nil then
        return true
    end

    return false
end

-- Hijacked the log message from original coreScripts
-- Found it imporant to inform in the consistent manner of the restock
function script.RestockGold(pid, cell, uniqueIndex)
    local merchantObjectData = cell.data.objectData[uniqueIndex]
    merchantObjectData.goldPool = merchantObjectData.initialGoldPool
    merchantObjectData.lastGoldRestockDay = script.GetCurrentDay()
    merchantObjectData.lastGoldRestockHour = script.GetCurrentHour()

    cell:QuicksaveToDrive()
    cell:LoadObjectsMiscellaneous(pid, cell.data.objectData, { uniqueIndex }, true)

    tes3mp.LogMessage(enumerations.log.INFO,
        "[RestockMerchantsGold] " .. uniqueIndex .. ", refId: " .. merchantObjectData.refId ..
        ", goldPool: " ..
        merchantObjectData.goldPool .. ", lastGoldRestockHour: " .. merchantObjectData.lastGoldRestockHour ..
        ", lastGoldRestockDay: " .. merchantObjectData.lastGoldRestockDay)
end

function script.OnServerPostInitHandler(eventStatus)
    tes3mp.LogMessage(enumerations.log.INFO, "[RestockMerchantsGold] Running...")
    script.CreateSpellRecords()
end

-- Adjust last restock day and hour if needed, that value then gets passed into respective handler and saved
function script.OnObjectMiscellaneousValidator(eventStatus, pid, cellDescription, objects, targetPlayers)
    local cell = LoadedCells[cellDescription]

    if cell == nil then return end

    for uniqueIndex, object in pairs(objects) do
        -- Adjust last restock day and hour
        if object.goldPool ~= nil then
            if not script.HasInitialGoldPool(cell, uniqueIndex) then
                script.SaveInitialGoldPool(cell, uniqueIndex, object.goldPool)
            else
                local lastGoldRestockDay = script.GetLastGoldRestockDay(cell, uniqueIndex)
                local lastGoldRestockHour = script.GetLastGoldRestockHour(cell, uniqueIndex)

                local goldPool = script.GetCurrentGoldPool(cell, uniqueIndex)
                local initialGoldPool = script.GetInitialGoldPool(cell, uniqueIndex)

                if object.goldPool < initialGoldPool and
                    (goldPool >= initialGoldPool or not script.HasRestockGoldSpellActive(cell, uniqueIndex)) then
                    lastGoldRestockDay = script.GetCurrentDay()
                    lastGoldRestockHour = script.GetCurrentHour()
                    script.ApplyRestockGoldSpell(pid, cell, uniqueIndex)
                end

                object.lastGoldRestockDay = lastGoldRestockDay
                object.lastGoldRestockHour = lastGoldRestockHour
            end
        end
    end
end

function script.OnObjectActivateHandler(eventStatus, pid, cellDescription, objects, targetPlayers)
    local cell = LoadedCells[cellDescription]
    if cell == nil then return end

    for uniqueIndex, object in pairs(objects) do
        if script.HasInitialGoldPool(cell, uniqueIndex) then
            script.DelayDisplayRestockGoldInfo(pid, cell, uniqueIndex)
        end
    end
end

customEventHooks.registerValidator("OnObjectMiscellaneous", script.OnObjectMiscellaneousValidator)

customEventHooks.registerHandler("OnServerPostInit", script.OnServerPostInitHandler)
customEventHooks.registerHandler("OnObjectActivate", script.OnObjectActivateHandler)
customEventHooks.registerHandler("OnActorSpellsActive", script.OnActorSpellsActiveHandler)
