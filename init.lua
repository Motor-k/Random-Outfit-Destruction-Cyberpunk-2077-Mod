-- init.lua for Random_outfit_damage v1.2.1 by Himawarin
-- Cyberpunk 2077 v2.21 + CET v1.35.0
-- Removes random equipment (visual-only clothing) on damage taken.

-- grab settings for gui default values
require ("data/settings.lua")

-- get list of valid items from external file
require("data/slots.lua")

function removeRandomWardrobeItems()
    -- get player instance
    local player = Game.GetPlayer()
    if not player then return end

    -- Grab the TransactionSystem *instance*
    local tsys = Game.GetTransactionSystem()
    if not tsys or type(tsys.GetItemInSlot) ~= "function" then
        print("[WardrobeMod] ERROR: TransactionSystem:GetItemInSlot unavailable")
        return
    end

    -- debug trigger counter
    if debugrod then triggers = triggers+1 end

    -- create a temporary list of all outfit slots removed
    local removelist = {}

    -- count how many outfits were removed
    local removed = 0
    
    -- find currently equiped items and if one is found try to break them acording to the rate (Partial credit: ripperdoc (nexusmods))
    for i = 1, ExSlots_Count do
        local slotName = ExSlots[i]       -- e.g. "OutfitSlots.Head"
        local slotTDB  = SLOTS[slotName]   -- your TweakDBID.new(slotName)

        -- Query the mount-in-slot via the *instance* method
        local itemObj = tsys:GetItemInSlot(player, slotTDB)   -- ref<ItemObject>

        -- if the item is valid and being worn
        if itemObj then
            -- Get the ItemID struct from the ItemObject
            local itemID   = itemObj:GetItemID()              -- CItemID 
            -- Convert to the actual TweakDBID string
            local tdbPath  = itemID:GetTDBID()                -- CName
            if math.random() < (rate/100) and removed < limit then
                EquipmentEx.UnequipSlot(slotName)
                table.insert(removelist, tostring(tdbPath.value))
                removed = removed+1

                -- debug activation counter
                if debugrod then activations = activations+1 end

            end
        end
    end

    -- return string of items removed
    return table.concat(removelist)

end

-- Main event registrations
registerForEvent("onInit", function()
    math.randomseed(os.time())  -- seed RNG once
    debugrod = false
    outfitSaved = false
    itemlist = ""
    hpdelta = 0
    triggers = 0
    activations = 0
    bvents = 0
    openwindow = true
    -- Build eex slots cache (Credit: ripperdoc (nexusmods))
    if ExSlots and type(ExSlots) == "table" and #ExSlots > 0 then
        ExSlots_Count = #ExSlots
    end

    local total_slots_count = 0
    SLOTS = { }
    for i = 1, ExSlots_Count do
        local slot_name = ExSlots[i]
        local record = TweakDB:GetRecord(slot_name)
        if record then
            SLOTS[slot_name] = TweakDBID.new(slot_name)
            total_slots_count = total_slots_count + 1
        end
    end

    -- OnEnterSafeZone for finding if player is at home
    ObserveAfter('PlayerPuppet', 'OnEnterSafeZone',function(self)
        -- repair outfit 
        if outfitSaved and repairOnSafezone then
            EquipmentEx.LoadOutfit("00codeoutfit temp")
            itemlist = "Outfit Repaired [Safezone]"
            outfitSaved = false
            -- debug to reset events counter
            if debugrod then
                bvents = 0
                activations = 0
                triggers = 0
            end
        end
    end)

    -- when player enters a vehicle (state 1 = driving)
    ObserveAfter("PlayerPuppet", "OnVehicleStateChange", function(self, state)
        -- check if the player is inside the car and driving
        if state == 1 then
            -- repair outfit 
            if outfitSaved and repairOnVehicle then
                EquipmentEx.LoadOutfit("00codeoutfit temp")
                itemlist = "Outfit Repaired [Vehicle]"
                outfitSaved = false
                -- debug to reset events counter
                if debugrod then
                    bvents = 0
                    activations = 0
                    triggers = 0
                end
            end
        end
    end)

    -- when hp changes
    ObserveAfter("PlayerPuppet", "OnHealthUpdateEvent", function(self, hitEvent)
        -- save the current outfit
        if not outfitSaved then
            EquipmentEx.SaveOutfit("00codeoutfit temp")
            outfitSaved = true
        end

        -- Grab the player and StatsSystem
        local player   = Game.GetPlayer()
        local statsSys = Game.GetStatsSystem()
        if not player or not statsSys then return end

        local eid = player:GetEntityID()

        -- Query maximum Health (your HP cap) and delta after hit
        -- hpmax = statsSys:GetStatValue(eid, gamedataStatType.Health)
        hpdelta = math.abs(hitEvent.healthDifference)
        
        -- debug for health update damage triggers total
        if hpdelta > damagetrigger and debugrod then bvents = bvents+1 end 

        -- % trigger chance
        if math.random() < (trigger/100) and hpdelta > damagetrigger then
            itemlist = removeRandomWardrobeItems()
        end
    end)
end)

-- drawbuffer
registerForEvent("onDraw", function()
    -- if list and bar are hidden hide everything
    if nolist and nobar then
        -- hide the window
        ImGui.Begin("Random Outfit Destruction", false)
        ImGui.End()
        return
    end

    -- draw the window
    ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, 360, 260)
    if not ImGui.Begin("Random Outfit Destruction", true, ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoBackground) then
    ImGui.End()
    return
    end

    ImGui.Spacing()

    -- draw the settings menu
    if not nobar then
        if ImGui.SmallButton("Hide settings", -1, 0) and not nobar then
            nobar = true
            -- save settings when hiding
            local f = assert(io.open("data/settings.lua", "w"))
            f:write("rate = "..rate.." trigger = "..trigger.." damagetrigger = "..damagetrigger.." limit = "..limit.." repairOnVehicle = "..tostring(repairOnVehicle).." repairOnSafezone = "..tostring(repairOnSafezone))
            f:close()
            Print("Settings saved to data/settings.lua")
        end

        ImGui.NewLine()

        rate = ImGui.SliderInt(" % rate", rate, 0, 100, "%d")
        if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Choose the probability of an outfit piece breaking in % during a break event")
        end

        trigger = ImGui.SliderInt(" % trigger", trigger, 0, 100, "%d")
        if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Choose the probability of damage triggering a break event")
        end

        damagetrigger = ImGui.InputInt("Damage trigger", damagetrigger, 1, 10)
        if ImGui.IsItemHovered() then
        ImGui.SetTooltip("How much damage delta (damage taken) before you can try to trigger a break event")
        end

        limit = ImGui.InputInt("Limit", limit, 1, 10)
        if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Maximum amount of pieces removable in a break event")
        end

        repairOnVehicle = ImGui.Checkbox("Repair on Vehicle", repairOnVehicle)

        ImGui.SameLine()

        repairOnSafezone = ImGui.Checkbox("Repair on Safezone", repairOnSafezone)
        ImGui.NewLine()
    end

    -- draw the removed outfit list (that shows last broken outfit(s))
    if not nolist then
        if ImGui.SmallButton("Hide list", -1, 0) then
            nolist = true
        end
        ImGui.NewLine()
        
        -- debug code to show break event telemetry
        if not debugrod then
            ImGui.Text("Removed items:")
        else
            ImGui.Text("Break atempts: "..bvents.." | Triggers: "..triggers.." | Activations : "..activations.." | Removed items:")
        end

        --list of destroyed items
        ImGui.TextWrapped(itemlist)
    end

    ImGui.End()

end)