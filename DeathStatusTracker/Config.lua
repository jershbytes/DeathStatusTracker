local addonName = ...

-- Create configuration panel
local configFrame = CreateFrame("Frame", "DeathStatusTrackerConfigFrame", UIParent)
configFrame.name = "Death Status Tracker"
local category = Settings.RegisterCanvasLayoutCategory(configFrame, "Death Status Tracker")
Settings.RegisterAddOnCategory(category)

-- Title
local title = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Death Status Tracker Options")

-- Scale slider
local scaleSlider = CreateFrame("Slider", "DeathStatusTrackerScaleSlider", configFrame, "OptionsSliderTemplate")
scaleSlider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
scaleSlider:SetWidth(250)
scaleSlider:SetHeight(20)
scaleSlider:SetMinMaxValues(0.5, 2.0)
scaleSlider:SetValueStep(0.1)
DeathStatusTrackerScaleSliderLow:SetText("50%")
DeathStatusTrackerScaleSliderHigh:SetText("200%")
DeathStatusTrackerScaleSliderText:SetText("UI Scale")

-- Font size slider
local fontSlider = CreateFrame("Slider", "DeathStatusTrackerFontSlider", configFrame, "OptionsSliderTemplate")
fontSlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -40)
fontSlider:SetWidth(250)
fontSlider:SetHeight(20)
fontSlider:SetMinMaxValues(8, 24)
fontSlider:SetValueStep(1)
DeathStatusTrackerFontSliderLow:SetText("8")
DeathStatusTrackerFontSliderHigh:SetText("24")
DeathStatusTrackerFontSliderText:SetText("Font Size")

-- Sample text to preview font size
local sampleText = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sampleText:SetPoint("TOPLEFT", fontSlider, "BOTTOMLEFT", 0, -20)
sampleText:SetText("Sample Text: Alive/Dead")

-- Add a checkbox for showing when solo
local soloCheck = CreateFrame("CheckButton", "DeathStatusTrackerSoloCheckbox", configFrame, "UICheckButtonTemplate")
soloCheck:SetPoint("TOPLEFT", fontSlider, "BOTTOMLEFT", 0, -40)

-- Create label text for the checkbox
local soloText = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
soloText:SetText("Show when not in a group")
soloText:SetPoint("LEFT", soloCheck, "RIGHT", 2, 0)

-- Safely check for DeathStatusTrackerDB
if DeathStatusTrackerDB then
    soloCheck:SetChecked(DeathStatusTrackerDB.showSolo)
end

soloCheck:SetScript("OnClick", function(self)
    -- Ensure DeathStatusTrackerDB exists before setting values
    if not DeathStatusTrackerDB then
        DeathStatusTrackerDB = {}
    end
    
    DeathStatusTrackerDB.showSolo = self:GetChecked()
    
    -- Apply the change immediately
    if _G.UpdateVisibility then
        _G.UpdateVisibility()
    end
end)

-- Update function
local function UpdateSliders()
    -- Only update if DeathStatusTrackerDB exists
    if not DeathStatusTrackerDB then return end
    
    scaleSlider:SetValue(DeathStatusTrackerDB.scale or 1.0)
    fontSlider:SetValue(DeathStatusTrackerDB.fontSize or 12)
    soloCheck:SetChecked(DeathStatusTrackerDB.showSolo)
    
    -- Update sample text with current font size
    local font, _, flags = sampleText:GetFont()
    sampleText:SetFont(font, DeathStatusTrackerDB.fontSize or 12, flags)
end

-- Make sure we initialize sliders after DB is loaded
local function InitializeConfig()
    if DeathStatusTrackerDB then
        UpdateSliders()
    end
end

-- Hook into addon loading events
configFrame:SetScript("OnShow", function()
    InitializeConfig()
end)

-- Additional initialization method for LoadAddOn situations
function configFrame:Initialize()
    InitializeConfig()
end

-- This ensures we can initialize from the main addon
_G.DeathStatusTrackerConfigInitialize = function()
    InitializeConfig()
end

-- Scale slider handler
scaleSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value * 10 + 0.5) / 10 -- Round to nearest 0.1
    DeathStatusTrackerDB.scale = value
    DeathStatusTrackerScaleSliderText:SetText(string.format("UI Scale: %d%%", value * 100))
    
    -- Apply the scale immediately
    if DeadStatusTrackerFrame then
        DeadStatusTrackerFrame:SetScale(value)
    end
end)

-- Font size slider handler
fontSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5) -- Round to nearest whole number
    DeathStatusTrackerDB.fontSize = value
    DeathStatusTrackerFontSliderText:SetText(string.format("Font Size: %d", value))
    
    -- Update sample text
    local font, _, flags = sampleText:GetFont()
    sampleText:SetFont(font, value, flags)
    
    -- Apply the font size immediately if the tracker is loaded
    if DeadStatusTrackerFrame and _G.UpdateStatus then
        _G.UpdateStatus() -- Call the function to update the text
    end
end)