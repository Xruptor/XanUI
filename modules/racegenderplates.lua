local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "racegenderplates"
 
local iconKey = ADDON_NAME .. "Icon"
local iconKeyGender = ADDON_NAME .. "IconGender"
 
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
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

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden()
end

local function isObjSafe(obj, checkInstance)
	local inInstance, instanceType = IsInInstance()
	if C_PvP.IsArena() then return false end
	if checkInstance and inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
end

local function UpdateNamePlateIcon(namePlate, unit)
	if not isObjSafe(namePlate) then return end
	if not XanUIDB then return end

	local skipCheck = false
	
	if XanUIDB.showRaceIcon then
		
		local icon = namePlate[iconKey]
		
		if UnitIsPlayer(unit) then
			local texture
			
			local _, race = UnitRace(unit)
			local sexID = UnitSex(unit)
			texture = GetRaceAtlas(race:lower(), genders[sexID], true)

			if texture then
				if not icon then
					icon = namePlate:CreateTexture(nil, "OVERLAY")
					namePlate[iconKey] = icon
					icon:Hide()
				end
				
				-- local iconStyle = UnitIsFriend("player", unit) and "friend" or "enemy"
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
				
				icon:ClearAllPoints()
				icon:SetPoint('CENTER', -33, 30)
				icon:SetSize(24, 24)
				icon:SetAtlas(texture)
				icon:Show()
				
				skipCheck = true
			end
		end
		
		if icon and (not skipCheck or not XanUIDB.showRaceIcon) then
			icon:Hide()
		end
		
	end
	
	skipCheck = false
	
	if XanUIDB.showGenderIcon or XanUIDB.showGenderText then
		
		local iconGender = namePlate[iconKeyGender]
		
		if UnitIsPlayer(unit) then
		
			local texture
			
			local _, race = UnitRace(unit)
			local sexID = UnitSex(unit)

			if genders[sexID] then
				
				if XanUIDB.showGenderIcon then
				
					if not iconGender then
						iconGender = namePlate:CreateTexture(nil, "OVERLAY")
						namePlate[iconKeyGender] = iconGender
						iconGender:ClearAllPoints()
						iconGender:SetPoint('RIGHT', 10, -5)
						iconGender:SetSize(16, 16)
						iconGender:Hide()
					end
					
					if not XanUIDB.onlyDracthyr or (XanUIDB.onlyDracthyr and race:lower() == "dracthyr") then
						--local genderTex = GetGenderAtlases(genders[sexID])
						--iconGender:SetAtlas(genderTex or nil)
						--iconGender:SetTexCoord(left,right,top,bottom)
						
						if genders[sexID] == "male" then
							iconGender:SetTexture(131149)
							iconGender:SetTexCoord(0,0.5,0,1) --male
							iconGender:Show()
						elseif genders[sexID] == "female" then
							iconGender:SetTexture(131149)
							iconGender:SetTexCoord(1,0.5,0,1) --female
							iconGender:Show()
						else
							iconGender:SetTexture(nil)
							iconGender:Hide()
						end
						
						skipCheck = true
					end

				end
				
				if XanUIDB.showGenderText then
				
					if not XanUIDB.onlyDracthyr or (XanUIDB.onlyDracthyr and race:lower() == "dracthyr") then
						
						if namePlate.UnitFrame and namePlate.UnitFrame.name then
						
							local getName = namePlate.UnitFrame.name:GetText()
							
							if genders[sexID] == "male" then
								getName = getName.." [M]"
								namePlate.UnitFrame.name:SetText(getName)
							elseif genders[sexID] == "female" then
								getName = getName.." [F]"
								namePlate.UnitFrame.name:SetText(getName)
							end
						end
						
					end
					
				end	
				
			end
		end
		
		if iconGender and (not skipCheck or not XanUIDB.showGenderIcon) then
			iconGender:Hide()
		end
	end
	
end
 
local function UpdateAllNamePlateIcons()
    local nameplates = C_NamePlate.GetNamePlates()
    for index = 1, #nameplates do
        UpdateNamePlateIcon(nameplates[index], nameplates[index].namePlateUnitToken)
    end
end
 
local function EnableRaceGenderPlates()
	if not addon.IsRetail then return end
	
	addon[moduleName.."Frame"] = CreateFrame("Frame")
	local frame = addon[moduleName.."Frame"]
	 
	frame:SetScript("OnEvent", function(self, event, unit)
		if event == "NAME_PLATE_UNIT_ADDED" then
			local namePlate = GetNamePlateForUnit(unit)
			UpdateNamePlateIcon(namePlate, unit)
		elseif event == "NAME_PLATE_UNIT_REMOVED" then
			local namePlate = GetNamePlateForUnit(unit)
			if namePlate[iconKey] then
				namePlate[iconKey]:Hide()
			end
		elseif event == "PLAYER_ENTERING_WORLD" then
			UpdateAllNamePlateIcons()
		end
	end)
	 
	frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableRaceGenderPlates, name=moduleName } )