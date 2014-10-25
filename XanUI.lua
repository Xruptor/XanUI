--[[
	NOTE: A lot of this addon is from bits and peices of other addons.
	I just wanted to compile them together into one single addon for my own purposes
--]]

----------------------------------------------------------------
---COLOR BARS BY CLASS
----------------------------------------------------------------

local function colour(statusbar, unit)
	if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
		local _, class = UnitClass(unit)
		local c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
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

--stop the stupid text from displaying on hover over
--blizzard changed this with WOD
hooksecurefunc("ShowTextStatusBarText", function(self)
	HideTextStatusBarText(self)
end)


----------------------------------------------------------------
---FACTION INDICATORS (TARGET ONLY)
----------------------------------------------------------------

function xanUI_CreateFactionIcon(frame)
	local f
	
	f = CreateFrame("Frame", "$parentFaction", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(40)
	f:SetHeight(40)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\xanUI\\Unknown")
	t:SetAllPoints(f)
	
	if frame == TargetFrame then
		f:SetPoint("CENTER", 67, 24)
	else
		f:SetPoint("CENTER", -6, 10)
	end
	
	f:Hide()
end

function xanUI_UpdateFactionIcon(unit, frame)
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
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral" and not TargetFrameTextureFramePVPIcon:IsVisible()) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
		
	else
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral"	) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
	end

end

xanUI_CreateFactionIcon(TargetFrame);
	

function xanUI_smallNum(sNum)
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
						local pervalue = tostring(math.floor((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
						textString:SetText(value.." / "..valueMax);
						textString:Show();

						if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
							getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
							getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
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
						local pervalue = tostring(math.floor((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
						textString:SetText(xanUI_smallNum(value).." / "..xanUI_smallNum(valueMax));
						textString:Show();
						
						if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
							getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
							getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
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
						local pervalue = tostring(math.floor((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
						textString:SetText(xanUI_smallNum(value).." / "..xanUI_smallNum(valueMax));
						textString:Show();
					end
				elseif parentName == "PetFrame" then
					if UnitIsDeadOrGhost("pet") then
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.floor((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
						textString:SetText(pervalue);
						textString:Show();
					end
				end	
			end
		end
	end
end)


--[[------------------------
	Blizzard Tradeskills Castbar
	This will modify the target castbar to also show tradeskills
--------------------------]]

local enableTradeskills = true

--initial override
if TargetFrameSpellBar then
	TargetFrameSpellBar.showTradeSkills = enableTradeskills
end

--double check the target castbar hasn't lost the tradeskill setting (another mod may change it)
hooksecurefunc("CastingBarFrame_OnEvent", function(self, event, ...)
	if self and self:GetName() == "TargetFrameSpellBar" then
		if TargetFrameSpellBar.showTradeSkills ~= enableTradeskills then
			TargetFrameSpellBar.showTradeSkills = enableTradeskills
		end
	end
end)


--[[------------------------
	This will fix the issues where the damn pet bar isn't showing up sometimes
--------------------------]]

local function checkPetBar()
	if not InCombatLockdown() and not PetActionBarFrame:IsVisible() and UnitExists("pet") and not UnitIsDeadOrGhost("pet") then
		if not UnitInVehicle("player") or not UnitHasVehicleUI("player") then
			PetActionBarFrame:Show()
		end
	end
end

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local eventFrame = CreateFrame("frame","xanUIEventFrame",UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
eventFrame:RegisterEvent("PLAYER_LOGIN")

--we need to fix a problem where sometimes the pet bar isn't showing up!
-- eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
-- eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
-- eventFrame:RegisterEvent("PET_BAR_UPDATE")
-- eventFrame:RegisterEvent("UNIT_PET")
-- eventFrame:RegisterEvent("UNIT_AURA")
-- eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
-- eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
-- eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
-- eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
-- eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")


function eventFrame:PLAYER_LOGIN()
	if not XanUIDB then XanUIDB = {} end
	if not XanUIDB["hidebossframes"] then XanUIDB["hidebossframes"] = false end

	local ver = GetAddOnMetadata("xanUI","Version") or 0
		
	SLASH_XANUI1 = "/xanui"
	SLASH_XANUI2 = "/xui"
	SlashCmdList["XANUI"] = function(msg)
	
		local a,b,c=strfind(msg, "(%S+)"); --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == "hidebossframes" then
				if XanUIDB.hidebossframes then
					XanUIDB.hidebossframes = false
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Blizzard Boss Health Frames are now [|cFF99CC33ON|r]")
				else
					XanUIDB.hidebossframes = true
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Blizzard Boss Health Frames are now [|cFF99CC33OFF|r]")
					for i = 1, 4 do
						local frame = _G["Boss"..i.."TargetFrame"]
						frame:UnregisterAllEvents()
						frame:Hide()
						frame.Show = function () end
					end
				end
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("xanUI")
		DEFAULT_CHAT_FRAME:AddMessage("/xanui hidebossframes - Toggles Hiding Blizzard Boss Health Frames On or Off")

	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [v|cFFDF2B2B"..ver.."|r]   /xanui, /xui")
	

	--xanUI_UpdateRaidLocks()
	
	--create the castbars
	-- if XSpellBar then
		-- for i = 1,4 do
			-- XSpellBar:New(getglobal("PartyMemberFrame"..i))
		-- end
	-- end 

	--ADD TradeSkills to the Blizzard Default TargetFrameSpellBar
	TargetFrameSpellBar.showTradeSkills = enableTradeskills;

	--move the target or target frame ToT
	TargetFrameToT:ClearAllPoints()
	TargetFrameToT:SetPoint("RIGHT", TargetFrame, "RIGHT", 120, 0);
	
	--Move the FocusFrameToT Frame to the right of the Focus frame
	FocusFrameToT:ClearAllPoints()
	FocusFrameToT:SetPoint("RIGHT", FocusFrame, "RIGHT", 95, 0);

	--hide the stupid blizzard boss frames
	if XanUIDB.hidebossframes then
		for i = 1, 4 do
			local frame = _G["Boss"..i.."TargetFrame"]
			frame:UnregisterAllEvents()
			frame:Hide()
			frame.Show = function () end
		end
	end
	
	eventFrame:UnregisterEvent("PLAYER_LOGIN")
end

local upt_throt  = 0

eventFrame:HookScript("OnUpdate", function(self, elapsed)
	--do some throttling
	upt_throt = upt_throt + elapsed
	if upt_throt < 3 then return end
	upt_throt = 0
			
	--because hunters start off with a fake pet that they really can't dismiss or control, we can ignore the pet show function
	--until they learn tame pet
	if select(2, UnitClass("player")) == "HUNTER" then
		--check for tame pet
		if IsSpellKnown(1515) then
			checkPetBar()
		end
	else
		checkPetBar()
	end
	
end)

function eventFrame:PLAYER_TARGET_CHANGED()
	xanUI_UpdateFactionIcon("target", TargetFrame)
end

------------------------------------------------
------------------------------------------------
------------------------------------------------

-- function eventFrame:PARTY_MEMBERS_CHANGED()
	-- xanUI_UpdateRaidPositions()
	-- checkPetBar()
-- end

-- function eventFrame:PLAYER_ENTERING_WORLD()
	-- xanUI_UpdateRaidPositions()
	-- checkPetBar()
-- end


-- function eventFrame:PET_BAR_UPDATE()
	-- checkPetBar()
-- end

-- function eventFrame:UNIT_PET(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_AURA(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_SPELLCAST_START(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_SPELLCAST_STOP(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_SPELLCAST_SUCCEEDED(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:PLAYER_REGEN_DISABLED()
	-- checkPetBar()
-- end

-- function eventFrame:PLAYER_REGEN_ENABLED()
	-- checkPetBar()
-- end
