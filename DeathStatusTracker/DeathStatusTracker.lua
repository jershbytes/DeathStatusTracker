local addonName, ns = ...

-- Define defaults first
local defaults = {
    posX = 0,
    posY = 0,
    font = "GameFontNormal",
    scale = 1.0,
    fontSize = 12,
    showSolo = true,
    colors = {
        ALIVE = {0, 1, 0},
        DEAD = {1, 0, 0},
        OFFLINE = {0.7, 0.7, 0.7},
    }
}

-- Create the main tracker frame
local frame = CreateFrame("Frame", "DeadStatusTrackerFrame", UIParent)
frame:SetSize(200, 300)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetFrameStrata("MEDIUM")
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, xOfs, yOfs = self:GetPoint()
    DeathStatusTrackerDB.posX = xOfs
    DeathStatusTrackerDB.posY = yOfs
end)

-- Create backdrop using the new method for Dragonflight
local backdropFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
backdropFrame:SetAllPoints(frame)
backdropFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
backdropFrame:SetBackdropColor(0.05, 0.05, 0.07, 0.6) -- Lighter dark blue with less opacity
backdropFrame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8) -- Lighter border color

-- For newer API (Shadowlands+)
local backdrop = {
  backgroundFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  backgroundInsets = { left = 11, right = 12, top = 12, bottom = 11 },
  backgroundColor = CreateColor(0, 0, 0, 0.3), -- More transparent background (0.3 alpha)
  borderFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  borderColor = CreateColor(1, 1, 1, 0.5),
  borderSize = 32,
}

frame:SetBackdrop(backdrop)

-- Add header text with explicit bright coloring
local headerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
headerText:SetPoint("TOPLEFT", 10, -10)
headerText:SetText("Group Status")
headerText:SetTextColor(1, 1, 1, 1) -- Pure white
headerText:SetFont(headerText:GetFont(), 14, "OUTLINE") -- Add outline to make it pop

-- Create storage for member texts
local memberTexts = {}

-- Create summary texts
local summaryTexts = {
    alive = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
    roles = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
}
summaryTexts.alive:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 25)
summaryTexts.roles:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)

-- Add role icons
local roleIcons = {
    TANK = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:0:19:22:41|t",
    HEALER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:1:20|t",
    DAMAGER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:22:41|t",
    NONE = ""
}

-- For summary display, make icons slightly smaller
local summaryRoleIcons = {
    TANK = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:12:12:0:0:64:64:0:19:22:41|t",
    HEALER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:12:12:0:0:64:64:20:39:1:20|t",
    DAMAGER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:12:12:0:0:64:64:20:39:22:41|t"
}

-- Enhanced shadow function with lighter shadow and stronger outline
local function ApplyTextEnhancement(fontString)
    local font, size, flags = fontString:GetFont()
    fontString:SetFont(font, size, "THICKOUTLINE") -- Use THICKOUTLINE for better visibility
    fontString:SetShadowColor(0, 0, 0, 0.7) -- Reduce shadow opacity
    fontString:SetShadowOffset(1.5, -1.5) -- Slightly larger offset
end

-- Apply shadow to header
ApplyTextEnhancement(headerText)

-- Create a function to check if the frame should be visible
local function ShouldShowTracker()
    -- If disabled manually with /dst hide, respect that setting
    if DeathStatusTrackerDB.hidden then
        return false
    end
    
    -- Check group status and settings
    local inGroup = IsInGroup() or IsInRaid()
    return inGroup or DeathStatusTrackerDB.showSolo
end

-- Create a function to update visibility
local function UpdateVisibility()
    if ShouldShowTracker() then
        DeadStatusTrackerFrame:Show()
    else
        DeadStatusTrackerFrame:Hide()
    end
end

-- Update logic
local function UpdateStatus()
    local groupType = IsInRaid() and "raid" or "party"
    local numMembers = GetNumGroupMembers()
    
    -- Initialize counters
    local aliveCount = 0
    local totalCount = 0
    local tankCount = 0
    local totalTanks = 0
    local healerCount = 0
    local totalHealers = 0
    local dpsCount = 0
    local totalDPS = 0
    
    -- Create player entry if it doesn't exist
    if not memberTexts[1] then
        memberTexts[1] = frame:CreateFontString(nil, "OVERLAY", DeathStatusTrackerDB.font or "GameFontNormal")
        memberTexts[1]:SetPoint("TOPLEFT", 10, -30)
    end
    
    -- Always display player status first
    local playerName = UnitName("player")
    local playerStatus = UnitIsDeadOrGhost("player") and "DEAD" or "ALIVE"
    local playerRole = UnitGroupRolesAssigned("player")
    local isPlayerAlive = playerStatus == "ALIVE"
    
    -- Set player entry
    local roleIcon = roleIcons[playerRole] or roleIcons.NONE
    memberTexts[1]:SetFontObject(DeathStatusTrackerDB.font or "GameFontNormal")
    local font, _, flags = memberTexts[1]:GetFont()
    memberTexts[1]:SetFont(font, DeathStatusTrackerDB.fontSize or 12, flags)
    memberTexts[1]:SetText(roleIcon .. " " .. playerName .. " (You): " .. playerStatus)
    
    -- Set player text color with enhanced brightness
    local r, g, b = 1, 1, 1
    if playerStatus == "ALIVE" then
        r, g, b = 0, 1, 0.3 -- Brighter, more vibrant green
    elseif playerStatus == "DEAD" then
        r, g, b = 1, 0.3, 0.3 -- Brighter red
    elseif playerStatus == "OFFLINE" then
        r, g, b = 0.9, 0.9, 0.9 -- Almost white for offline
    end
    memberTexts[1]:SetTextColor(r, g, b)
    
    -- Apply shadow to player text
    ApplyTextEnhancement(memberTexts[1])
    
    -- Update player counters
    totalCount = 1
    if isPlayerAlive then aliveCount = 1 end
    
    if playerRole == "TANK" then
        totalTanks = 1
        if isPlayerAlive then tankCount = 1 end
    elseif playerRole == "HEALER" then
        totalHealers = 1
        if isPlayerAlive then healerCount = 1 end
    else -- "DAMAGER" or other
        totalDPS = 1
        if isPlayerAlive then dpsCount = 1 end
    end
    
    -- Fix: Ensure numMembers is never negative
    if groupType == "party" then
        numMembers = math.max(0, numMembers - 1) -- exclude player but ensure it's not negative
    end

    -- Display group members if in a group
    if numMembers > 0 then
        totalCount = numMembers + 1  -- Player + group members
        
        -- Count group members
        for i = 1, numMembers do
            local unit = groupType .. i
            local name = UnitName(unit)
            local status
            if not UnitIsConnected(unit) then
                status = "OFFLINE"
            elseif UnitIsDeadOrGhost(unit) then
                status = "DEAD"
            else
                status = "ALIVE"
                aliveCount = aliveCount + 1
            end
            
            local role = UnitGroupRolesAssigned(unit)
            if role == "TANK" then
                totalTanks = totalTanks + 1
                if status == "ALIVE" then tankCount = tankCount + 1 end
            elseif role == "HEALER" then
                totalHealers = totalHealers + 1
                if status == "ALIVE" then healerCount = healerCount + 1 end
            else -- "DAMAGER" or other
                totalDPS = totalDPS + 1
                if status == "ALIVE" then dpsCount = dpsCount + 1 end
            end

            -- Display group member (offset by 1 to account for player entry)
            if not memberTexts[i+1] then
                memberTexts[i+1] = frame:CreateFontString(nil, "OVERLAY", DeathStatusTrackerDB.font or "GameFontNormal")
                memberTexts[i+1]:SetPoint("TOPLEFT", 10, -30 - ((i+1) * 15))
            end

            local roleIcon = roleIcons[role] or roleIcons.NONE
            memberTexts[i+1]:SetFontObject(DeathStatusTrackerDB.font or "GameFontNormal")
            local font, _, flags = memberTexts[i+1]:GetFont()
            memberTexts[i+1]:SetFont(font, DeathStatusTrackerDB.fontSize or 12, flags)
            memberTexts[i+1]:SetText(roleIcon .. " " .. name .. ": " .. status)

            -- For group members, use even brighter colors
            local r, g, b = 1, 1, 1
            if status == "ALIVE" then
                r, g, b = 0, 1, 0.3 -- Brighter green
            elseif status == "DEAD" then
                r, g, b = 1, 0.3, 0.3 -- Brighter red
            elseif status == "OFFLINE" then
                r, g, b = 0.9, 0.9, 0.9 -- Almost white for offline
            end
            memberTexts[i+1]:SetTextColor(r, g, b)
            
            -- Apply shadow to member text
            ApplyTextEnhancement(memberTexts[i+1])
        end
    end
    
    -- Hide unused text lines
    for j = numMembers + 2, #memberTexts do
        memberTexts[j]:SetText("")
    end
    
    -- Update summary texts
    local font, _, flags = summaryTexts.alive:GetFont()
    summaryTexts.alive:SetFont(font, DeathStatusTrackerDB.fontSize or 12, "OUTLINE")
    summaryTexts.alive:SetText("Players Alive: " .. aliveCount .. "/" .. totalCount)

    local font, _, flags = summaryTexts.roles:GetFont()
    summaryTexts.roles:SetFont(font, DeathStatusTrackerDB.fontSize or 12, "OUTLINE")
    summaryTexts.roles:SetText(string.format("%s %d/%d   %s %d/%d   %s %d/%d", 
                                            summaryRoleIcons.TANK, tankCount, totalTanks, 
                                            summaryRoleIcons.HEALER, healerCount, totalHealers, 
                                            summaryRoleIcons.DAMAGER, dpsCount, totalDPS))

    -- Apply shadow to summary texts
    ApplyTextEnhancement(summaryTexts.alive)
    ApplyTextEnhancement(summaryTexts.roles)

    -- Update summary text colors with brighter values
    local overallPercent = aliveCount / totalCount
    if overallPercent == 1 then
        summaryTexts.alive:SetTextColor(0, 1, 0.3) -- Brighter green for 100%
    elseif overallPercent < 0.5 then
        summaryTexts.alive:SetTextColor(1, 0.3, 0.3) -- Brighter red for under 50%
    else
        summaryTexts.alive:SetTextColor(1, 0.7, 0) -- Brighter orange for 50-99%
    end

    -- Make role text brighter
    local tankPercent = totalTanks > 0 and tankCount / totalTanks or 1
    local healerPercent = totalHealers > 0 and healerCount / totalHealers or 1
    local dpsPercent = totalDPS > 0 and dpsCount / totalDPS or 1

    if tankPercent < 0.5 or healerPercent < 0.5 or dpsPercent < 0.5 then
        summaryTexts.roles:SetTextColor(1, 0.3, 0.3) -- Brighter red if any role is under 50%
    else
        summaryTexts.roles:SetTextColor(1, 1, 1) -- Keep pure white for normal status
    end
end

-- Initialize saved variables
local function InitSavedVariables()
    if not DeathStatusTrackerDB then DeathStatusTrackerDB = {} end
    for k, v in pairs(defaults) do
        if DeathStatusTrackerDB[k] == nil then
            DeathStatusTrackerDB[k] = v
        end
    end
    
    -- Apply saved settings
    frame:SetScale(DeathStatusTrackerDB.scale or 1.0)
    
    -- Initialize config panel if it exists
    if _G.DeathStatusTrackerConfigInitialize then
        _G.DeathStatusTrackerConfigInitialize()
    end
end

-- Make functions available globally for the config panel
_G.UpdateStatus = UpdateStatus
_G.UpdateVisibility = UpdateVisibility

-- Event handler
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        InitSavedVariables()
        
        -- Initialize config panel if it exists
        if _G.DeathStatusTrackerConfigInitialize then
            _G.DeathStatusTrackerConfigInitialize()
        end
        
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", DeathStatusTrackerDB.posX, DeathStatusTrackerDB.posY)
        frame:SetScale(DeathStatusTrackerDB.scale or 1.0)
        
        UpdateStatus()
        UpdateVisibility()
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- When group changes, update visibility and status
        UpdateVisibility()
        UpdateStatus()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent = CombatLogGetCurrentEventInfo()
        if subEvent == "UNIT_DIED" then
            UpdateStatus()
        end
    else
        UpdateStatus()
    end
end)

-- Slash Command Handler
SLASH_DEADSTATUSTRACKER1 = "/dst"
SlashCmdList["DEADSTATUSTRACKER"] = function(msg)
    local cmd, arg = strsplit(" ", msg:lower(), 2)
    
    if cmd == "hide" then
        DeathStatusTrackerDB.hidden = true
        DeadStatusTrackerFrame:Hide()
        print("Dead Status Tracker hidden. Use '/dst show' to show it again.")
    elseif cmd == "show" then
        DeathStatusTrackerDB.hidden = false
        UpdateVisibility() -- Show only if should be visible based on settings
        print("Dead Status Tracker shown (will display based on your settings).")
    elseif cmd == "toggle" or cmd == "" then
        DeathStatusTrackerDB.hidden = not DeathStatusTrackerDB.hidden
        if DeathStatusTrackerDB.hidden then
            DeadStatusTrackerFrame:Hide()
            print("Dead Status Tracker hidden.")
        else
            UpdateVisibility()
            print("Dead Status Tracker shown (will display based on your settings).")
        end
    elseif cmd == "solo" then
        DeathStatusTrackerDB.showSolo = not DeathStatusTrackerDB.showSolo
        print("Dead Status Tracker will " .. (DeathStatusTrackerDB.showSolo and "show" or "hide") .. " when solo.")
        UpdateVisibility()
    elseif cmd == "help" then
        print("Dead Status Tracker commands:")
        print("/dst - Toggle visibility")
        print("/dst show - Show tracker")
        print("/dst hide - Hide tracker")
        print("/dst solo - Toggle showing when solo")
        print("/dst help - Show this help")
    else
        print("Usage: /dst [show | hide | toggle | solo | help]")
    end
end
