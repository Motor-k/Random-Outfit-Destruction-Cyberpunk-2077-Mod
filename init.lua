-- init.lua for Random_outfit_damage v1.4.1 by Himawarin
-- Cyberpunk 2077 v2.3 + CET v1.36.0
-- Removes random equipment (visual-only clothing) on damage taken to simulate combat damage.

-- grab settings for gui default values
require ("data/settings.lua")

-- get list of valid items from external file
require("data/slots.lua")

-- Get every saved Equipment-EX outfit name in CET
function getRandomLoadout(mode, zone)
    if mode == "random" then
        -- Grab the Scriptable Systems Container (this is how equipment ex extends the wardrobe functionality)
        local ssc = Game.GetScriptableSystemsContainer()

        -- Retrieve the OutfitSystem by its registered name (as per OutfitSystem.GetInstance() in Equipment-EX)
        local outfitSystem = ssc:Get(CName.new("EquipmentEx.OutfitSystem"))
        if not outfitSystem or type(outfitSystem.GetOutfits) ~= "function" then
            print("[WardrobeMod] ERROR: Unable to access OutfitSystem:GetOutfits()")
            return
        end

        -- Call GetOutfits() to get an array of CName entries
        local outfitNames = outfitSystem:GetOutfits()

        -- validate
        if outfitNames then
            local tempoutfit = NameToString(outfitNames[math.random(#outfitNames)])
            -- unequip to prevent ctd due to flat shoes interactions with socks
            EquipmentEx.UnequipAll()
            EquipmentEx.LoadOutfit(tempoutfit)
            return string.format("[%s] Equipped: %s",zone, tempoutfit)
        end
    elseif mode == "repair" then
        -- unequip to prevent ctd due to flat shoes interactions with socks
        EquipmentEx.UnequipAll()
        EquipmentEx.LoadOutfit("00 - ROD Current Outfit")
        return string.format("[%s] Outfit Repaired", zone)
    else
        print "The user has no Loadouts"
    end
end

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
                -- save the current outfit
                if not outfitSaved then
                    EquipmentEx.SaveOutfit("00 - ROD Current Outfit")
                    outfitSaved = true
                end

                -- remove and add to list
                EquipmentEx.UnequipSlot(slotName)
                table.insert(removelist, {tostring(tdbPath.value), tostring(slotTDB.value)})
                removed = removed+1

                -- debug activation counter
                if debugrod then activations = activations+1 end
            end
        end
    end

    -- list all currently removed items when a break event happens
    local etb = {}
    for i=1,#removelist do
        etb[i] = string.format("%s \n",removelist[i][1])
    end

    -- return string of items removed
    return table.concat(etb)

end

-- Main event registrations
registerForEvent("onInit", function()
    math.randomseed(os.time())  -- seed RNG once
    outfitSaved = false
    removelist = {}
    itemlist = ""
    hpdelta = 0
    -- debug vars
    debugrod = false
    triggers = 0
    activations = 0
    bvents = 0
    -- stop double triggers
    lockstate = false
    frametimer = 0

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
            -- if we got a random loadout we equip that loadout otherwise we repair the outfit
            if random then
                itemlist = getRandomLoadout("random","Safezone")
            else
                itemlist = getRandomLoadout("repair","Safezone")
            end
            removelist = {} 
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
            -- get player instance
            local player = Game.GetPlayer()
            if not player then return end

            -- Grab the TransactionSystem *instance*
            local tsys = Game.GetTransactionSystem()
            if not tsys or type(tsys.GetItemInSlot) ~= "function" then
                print("[WardrobeMod] ERROR: TransactionSystem:GetItemInSlot unavailable")
                return
            end

            -- repair outfit 
            if outfitSaved and repairOnVehicle then
                -- if we got a random loadout we equip that loadout otherwise we repair the outfit
                if random then
                    itemlist = getRandomLoadout("random","Vehicle")
                else
                    itemlist = getRandomLoadout("repair","Vehicle")
                end
                removelist = {}   
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

    -- Immersive clothing recovery: when player picks item
    ObserveAfter("PlayerPuppet", "OnItemAddedToInventory", function(_, event)
        local data     = event.itemData
        local itemType = data:GetItemType()

        -- Option A: parse via string.match
        local rawType  = tonumber(string.match(tostring(itemType), "%d+"))
        -- when player picks a outfit type
        if rawType and rawType >= 0 and rawType <= 6 and next(removelist) ~= nil then
            local index = math.random(#removelist)
            itemlist = string.format("[EquipFix] equipped %s",removelist[index][1])
            EquipmentEx.EquipItem(removelist[index][1], removelist[index][2])
            table.remove(removelist, index)
        -- when player picks a crafting type
        elseif rawType == 27 and next(removelist) ~= nil then
            -- 30% chance to repair
            if math.random() < (0.30) then
                local index = math.random(#removelist)
                itemlist = string.format("[CraftFix] equipped %s",removelist[index][1])
                EquipmentEx.EquipItem(removelist[index][1], removelist[index][2])
                table.remove(removelist, index)
            end
        -- if everything is fixed disable unecessary repairs
        elseif next(removelist) == nil then
            outfitSaved = false
        end
    end)

    -- when player gets hit by vehicle (ChargedWhipAttack = 0)
    ObserveAfter("PlayerPuppet", "OnHitAnimation", function(self, hitEvent)
        local state = string.match(tostring(hitEvent.attackData.attackType),"%d+")
        if state == "0" then
            if not lockstate then
                lockstate = true
                itemlist = removeRandomWardrobeItems()
            end
        end
    end)

    -- when hp changes
    ObserveAfter("PlayerPuppet", "OnHealthUpdateEvent", function(self, hitEvent)
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
            -- to prevent double triggers
            if not lockstate then
                lockstate = true
                itemlist = removeRandomWardrobeItems()
            end
        end
    end)
end)

-- drawbuffer
registerForEvent("onDraw", function()
    -- timer for lockstate
    if lockstate and frametimer < 180 then
        frametimer = frametimer+1
    else
        lockstate = false
        frametimer = 0
    end

    -- if list and bar are hidden hide everything
    if nolist and nobar then
        -- hide the window
        ImGui.Begin("Random Outfit Destruction", false)
        ImGui.End()
        return
    end

    -- prevent tab navigation (a known focus bug happens otherwise)
    ImGui.PushItemFlag(ImGuiItemFlags.NoTabStop, true)
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
            f:write("rate = "..rate.." trigger = "..trigger.." damagetrigger = "..damagetrigger.." limit = "..limit.." random = "..tostring(random).." repairOnVehicle = "..tostring(repairOnVehicle).." repairOnSafezone = "..tostring(repairOnSafezone))
            f:close()
            Print("Settings saved to data/settings.lua")
        end

        ImGui.NewLine()

        random = ImGui.Checkbox("Randomize", random)
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip("Choose a random outfit when the player gets to the vehicle or safezone")
        end

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
        
        ImGui.SameLine()

        if ImGui.SmallButton("Get Random Outfit", -1, 0) then
            -- lockstate to prevent bugged outfits
            if not lockstate then
                lockstate = true
                itemlist = getRandomLoadout("random","Random")
                removelist = {}
                if outfitSaved then
                    outfitSaved = false
                end
            end
        end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip("Choose a random outfit and equip it")
        end

        ImGui.NewLine()

        -- debug code to show break event telemetry
        if not debugrod then
            ImGui.Text("Removed items:")
        else
            ImGui.Text("Break atempts: "..bvents.." | Triggers: "..triggers.." | Activations : "..activations.."\nRemoved items:")
        end

        --list of destroyed items
        ImGui.TextWrapped(itemlist)

    end

    ImGui.End()

end)