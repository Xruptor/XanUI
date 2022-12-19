local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "racegenderplates"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

local npHooks = addon["nameplateHooks"]
local iconKey = ADDON_NAME .. "IconRace"
local iconKeyGender = ADDON_NAME .. "IconGender"
local iconKeyGenderLabel = ADDON_NAME .. "GenderLabel"

local genders = {nil, "male", "female"}

local fixedRaceAtlasNames = {
	["highmountaintauren"] = "highmountain",
	["lightforgeddraenei"] = "lightforged",
	["scourge"] = "undead",
	["zandalaritroll"] = "zandalari",
}

function GetRaceAtlas(raceName, gender, useHiRez)
	if (fixedRaceAtlasNames[raceName]) then
		raceName = fixedRaceAtlasNames[raceName]
	end
	local formatingString = useHiRez and "raceicon128-%s-%s" or "raceicon-%s-%s"
	return formatingString:format(raceName, gender)
end

function GetGenderAtlases(genderName)
	local baseAtlas = ("charactercreate-gendericon-%s"):format(genderName)
	local selectedAtlas = ("%s-selected"):format(baseAtlas)
	return baseAtlas, selectedAtlas
end

CUSTOM_FACTION_BAR_COLORS = {
    [1] = {r = 1, g = 0, b = 0},
    [2] = {r = 1, g = 0, b = 0},
    [3] = {r = 1, g = 1, b = 0},
    [4] = {r = 1, g = 1, b = 0},
    [5] = {r = 0, g = 1, b = 0},
    [6] = {r = 0, g = 1, b = 0},
    [7] = {r = 0, g = 1, b = 0},
    [8] = {r = 0, g = 1, b = 0},
}

function GetUnitColor(unit)

    local r, g, b

    if (UnitIsDead(unit) or UnitIsGhost(unit) or UnitIsTapDenied(unit)) then
        r = 0.5
        g = 0.5
        b = 0.5
    elseif (UnitIsPlayer(unit)) then
        if (UnitIsFriend(unit, 'player')) then
            local _, class = UnitClass(unit)
            if ( class ) then
                r = RAID_CLASS_COLORS[class].r
                g = RAID_CLASS_COLORS[class].g
                b = RAID_CLASS_COLORS[class].b
            else
                r = 0.60
                g = 0.60
                b = 0.60
            end
        elseif (not UnitIsFriend(unit, 'player')) then
            r = 1
            g = 0
            b = 0
        end
    elseif (UnitPlayerControlled(unit)) then
        if (UnitCanAttack(unit, 'player')) then
            if (not UnitCanAttack('player', unit)) then
                r = 157/255
                g = 197/255
                b = 255/255
            else
                r = 1
                g = 0
                b = 0
            end
        elseif (UnitCanAttack('player', unit)) then
            r = 1
            g = 1
            b = 0
        elseif (UnitIsPVP(unit)) then
            r = 0
            g = 1
            b = 0
        else
            r = 157/255
            g = 197/255
            b = 255/255
        end
    else
        local reaction = UnitReaction(unit, 'player')

        if (reaction) then
            r = CUSTOM_FACTION_BAR_COLORS[reaction].r
            g = CUSTOM_FACTION_BAR_COLORS[reaction].g
            b = CUSTOM_FACTION_BAR_COLORS[reaction].b
        else
            r = 157/255
            g = 197/255
            b = 255/255
        end
    end

    return r, g, b
end

local function UpdateIcons(f, plate, unitID)
	if not f or not plate then return end
	if not XanUIDB then return end

	local iconRace = f[iconKey]
	local iconGender = f[iconKeyGender]
	local genderLabel = f[iconKeyGenderLabel]
	local dontHide

	--RACE ICON
	dontHide = false

	if iconRace and XanUIDB.showRaceIcon and UnitIsPlayer(unitID) then
		local texture
		local _, race = UnitRace(unitID)
		local sexID = UnitSex(unitID)

		if sexID and race and genders[sexID] then
			texture = GetRaceAtlas(race:lower(), genders[sexID], true)
		end

		if texture then
			-- local iconStyle = UnitIsFriend("player", unitID) and "friend" or "enemy"
			-- if icon.style ~= iconStyle then
				-- icon.style = iconStyle
				-- icon:ClearAllPoints()
				-- if iconStyle == "friend" then
					-- icon:SetPoint('CENTER', 0, 29.46)
					-- icon:SetSize(24, 24)
				-- else
					-- icon:SetPoint('RIGHT', 16, -5)
					-- icon:SetSize(24, 24)
				--end
			--end

			iconRace:ClearAllPoints()
			iconRace:SetPoint('CENTER', -33, 30)
			iconRace:SetSize(24, 24)
			iconRace:SetAtlas(texture)
			iconRace:Show()
			dontHide = true
		end
	end
	if not dontHide and iconRace then
		iconRace:Hide()
	end

	--GENDER ICON
	dontHide = false

	if iconGender and XanUIDB.showGenderIcon then

		if UnitIsPlayer(unitID) and UnitName(unitID) ~= UnitName("player") then

			local texture
			local _, race = UnitRace(unitID)
			local sexID = UnitSex(unitID)

			if sexID and race and genders[sexID] then

				if XanUIDB.showGenderIcon then

					if not XanUIDB.onlyDracthyr or (XanUIDB.onlyDracthyr and race:lower() == "dracthyr") then
						--local genderTex = GetGenderAtlases(genders[sexID])
						--iconGender:SetAtlas(genderTex or nil)
						--iconGender:SetTexCoord(left,right,top,bottom)

						if genders[sexID] == "male" then
							iconGender:SetTexture(131149)
							iconGender:SetTexCoord(0,0.5,0,1) --male
							dontHide = true
						elseif genders[sexID] == "female" then
							iconGender:SetTexture(131149)
							iconGender:SetTexCoord(1,0.5,0,1) --female
							dontHide = true
						end

						if dontHide then
							iconGender:Show()
						end
					end

				end

			end

		end

	end

	if not dontHide and iconGender then
		iconGender:Hide()
	end

	--GENDER TEXT
	dontHide = false

	if genderLabel and XanUIDB.showGenderText and UnitName(unitID) ~= UnitName("player") then

		local _, race = UnitRace(unitID)
		local sexID = UnitSex(unitID)

		if race and sexID and genders[sexID] then

			if not XanUIDB.onlyDracthyr or (XanUIDB.onlyDracthyr and race:lower() == "dracthyr") then

				local getName = UnitName(unitID)
				local r, g, b = GetUnitColor(unitID)

				if not r then
					r, g, b = 0.6, 0.6, 1
				end
				genderLabel:SetTextColor(r, g, b, 1.0)

				if getName then
					if genders[sexID] == "male" then
						genderLabel:SetText("[M]")
						genderLabel:SetPoint("LEFT",-9,5)
						genderLabel:Show()
						dontHide = true
					elseif genders[sexID] == "female" then
						genderLabel:SetText("[F]")
						genderLabel:SetPoint("LEFT",-4,5)
						genderLabel:Show()
						dontHide = true
					end
				end

			end
		end

	end
	if not dontHide and genderLabel then
		genderLabel:Hide()
	end

end

function moduleFrame:UpdateAllIcons()
	if not npHooks then return end

	for plate, f in pairs(npHooks:GetActiveNameplates()) do
		UpdateIcons(f, plate, f._unitID)
	end
end

function moduleFrame:XANUI_ON_NEWPLATE(event, f, plate)
	local iconRace = f[iconKey]
	local iconGender = f[iconKeyGender]
	local genderLabel = f[iconKeyGenderLabel]

	if not iconRace then
		iconRace = f:CreateTexture(nil, "OVERLAY")
		f[iconKey] = iconRace
		iconRace:Hide()
	end
	if not iconGender then
		iconGender = f:CreateTexture(nil, "OVERLAY")
		f[iconKeyGender] = iconGender
		iconGender:ClearAllPoints()
		iconGender:SetPoint('RIGHT', 10, -5)
		iconGender:SetSize(16, 16)
		iconGender:Hide()
	end
	if not genderLabel then
		genderLabel = f:CreateFontString(nil, "ARTWORK", "SystemFont_NamePlate")
		f[iconKeyGenderLabel] = genderLabel
		genderLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
		genderLabel:SetJustifyH("LEFT")
		genderLabel:SetPoint("LEFT",-5,5)
		genderLabel:SetText("[M]")
		genderLabel:Hide()
	end
end

function moduleFrame:XANUI_ON_PLATESHOW(event, f, plate, unitID)
	UpdateIcons(f, plate, unitID)
end

function moduleFrame:XANUI_ON_PLATEHIDE(event, f, plate, unitID)
	if f[iconKey] then
		f[iconKey]:Hide()
	end
	if f[iconKeyGender] then
		f[iconKeyGender]:Hide()
	end
end

function moduleFrame:UNIT_NAME_UPDATE(event, unitID)
	if not npHooks then return end

	local plate, f = npHooks:GetPlateForUnit(unitID)
	UpdateIcons(f, plate, unitID)
end

local function EnableRaceGenderPlates()
	if not addon.IsRetail then return end

	moduleFrame:RegisterEvent("PLAYER_ENTERING_WORLD", moduleFrame.UpdateAllIcons)
	moduleFrame:RegisterMessage('XANUI_ON_NEWPLATE')
	moduleFrame:RegisterMessage('XANUI_ON_PLATESHOW')
	moduleFrame:RegisterMessage('XANUI_ON_PLATEHIDE')

	--check for nameplate name updates
	moduleFrame:RegisterEvent("UNIT_NAME_UPDATE")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableRaceGenderPlates, name=moduleName } )