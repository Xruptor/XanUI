local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "racegenderplates"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

local iconKey = ADDON_NAME .. "IconRace"
local iconKeyGender = ADDON_NAME .. "IconGender"
 
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

local function UpdateIcons(f, plate, unitID)
	if not f or not plate then return end
	if not XanUIDB then return end

	local iconRace = f[iconKey]
	local iconGender = f[iconKeyGender]
	local dontHide
	
	--RACE ICON
	dontHide = false
	
	if XanUIDB.showRaceIcon and UnitIsPlayer(unitID) then
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
	
	if XanUIDB.showGenderIcon then
		
		if UnitIsPlayer(unitID) then
		
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
	
	if XanUIDB.showGenderText then
	
		local _, race = UnitRace(unitID)
		local sexID = UnitSex(unitID)
		
		if race and sexID and genders[sexID] then
		
			if not XanUIDB.onlyDracthyr or (XanUIDB.onlyDracthyr and race:lower() == "dracthyr") then
				
				if plate.UnitFrame and plate.UnitFrame.name then
					
					local getName = UnitName(unitID)
					
					if getName then
						if genders[sexID] == "male" then
							getName = getName.." [M]"
							plate.UnitFrame.name:SetText(getName)
							f.genderTextOn = true
							dontHide = true
						elseif genders[sexID] == "female" then
							getName = getName.." [F]"
							plate.UnitFrame.name:SetText(getName)
							f.genderTextOn = true
							dontHide = true
						end
					end

				end
				
			end
		end
		
	end
	if not dontHide and f.genderTextOn and plate.UnitFrame and plate.UnitFrame.name then
		local getName = UnitName(unitID)
		if getName then
			plate.UnitFrame.name:SetText(getName)
			f.genderTextOn = false
		end
	end
	
end
 
function moduleFrame:UpdateAllIcons()
	local npHooks = addon["nameplateHooks"]
	if not npHooks then return end
	
	for plate, f in pairs(npHooks:GetActiveNameplates()) do
		UpdateIcons(f, plate, f._unitID)
	end
end

function moduleFrame:XANUI_ON_NEWPLATE(event, f, plate)
	local iconRace = f[iconKey]
	local iconGender = f[iconKeyGender]
	
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
	local npHooks = addon["nameplateHooks"]
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