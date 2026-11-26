-- R-UI | WoW Forever 1.60.1
-- Display only. Never changes secure unit frames, attributes, or click actions.
local ADDON = ...
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
local TEXTURE = "Interface\\Buttons\\WHITE8X8"
local bars = {}
local eventFrame = CreateFrame("Frame")
local db
local elapsed = 0
local loaded = false
local defaults = { enabled = true, height = 13 }
local function secret(v)
    return type(issecretvalue) == "function" and issecretvalue(v)
end
local function plain(v)
    return not secret(v) and v ~= nil
end
-- Geometry can be protected independently of combat lockdown.
local function publicNumber(v)
    if not secret(v) and type(v) == "number" then return v end
end
local function publicTrue(v)
    return not secret(v) and v == true
end
local function isPartyToken(unit)
    return plain(unit) and type(unit) == "string"
        and unit:match("^party[1-4]$") ~= nil
end
local function getUnit(frame)
    local unit = frame.unit
    if not isPartyToken(unit) then return nil end
    -- Never assume member frame indices correspond to unit tokens.
    -- Skip vehicle/pet substitutions rather than display the wrong person's mana.
    local displayed = frame.displayedUnit
    if secret(displayed) then return nil end
    if displayed and displayed ~= unit then return nil end
    return unit
end
local function child(frame, key, suffix)
    local value = frame[key]
    if not secret(value) and value then return value end
    local name = frame:GetName()
    return not secret(name) and type(name) == "string" and _G[name .. suffix] or nil
end
local function hideAll()
    for _, bar in pairs(bars) do bar:Hide() end
end
local function createBar(frame)
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:EnableMouse(false)
    bar:SetStatusBarTexture(TEXTURE)
    bar:SetStatusBarColor(0.12, 0.42, 0.79, 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.035, 0.055, 0.095, 1)
    local top = bar:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(1)
    top:SetColorTexture(0.025, 0.035, 0.055, 0.95)
    local shine = bar:CreateTexture(nil, "ARTWORK")
    shine:SetPoint("TOPLEFT", bar:GetStatusBarTexture(), "TOPLEFT", 0, -1)
    shine:SetPoint("TOPRIGHT", bar:GetStatusBarTexture(), "TOPRIGHT", 0, -1)
    shine:SetHeight(1)
    shine:SetColorTexture(0.68, 0.83, 1, 0.22)
    local label = bar:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    label:SetTextColor(0.97, 0.98, 1)
    label:SetShadowColor(0, 0, 0, 0.8)
    label:SetShadowOffset(1, -1)
    label:SetPoint("CENTER", 0, 0)
    bar.label = label
    bar:Hide()
    bars[frame] = bar
    return bar
end
local function layout(frame, bar)
    -- Only our own frame is positioned. The protected health bar is untouched.
    if InCombatLockdown() then return end
    local hp = child(frame, "healthBar", "HealthBar")
    if not hp then return end
    local native = child(frame, "powerBar", "PowerBar")
    -- Inspect only public geometry, never compare or calculate secret dimensions.
    -- Retain a previously confirmed slot; otherwise use our own fixed height.
    local nativeHeight = native and publicNumber(native:GetHeight())
    local nativeShown = native and native:IsShown()
    local useNative = false
    if native and publicTrue(nativeShown) then
        if nativeHeight then
            useNative = nativeHeight >= 8
        elseif bar.anchor == native and bar.mode == "native" then
            nativeHeight = bar.height
            useNative = true
        end
    end
    local hpHeight = publicNumber(hp:GetHeight())
    if hpHeight and hpHeight > 0 then
        bar.lastHP, bar.lastHPHeight = hp, hpHeight
    elseif bar.lastHP == hp then
        hpHeight = bar.lastHPHeight
    end
    local anchor = useNative and native or hp
    local mode = useNative and "native" or "inset"
    local height = useNative and nativeHeight or db.height
    if not useNative and hpHeight and hpHeight > 0 then
        height = math.min(db.height, math.max(8, hpHeight * 0.30))
    end
    local level = publicNumber(frame:GetFrameLevel()) or bar.level
    if bar.anchor == anchor and bar.mode == mode and bar.height == height
        and bar.level == level then return end
    bar:ClearAllPoints()
    -- With native power bars enabled we occupy their existing slot.
    -- Otherwise use the bottom edge of HP so neighboring frames never overlap.
    bar:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
    bar:SetHeight(height)
    if level then bar:SetFrameLevel(level + 12) end
    bar.label:SetFont(STANDARD_TEXT_FONT, math.max(8, math.min(11, height - 3)), "OUTLINE")
    bar.anchor, bar.mode, bar.height, bar.level = anchor, mode, height, level
end
local function manaValues(unit)
    local maximum = UnitPowerMax(unit, MANA)
    if not secret(maximum) then
        if type(maximum) ~= "number" or maximum <= 0 then return nil end
    else
        -- Do not branch on a secret quantity. Only use a public power type.
        local powerType = UnitPowerType(unit)
        if secret(powerType) or powerType ~= MANA then return nil end
    end
    return maximum, UnitPower(unit, MANA)
end
local function percentValue(unit, current, maximum)
    if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
        local ok, pct = pcall(UnitPowerPercent, unit, MANA, false, CurveConstants.ScaleTo100)
        if ok and (secret(pct) or type(pct) == "number") then return pct end
    end
    -- Legacy fallback only when both numbers are explicitly non-secret.
    if not secret(current) and not secret(maximum)
        and type(current) == "number" and type(maximum) == "number" and maximum > 0 then
        return current / maximum * 100
    end
end
local function update(frame, bar)
    local unit = getUnit(frame)
    if not db.enabled or not unit or not publicTrue(frame:IsVisible()) or not bar.anchor then
        bar:Hide()
        return
    end
    local exists = UnitExists(unit)
    local connected = UnitIsConnected(unit)
    if (not secret(exists) and not exists) or (not secret(connected) and not connected) then
        bar:Hide()
        return
    end
    local maximum, current = manaValues(unit)
    if not secret(maximum) and maximum == nil then
        bar:Hide()
        return
    end
    -- The modern native APIs may accept secret values directly; never do Lua
    -- arithmetic, comparisons, string formatting, or inference on those values.
    local ok = pcall(function()
        bar:SetMinMaxValues(0, maximum)
        bar:SetValue(current)
    end)
    if not ok then bar:Hide(); return end
    local pct = percentValue(unit, current, maximum)
    local textOK = false
    if secret(pct) or pct ~= nil then
        textOK = pcall(bar.label.SetFormattedText, bar.label, "%.0f  |  %.0f%%", current, pct)
    end
    if not textOK then
        textOK = pcall(bar.label.SetFormattedText, bar.label, "%.0f  |  --%%", current)
        if not textOK then bar.label:SetText("Mana") end
    end
    bar:Show()
end
local function scan()
    if not loaded or not db.enabled or not IsInGroup() or IsInRaid() then
        hideAll()
        return
    end
    local found = {}
    local function consider(frame)
        if not frame or found[frame] or not frame.IsVisible then return end
        local unit = getUnit(frame)
        if not unit or not child(frame, "healthBar", "HealthBar") then return end
        found[frame] = true
        local bar = bars[frame]
        if not InCombatLockdown() then
            bar = bar or createBar(frame)
            layout(frame, bar)
        end
        if bar then update(frame, bar) end
    end
    -- Scan only the Blizzard compact party-frame family, never raid/nameplates.
    for i = 1, 5 do consider(_G["CompactPartyFrameMember" .. i]) end
    local container = _G.CompactPartyFrame
    if container then
        local members = container.memberUnitFrames
        if type(members) == "table" then
            for _, frame in pairs(members) do consider(frame) end
        end
        -- Modern client frame pools can use child frames without global names.
        local function walk(parent, depth)
            if depth > 3 or not parent.GetChildren then return end
            for _, frame in ipairs({parent:GetChildren()}) do
                consider(frame)
                walk(frame, depth + 1)
            end
        end
        walk(container, 1)
    end
    for frame, bar in pairs(bars) do if not found[frame] then bar:Hide() end end
end
local function refreshExisting()
    if not db or not db.enabled or not IsInGroup() or IsInRaid() then hideAll(); return end
    for frame, bar in pairs(bars) do update(frame, bar) end
end
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_MAXPOWER")
eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
eventFrame:RegisterEvent("UNIT_CONNECTION")
eventFrame:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= ADDON then return end
        RUIDB = type(RUIDB) == "table" and RUIDB or {}
        db = RUIDB
        if type(db.enabled) ~= "boolean" then db.enabled = defaults.enabled end
        db.height = type(db.height) == "number" and math.max(8, math.min(24, db.height)) or defaults.height
        loaded = true
        return
    end
    if not loaded then return end
    if event:match("^UNIT_") then
        if isPartyToken(arg) then refreshExisting() end
    else
        scan()
    end
end)
-- A slow discovery pass handles Edit Mode, delayed layout, and frame recycling.
eventFrame:SetScript("OnUpdate", function(_, dt)
    if not loaded then return end
    elapsed = elapsed + dt
    if elapsed < 0.35 then return end
    elapsed = 0
    if InCombatLockdown() then refreshExisting() else scan() end
end)
local function message(text)
    print("|cff479fffR-UI|r: " .. text)
end
SLASH_RUI1 = "/rui"
SlashCmdList.RUI = function(input)
    if not db then return end
    local cmd, value = input:lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "on" then db.enabled = true; scan(); message("Aktiviert.")
    elseif cmd == "off" then db.enabled = false; hideAll(); message("Deaktiviert.")
    elseif cmd == "height" then
        local number = tonumber(value)
        if not number then message("Beispiel: /rui height 13"); return end
        db.height = math.max(8, math.min(24, math.floor(number + 0.5)))
        scan(); message("Balkenhöhe: " .. db.height .. " (bei eigenem Balken).")
    elseif cmd == "reset" then
        db.enabled, db.height = defaults.enabled, defaults.height
        scan(); message("Standardeinstellungen wiederhergestellt.")
    elseif cmd == "status" then
        local total, visible = 0, 0
        for _, bar in pairs(bars) do total = total + 1; if publicTrue(bar:IsVisible()) then visible = visible + 1 end end
        message((db.enabled and "Aktiv" or "Inaktiv") .. " | Rahmen erkannt: " .. total .. " | Anzeigen sichtbar: " .. visible)
    else
        message("/rui on | off | height 13 | reset | status")
    end
end
