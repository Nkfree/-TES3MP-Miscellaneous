--[[
=====================================
| author: Nkfree                    |
| github: https://github.com/Nkfree |
===============================================================================================================================================|
| installation:                                                                                                                                |
|   1. Create a folder crouchOnPouch in <tes3mp>/server/scripts/custom                                                                         |
|   2. Add main.lua in that created folder                                                                                                     |
|   3. Open customScripts.lua and put there this line: require("custom.crouchOnPouch.main")                                                    |
|   4. Save customScripts.lua and launch the server                                                                                            |
|   5. To confirm the script is running fine, you should see "[CrouchOnPouch] Running..." among the first few lines of server console          |
================================================================================================================================================
]]

local main = {}

main.IsLoggedIn = function(pid)
    return Players[pid] ~= nil and Players[pid]:IsLoggedIn()
end

main.IsStandingStill = function(pid)
    local lastPosX = Players[pid].crouchOnPouch.lastKnownPosition.posX
    local lastPosY = Players[pid].crouchOnPouch.lastKnownPosition.posY
    local lastPosZ = Players[pid].crouchOnPouch.lastKnownPosition.posZ
    local lastRotX = Players[pid].crouchOnPouch.lastKnownPosition.rotX
    local lastRotZ = Players[pid].crouchOnPouch.lastKnownPosition.rotZ

    if lastPosX ~= tes3mp.GetPosX(pid) then return false end
    if lastPosY ~= tes3mp.GetPosY(pid) then return false end
    if lastPosZ ~= tes3mp.GetPosZ(pid) then return false end
    if lastRotX ~= tes3mp.GetRotX(pid) then return false end
    if lastRotZ ~= tes3mp.GetRotZ(pid) then return false end

    return true
end

crouch_on_pouch_periodic_reset_sneak = function(pid)
    if not main.IsLoggedIn(pid) then return end

    if not main.IsStandingStill(pid) then
        logicHandler.RunConsoleCommandOnPlayer(pid, "ClearForceSneak", true)
        Players[pid].crouchOnPouch = nil
        return
    end

    tes3mp.RestartTimer(Players[pid].crouchOnPouch.resetSneakTimer, 100)
end

main.OnServerPostInitHandler = function(eventStatus)
    tes3mp.LogMessage(enumerations.log.INFO, "[CrouchOnPouch] Running...")
end

main.OnObjectActivateHandler = function(eventStatus, pid, cellDescription, objects, targetPlayers)
    if not main.IsLoggedIn(pid) or tes3mp.GetSneakState(pid) then return end

    local shouldSneak = false
    
    for uniqueIndex, _ in pairs(objects) do
        if not tableHelper.containsValue(LoadedCells[cellDescription].data.packets.container, uniqueIndex) then return end
        if tableHelper.containsValue(LoadedCells[cellDescription].data.packets.actorList) and not tableHelper.containsValue(LoadedCells[cellDescription].data.packets.death, uniqueIndex) then return end

        shouldSneak = true
    end

    if not shouldSneak then return end

    logicHandler.RunConsoleCommandOnPlayer(pid, "ForceSneak", true)

    Players[pid].crouchOnPouch = {
        lastKnownPosition = nil,
        resetSneakTimer = nil
    }

    Players[pid].crouchOnPouch.lastKnownPosition = {
        posX = tes3mp.GetPosX(pid),
        posY = tes3mp.GetPosY(pid),
        posZ = tes3mp.GetPosZ(pid),
        rotX = tes3mp.GetRotX(pid),
        rotZ = tes3mp.GetRotZ(pid)
    }

    Players[pid].crouchOnPouch.resetSneakTimer = tes3mp.CreateTimerEx("crouch_on_pouch_periodic_reset_sneak", 1000, "i", pid)
    tes3mp.StartTimer(Players[pid].crouchOnPouch.resetSneakTimer)
end

customEventHooks.registerHandler("OnServerPostInit", main.OnServerPostInitHandler)
customEventHooks.registerHandler("OnObjectActivate", main.OnObjectActivateHandler)
