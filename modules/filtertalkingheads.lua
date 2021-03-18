local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "filtertalkingheads"

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

----------------------------------------------------------------
---Shows talking head dialogue only once per session, don't spam it constantly
----------------------------------------------------------------

local talkingHeadDB = {}
local lastTalkingVO

function eventFrame:TALKINGHEAD_REQUESTED()

	if _G.TalkingHeadFrame or IsAddOnLoaded("Blizzard_TalkingHeadUI") then
		if not eventFrame.talkingUnRegistered then
			_G.TalkingHeadFrame:UnregisterEvent('TALKINGHEAD_REQUESTED')
			eventFrame.talkingUnRegistered = true
		end
	end
	
	local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead = C_TalkingHead.GetCurrentLineInfo()
	
	-- if (talkingHeadDB[vo]) then
		-- C_Timer.After(1, TalkingHeadFrame_CloseImmediately)
	-- else
		-- talkingHeadDB[vo] = true
	-- end
	
	local inInstance, instanceType = IsInInstance()
	
	--only do the talking head filtering in instances, in outside world for quests and stuff don't filter it
	if inInstance and vo then
		if not talkingHeadDB[vo] then
			_G.TalkingHeadFrame_PlayCurrent()
			talkingHeadDB[vo] = true
		else
			--don't spam the notice
			if not lastTalkingVO or lastTalkingVO ~= vo then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF96xanUI: TalkingHead conversation silenced.|r")
				lastTalkingVO = vo
			end
		end
	else
		_G.TalkingHeadFrame_PlayCurrent()
	end
end

local function EnableFilterTalkingHeads()
	if not addon.IsRetail then return end
	
	if not IsAddOnLoaded("Blizzard_TalkingHeadUI") then
		LoadAddOn("Blizzard_TalkingHeadUI")
	end
	eventFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableFilterTalkingHeads } )

