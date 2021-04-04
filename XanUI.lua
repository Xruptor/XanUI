--[[
	NOTE: This is my personal UI modifications.  It's not meant for the general public.
	Don't say I didn't warn you!
--]]

local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.moduleFuncs = {}

local enableTradeskills = true

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		if event == "ADDON_LOADED" then
			local arg1 = ...
			if arg1 and arg1 == ADDON_NAME then
				self:UnregisterEvent("ADDON_LOADED")
				self:RegisterEvent("PLAYER_LOGIN")
			end
			return
		end
		if IsLoggedIn() then
			self:EnableAddon(event, ...)
			self:UnregisterEvent("PLAYER_LOGIN")
		end
		return
	end
	if self[event] then
		return self[event](self, event, ...)
	end
end)

function addon.CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end

function addon.SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanUIDB then XanUIDB = {} end
	
	local opt = XanUIDB[frame] or nil

	if not opt then
		XanUIDB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanUIDB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function addon.RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanUIDB then XanUIDB = {} end

	local opt = XanUIDB[frame] or nil

	if not opt then
		XanUIDB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanUIDB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
	
	-- xpcall(self.SetPoint, geterrorhandler(), self, self.anchorPoint, self.relativeTo, self.relativePoint, xOffset, yOffset);
	--https://github.com/WeakAuras/WeakAuras2/commit/f02d15dcf50b158e9ba08af0f34f586fdadf015f
	--https://github.com/WeakAuras/WeakAuras2/pull/1425/commits/37c41ae0c9cf978d3151227e2c665eaf3b1cd00e
	--https://github.com/emptyrivers/WeakAuras2/commit/823e682849d7383f33d12eb61af96c8f1037a2d2
	
end

function addon:EnableAddon()

	if not XanUIDB then XanUIDB = {} end
	if not XanUIDB.hidebossframes then XanUIDB.hidebossframes = false end
	if not XanUIDB.showRace then XanUIDB.showRace = false end
	
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
			elseif c and c:lower() == "showrace" then
				if XanUIDB.showRace then
					XanUIDB.showRace = false
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Race icons are now [|cFF99CC33OFF|r]")
				else
					XanUIDB.showRace = true
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Race icons are now [|cFF99CC33ON|r]")
				end
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("xanUI")
		DEFAULT_CHAT_FRAME:AddMessage("/xanui hidebossframes - Toggles Hiding Blizzard Boss Health Frames On or Off")
		DEFAULT_CHAT_FRAME:AddMessage("/xanui showrace - Toggles Race icons on Nameplates On or Off")

	end

	--move the target or target frame ToT
	--some bosses have these special charge bars to the right of their frame
	--so lets put the TOT below it and to the right slightly
	TargetFrameToT:ClearAllPoints()
	TargetFrameToT:SetPoint("RIGHT", TargetFrame, "RIGHT", 100, -45);
	
	--hide the stupid blizzard boss frames
	if XanUIDB.hidebossframes then
		if not addon.IsRetail then return end
		for i = 1, 4 do
			local frame = _G["Boss"..i.."TargetFrame"]
			frame:UnregisterAllEvents()
			frame:Hide()
			frame.Show = function () end
		end
	end
	
	--ADD TradeSkills to the Blizzard Default TargetFrameSpellBar
	if TargetFrameSpellBar then
		TargetFrameSpellBar.showTradeSkills = enableTradeskills
	end

	if addon.IsRetail then
	
		-- Always show missing transmogs in tooltips
		C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)
		
		--Move the FocusFrameToT Frame to the right of the Focus frame
		FocusFrameToT:ClearAllPoints()
		FocusFrameToT:SetPoint("RIGHT", FocusFrame, "RIGHT", 95, 0)
	
		-- Always show missing transmogs in tooltips
		C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)
		
		--mute ban-lu monk mount
		MuteSoundFile(1593212)
		MuteSoundFile(1593212)
		MuteSoundFile(1593213)	
		MuteSoundFile(1593214)	
		MuteSoundFile(1593215)	
		MuteSoundFile(1593216)
		MuteSoundFile(1593217)	
		MuteSoundFile(1593218)
		MuteSoundFile(1593219)
		MuteSoundFile(1593220)	
		MuteSoundFile(1593221)
		MuteSoundFile(1593222)
		MuteSoundFile(1593223)
		MuteSoundFile(1593224)
		MuteSoundFile(1593225)
		MuteSoundFile(1593226)
		MuteSoundFile(1593227)
		MuteSoundFile(1593228)	
		MuteSoundFile(1593229)
		MuteSoundFile(1593236)
		
		--mute Chordy from shadowlands
		MuteSoundFile(3719073)  --Lets find shinies
		
		--Hostile, Quest, and Interactive NPCs:
		SetCVar("UnitNameFriendlySpecialNPCName", "1")
		SetCVar("UnitNameHostleNPC", "1")
		SetCVar("UnitNameInteractiveNPC", "1")
		SetCVar("ShowQuestUnitCircles", "1")
	end
	
	--make sure to set Status Text to Numeric Values in Interface Options for this to work
	--"PERCENT" and "NUMERIC"
	--GetCVarDefault("statusTextDisplay") -> "NUMERIC"
	--GetCVarDefault("statusText") -> "0"

	--force Numeric for healthbar fix
	SetCVar("statusText","1")
	SetCVar("statusTextDisplay","NUMERIC")
	--InterfaceOptionsStatusTextPanelDisplayDropDown:SetValue("NUMERIC")
	
	--OPTIONS PANEL
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/InterfaceOptionsPanels.lua
	
	--NAMEPLATES
	--http://www.wowinterface.com/forums/showthread.php?t=55998
	SetCVar("nameplateShowAll", 1) -- always show the nameplates (combat/noncombat)
	SetCVar("nameplateShowFriends", 1) -- show for friendly units
	--SetCVar("nameplateShowFriendlyNPCs", 0) --show the nameplates on friendly units as well

	SetCVar("nameplateShowEnemies", 1) -- Enemy
	--SetCVar("nameplateShowEnemyMinions", 0) -- Enemy Minions
	SetCVar("nameplateShowEnemyMinus", 1) -- Enemy Minors
	
	SetCVar("nameplateMaxDistance", 100) --default 60
	
	SetCVar("UnitNameNPC", "0") --this is necessary as part of the (Hostile, Quest, and Interactive NPCs) group
	
	--NamePanelOptions
	--SetCVar("UnitNameOwn", "0");
	--SetCVar("UnitNameNonCombatCreatureName", "0");
	SetCVar("UnitNameFriendlyPlayerName", "1")
	SetCVar("UnitNameFriendlyMinionName", "1")
	SetCVar("UnitNameEnemyPlayerName", "1")
	SetCVar("UnitNameEnemyMinionName", "1")

	--NOW LOAD ALL THE MODULES
	for i=1, #addon.moduleFuncs do
		if addon.moduleFuncs[i].func then
			addon.moduleFuncs[i].func()
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [v|cFF20ff20"..ver.."|r]   /xanui, /xui")
end

----------------------------------------------------------------
---Open all bags when at bank
----------------------------------------------------------------
addon:RegisterEvent("BANKFRAME_OPENED")

function addon:BANKFRAME_OPENED()
	local numSlots, full
	local i

	numSlots, full = GetNumBankSlots()
	for i = 0, numSlots do
		OpenBag(NUM_BAG_SLOTS + 1 + i)
	end
end
