--[[
	NOTE: A lot of this addon is from bits and peices of other addons.
	I just wanted to compile them together into one single addon for my own purposes
	All credit where needed should be given to the original authors.

	Special thanks to Efindel for (Trav's Unit Frame Extensions)

	colors the health bars based on class color
	added class icons
	added level indicators for party members
	moved party indicators so not to be cluttered up
	organizes your blizzard raid pullouts evenly on the screen
	added faction indicators to the target frame to let you know whom is horde or alliance (will hide if unit is in PVP)
	lock/unlock the default blizzard raid frames using /xanui
	added health and mana text to frames.
	mousing over a party members healthbar or manabar will show actual health and not percentage
	added race icons for the target frame (for those moments where helmets block the view)
	the raid pullouts will now organize themselves perfectly into columns and rows on the left of your screen
	party frames will now show party buffs under the manabar, and debuffs to the right of the healthbar
	added party casting bars to the right of the party manabar

	added tradeskills to the blizzard targeting casting bar
	added tradeskills to the party casting bars

	Text Display:
	Player Frame: Will show actual health and mana, health shown as a percent, is shown on upper right of frame
	Target Frame: Will show a float version of current health and mana (ie 1345 would be 1.3k).
			Health shown as a percent is displayed at upper left of targetframe.
	Party Frame:	Health and Mana shown as percentages due to limited space for text.
	Focus Frame:	Will show a float version of current health and mana (ie 1345 would be 1.3k).
	Target of Target Frame: Will move the frame to the right of the Target Frame
	Target of Focus Frame: Will move the frame to the right of the Focus Frame
	
--]]

----------------------------------------------------------------
---COLOR BARS BY CLASS
----------------------------------------------------------------

local   UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS =
        UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS
local _, class, c

local function colour(statusbar, unit)
	if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
		_, class = UnitClass(unit)
		c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		statusbar:SetStatusBarColor(c.r, c.g, c.b)
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
	colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local addon = CreateFrame("Frame", "StatusColour")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function()
	colour(sb, "mouseover")
end)

----------------------------------------------------------------
---LEVEL INDICATORS
----------------------------------------------------------------

function XanUI_CreateLevelButtons(frame, settings)

	local f, g
	f = CreateFrame("Frame", "$parentLevel", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(settings[1])
	f:SetHeight(settings[1])

	local t = f:CreateTexture("$parentLevelIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\XanUI\\ClassIcons\\Unknown")
	t:SetAlpha(0.8)
	t:SetAllPoints(f)

	g = f:CreateFontString("$parentText", "ARTWORK", "GameFontNormalSmall")
	g:SetAlpha(0.8)
	g:SetAllPoints(f)

	f:SetPoint("CENTER", settings[2], settings[3])
	f:Show()
end

function XanUI_SetLevels(which)
	local level = UnitLevel("party"..which)
	getglobal("PartyMemberFrame"..which.."LevelText"):SetText(level)
end

function XanUI_LoadPartyLevels()
	local i
	for i = 1,4 do
		XanUI_CreateLevelButtons( getglobal("PartyMemberFrame"..i), { 24, -60, -10 } )
	end
end

XanUI_LoadPartyLevels()

----------------------------------------------------------------
---CLASS ICONS
----------------------------------------------------------------

local frames_POS = {}
frames_POS["player"] = { "PlayerFrame", { 32, -12, 26 } }
frames_POS["target"] = { "TargetFrame", { 32, 12, 26 } }
frames_POS["party"] = { "PartyMemberFrame", { 24, -23, 16 } }
frames_POS["pet"] = { "PetFrame", { 24, -63, 5 } }
--frames_POS["focustarget"] = { "FocusFrameToT", { 24, -6, 10 } }
--frames_POS["targettarget"] = { "TargetFrameToT", { 24, -6, 10 } }
frames_POS["focus"] = { "FocusFrame", { 24, 24, 32 } }
frames_POS["endprotect"] = {}
	
function XanUI_CreateClassButtons(frame, settings)
	local f

	if not frame then return end
	
	if ( frame == PlayerFrame ) then
		f = CreateFrame("Button", "$parentClass", frame)
	else
		f = CreateFrame("Frame", "$parentClass", frame)
	end

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(settings[1])
	f:SetHeight(settings[1])

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\XanUI\\ClassIcons\\Unknown")
	t:SetAllPoints(f)

	f:SetPoint("CENTER", settings[2], settings[3])
	f:Show()
end

function XanUI_SetClassIcon(whichframe, class)
	if ( not class ) then
		class = "Unknown"
	end
	
	if ( not whichframe ) then return end
	getglobal(whichframe:GetName().."ClassIcon"):SetTexture("Interface\\AddOns\\XanUI\\ClassIcons\\"..class)
end

function XanUI_InitializeClassButton(unit, number)
	local i

	if ( number == nil ) then
		XanUI_CreateClassButtons( getglobal(frames_POS[unit][1]), frames_POS[unit][2] )
	else
		for i = 1,number do
			XanUI_CreateClassButtons( getglobal(frames_POS[unit][1]..i), frames_POS[unit][2] )
		end
	end
end

function XanUI_GetClass(unit)
	local class
	if not UnitIsPlayer(unit) then
		class = UnitCreatureType(unit)
	else
		_, class = UnitClass(unit)
	end
	return class
end

function XanUI_UpdateClassIcon(unit, index)
	local class, unitname, unitframe

	if ( index == nil ) then
		unitname = unit
		unitframe = getglobal(frames_POS[unit][1])
	else
		unitname = unit..index
		unitframe = getglobal(frames_POS[unit][1]..index)
	end

	if ( UnitExists(unitname) ) then
		XanUI_SetClassIcon( unitframe, XanUI_GetClass(unitname) )
	end
end

local _, class = UnitClass("player")
XanUI_InitializeClassButton( "player" )
XanUI_SetClassIcon( PlayerFrame, class )

XanUI_InitializeClassButton( "party", 4 )
XanUI_InitializeClassButton( "pet" )
XanUI_InitializeClassButton( "target" )

--XanUI_InitializeClassButton( "targettarget" )
--hooksecurefunc( "TargetofTarget_Update", function(self)
--	XanUI_UpdateClassIcon( "targettarget" )
--end)


XanUI_InitializeClassButton( "focus" )
--XanUI_InitializeClassButton( "focustarget" )

--[[
FocusFrameToT:HookScript("OnUpdate", function(self, elapsed)
	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
	
	if (self.TimeSinceLastUpdate > 2) then
		if self.getLastName == nil then
			self.getLastName = UnitGUID("focustarget")
			XanUI_UpdateClassIcon( "focustarget" )
		elseif self.getLastName ~= UnitGUID("focustarget") then
			self.getLastName = UnitGUID("focustarget")
			XanUI_UpdateClassIcon( "focustarget" )
		end
		self.TimeSinceLastUpdate = 0;
	end
end)
--]]

----------------------------------------------------------------
---FACTION INDICATORS (TARGET ONLY)
----------------------------------------------------------------

function XanUI_CreateFactionIcon(frame)
	local f
	
	f = CreateFrame("Frame", "$parentFaction", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(40)
	f:SetHeight(40)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\XanUI\\ClassIcons\\Unknown")
	t:SetAllPoints(f)
	
	if frame == TargetFrame then
		f:SetPoint("CENTER", 67, 24)
	else
		f:SetPoint("CENTER", -6, 10)
	end
	
	f:Hide()
end

function XanUI_UpdateFactionIcon(unit, frame)
	if not unit then return nil; end
	if not frame then return nil; end
	
	if frame == TargetFrame then
		--we have to move the target raid icon identifier to the right a bit (skull, diamond, star, etc..)
		TargetFrameTextureFrameRaidTargetIcon:SetPoint("CENTER", TargetFrame, "TOPRIGHT", -82, -74);
		--bottom right to the left of level icon
		
		--we have to move the target leader icon as well
		TargetFrameTextureFrameLeaderIcon:ClearAllPoints();
		TargetFrameTextureFrameLeaderIcon:SetPoint("TOPLEFT", -2, -15);

		--don't show the faction icon if the unit is already in PVP.  The PVP icon is a bigger notifier of what
		--faction a unit is... duh!
		if( UnitFactionGroup(unit) and not TargetFrameTextureFramePVPIcon:IsVisible()) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
		
	else
		if( UnitFactionGroup(unit) ) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
	end

end

XanUI_CreateFactionIcon(TargetFrame);
XanUI_CreateFactionIcon(TargetFrameToT);
XanUI_CreateFactionIcon(FocusFrameToT);

hooksecurefunc( "TargetofTarget_Update", function(self)
	XanUI_UpdateFactionIcon( "targettarget", TargetFrameToT)
end)

FocusFrameToT:HookScript("OnUpdate", function(self, elapsed)
	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
	
	if (self.TimeSinceLastUpdate > 2) then
		if self.getLastName == nil then
		
			self.getLastName = UnitGUID("focustarget")
			XanUI_UpdateFactionIcon( "focustarget", FocusFrameToT)
			
		elseif self.getLastName ~= UnitGUID("focustarget") then
		
			self.getLastName = UnitGUID("focustarget")
			XanUI_UpdateFactionIcon( "focustarget", FocusFrameToT)
			
		end
		self.TimeSinceLastUpdate = 0;
	end
end)

----------------------------------------------------------------
---RACE ICONS (TARGET ONLY)
----------------------------------------------------------------

local racesCheck = {
	["Orc"] = "Interface\\AddOns\\XanUI\\RaceIcons\\orc",
	["Tauren"] = "Interface\\AddOns\\XanUI\\RaceIcons\\tauren",
	["Undead"] = "Interface\\AddOns\\XanUI\\RaceIcons\\undead",
	["Scourge"] = "Interface\\AddOns\\XanUI\\RaceIcons\\undead",  --undead can be listed as scourge depending on language
	["Troll"] = "Interface\\AddOns\\XanUI\\RaceIcons\\troll",
	["Blood Elf"] = "Interface\\AddOns\\XanUI\\RaceIcons\\blood_elf",
	["BloodElf"] = "Interface\\AddOns\\XanUI\\RaceIcons\\blood_elf",
	["Human"] = "Interface\\AddOns\\XanUI\\RaceIcons\\human",
	["Gnome"] = "Interface\\AddOns\\XanUI\\RaceIcons\\gnome",
	["Dwarf"] = "Interface\\AddOns\\XanUI\\RaceIcons\\dwarf",
	["Night Elf"] = "Interface\\AddOns\\XanUI\\RaceIcons\\night_elf",
	["NightElf"] = "Interface\\AddOns\\XanUI\\RaceIcons\\night_elf",
	["Draenei"] = "Interface\\AddOns\\XanUI\\RaceIcons\\draenei",
}

function XanUI_CreateRaceIcon()
	local f
	
	f = CreateFrame("Frame", "$parentRace", TargetFrame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(32)
	f:SetHeight(32)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\XanUI\\ClassIcons\\Unknown")
	t:SetAllPoints(f)

	f:SetPoint("CENTER", 39, 37)
	f:Hide()
end

function XanUI_UpdateRaceIcon(unit, frame)
	if not unit then return nil; end
	if not frame then return nil; end
	
	local race, raceEn = UnitRace(unit);

	if raceEn and racesCheck[raceEn] then
		getglobal(frame:GetName().."RaceIcon"):SetTexture(racesCheck[raceEn])
		getglobal(frame:GetName().."Race"):Show()
	else
		getglobal(frame:GetName().."Race"):Hide()
	end	
end

XanUI_CreateRaceIcon();		

----------------------------------------------------------------
--Enable a toggle that allows the default blizzard raid UI panels to lock/unlock
----------------------------------------------------------------

SLASH_XANUI1 = "/xanui"
SlashCmdList["XANUI"] = function(arg)
	if not XanUIDB then return nil; end
	if XanUIDB["RaidLock"] == "yes" then
		XanUIDB["RaidLock"] = "no"
		DEFAULT_CHAT_FRAME:AddMessage("XanUI: Blizzard Raid Pullouts are now unlocked.");
	else
		XanUIDB["RaidLock"] = "yes"
		DEFAULT_CHAT_FRAME:AddMessage("XanUI: Blizzard Raid Pullouts are now locked.");
	end
	XanUI_UpdateRaidLocks()
end

function XanUI_UpdateRaidLocks()
	if not XanUIDB["RaidLock"] then XanUIDB["RaidLock"] = "yes" end
	
	--lock the frames
	if XanUIDB["RaidLock"] == "yes" then
		for i=1, 8 do
			local f=_G["RaidPullout"..i]
			if f then f:SetScript("OnDragStart", function() end) end 
		end
	else
	--unlock the frames
		for i=1, 8 do
			local f=_G["RaidPullout"..i] 
			if f then f:SetScript("OnDragStart", function(self) self:SetMovable(true) self:StartMoving() end) end
		end
	end
end

----------------------------------------------------------------
--RAID POSITION UPDATE
----------------------------------------------------------------

local function framesort(a, b)
	return a.label:GetText() < b.label:GetText()
end

function XanUI_UpdateRaidPositions()
	--number of pullsout per column
	local fpr = 3
	
	if NUM_RAID_PULLOUT_FRAMES and not InCombatLockdown() then
		local frm = {}
		local r = 1
		local n = 1

		for i = 1, NUM_RAID_PULLOUT_FRAMES do
			local f = getglobal("RaidPullout" .. i)
			local b = getglobal("RaidPullout" .. i .. "MenuBackdrop")
			
			--hide the background
			b:Hide()
			
			if f and f:IsShown() and f:IsVisible() and f.label and f.label:GetText() then
				frm[n] = f
				n = n + 1
			end
		end

		table.sort(frm, framesort)

		for i = 1, #frm do
		
			frm[i]:ClearAllPoints()
			frm[i]:Show()
			
			if i == 1 then
				frm[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 25, (-UIParent:GetHeight() / 6.5)-5)
			elseif r == fpr then
				frm[i]:SetPoint("TOPLEFT", frm[i - fpr], "TOPRIGHT", 25, 0)
				r = 1
			else
				frm[i]:SetPoint("TOPLEFT", frm[i - 1], "BOTTOMLEFT", 0, -13)
				r = r + 1
			end
		end
	end
end

----------------------------------------------------------------
--Update party frame icon positions
----------------------------------------------------------------

hooksecurefunc( "PartyMemberFrame_UpdateMember", function(self)
	if GetNumRaidMembers() > 0 then return end
 	--Returns 1 if the specified party member exists, nil otherwise. 
 	local id = self:GetID();
	if ( GetPartyMember(id) ) then
		getglobal(self:GetName().."PVPIcon"):SetPoint("TOPLEFT", 8, 11) --upper right
		getglobal(self:GetName().."MasterIcon"):SetPoint("TOPLEFT", -5, -10) --slightly lower then leader icon (middle left)
		getglobal(self:GetName().."LeaderIcon"):SetPoint("TOPLEFT", -3, 3) --upper left
		getglobal(self:GetName().."RoleIcon"):ClearAllPoints()
		getglobal(self:GetName().."RoleIcon"):SetPoint("BOTTOMLEFT", 11, -2) --upper left
	end
end)

----------------------------------------------------------------
--Add percents and actual health/mana values to specific frames
--MAKE SURE YOU ENABLED THE TEXT STATUS IN THE BLIZZARD -> OPTIONS -> STATUS TEXT
----------------------------------------------------------------

hooksecurefunc( "TextStatusBar_UpdateTextString", function(self)

	if self and self:GetParent() then
		local frame = self:GetParent();
		
		if frame:GetName() then
		
			local parentName = frame:GetName();
			local textString = self.TextString;
			
			if textString then
				local value = self:GetValue();
				local valueMin, valueMax = self:GetMinMaxValues();
				
				--display according to frame name
				if parentName == "PlayerFrame" then
					if UnitIsDeadOrGhost("player") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("0%")
						end
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(value.." / "..valueMax);
						textString:Show();

						if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
							getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
							getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPRIGHT", -20, -12)
							getglobal(parentName.."PercentStr"):SetText(pervalue)
							getglobal(parentName.."PercentStr"):Show()
						elseif string.find(self:GetName(), "HealthBar") then
							getglobal(parentName.."PercentStr"):SetText(pervalue)
						end
						
					end
				elseif parentName == "TargetFrame" then
					if UnitIsDeadOrGhost("target") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("0%")
						end
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(XanUI_smallNum(value).." / "..XanUI_smallNum(valueMax));
						textString:Show();
						
						if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
							getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
							getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPLEFT", 20, -12)
							getglobal(parentName.."PercentStr"):SetText(pervalue)
							getglobal(parentName.."PercentStr"):Show()
						elseif string.find(self:GetName(), "HealthBar") then
							getglobal(parentName.."PercentStr"):SetText(pervalue)
						end
					end
				elseif parentName == "FocusFrame" then
					if UnitIsDeadOrGhost("focus") then
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(XanUI_smallNum(value).." / "..XanUI_smallNum(valueMax));
						textString:Show();
					end
				elseif parentName == "PetFrame" then
					if UnitIsDeadOrGhost("pet") then
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(pervalue);
						textString:Show();
					end
				elseif string.len(parentName) >= 16 and string.sub(parentName, 1, 16) == "PartyMemberFrame" and frame:GetID() then
					
					local partyFrmName = (string.sub(parentName, 1, 16) or "PartyMemberFrame")..(frame:GetID() or 1)
					--self:GetParent():GetAttribute('unit')
					
					if UnitIsDeadOrGhost("party"..frame:GetID()) then
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						--check for mouseover
						if (GetMouseFocus() and GetMouseFocus():GetParent() and GetMouseFocus():GetParent():GetName() and GetMouseFocus():GetParent():GetName() == partyFrmName) then
							textString:SetText(XanUI_smallNum(value).." / "..XanUI_smallNum(valueMax));
						else
							local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
							textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
							textString:SetText(pervalue);
							textString:Show();
						end
					end
				end	
			end
		end
	end
end)

function XanUI_smallNum(sNum)
	if not sNum then return end

	sNum = tonumber(sNum)

	if sNum < 1000 then
		return sNum
	elseif sNum >= 1000 then
		return string.format("%.1fK", sNum/1000)
	else	
		return sNum
	end
end

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "XanUIEventFrame", UIParent)
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
eventFrame:RegisterEvent("UNIT_LEVEL");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
eventFrame:RegisterEvent("UNIT_PET");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and arg1 == "XanUI" then
		if not XanUIDB then XanUIDB = {} end
		DEFAULT_CHAT_FRAME:AddMessage("XanUI: Loaded /xanui");
	
		XanUI_PartyBuffs_OnLoad()
		
		--create the castbars
		if XSpellBar then
			for i = 1,4 do
				XSpellBar:New(getglobal("PartyMemberFrame"..i))
			end
		end
		
		XanUI_UpdateRaidLocks()
		
		--Move the TargetToT Frame to the right of the target frame
		TargetFrameToT:ClearAllPoints()
		TargetFrameToT:SetPoint("RIGHT", TargetFrame, "RIGHT", 80, 0);
		
		--Move the FocusFrameToT Frame to the right of the Focus frame
		FocusFrameToT:ClearAllPoints()
		FocusFrameToT:SetPoint("RIGHT", FocusFrame, "RIGHT", 80, 0);
		
		--do chat stuff
		XanUI_doChat()
		
	elseif ( event == "PARTY_MEMBERS_CHANGED" or event == "UNIT_LEVEL" or event == "PLAYER_ENTERING_WORLD" ) then
		for i = 1,4 do
			XanUI_UpdateClassIcon("party", i)
			XanUI_SetLevels(i)
		end
		XanUI_UpdateRaidPositions()
		
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		 XanUI_UpdateClassIcon("target")
		 XanUI_UpdateFactionIcon("target", TargetFrame)
		 XanUI_UpdateRaceIcon("target", TargetFrame)
		 
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		XanUI_UpdateClassIcon("focus")

	elseif ( event == "UNIT_PET" ) then
		if ( arg1 == "player" ) then
			XanUI_UpdateClassIcon("pet")
		end
	
	elseif ( event == "RAID_ROSTER_UPDATE" or event == "PLAYER_REGEN_ENABLED" ) then
		XanUI_UpdateRaidPositions()
	end
end)

