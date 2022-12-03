local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "filtertalkingheads"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

----------------------------------------------------------------
---Shows talking head dialogue only once per session, don't spam it constantly
----------------------------------------------------------------

local talkingHeadDB = {}
local lastTalkingVO = 0
local lastText = "?"

function moduleFrame:TALKINGHEAD_REQUESTED()
	
	if _G.TalkingHeadFrame and not moduleFrame.talkingUnRegistered then
		_G.TalkingHeadFrame:UnregisterEvent('TALKINGHEAD_REQUESTED')
		moduleFrame.talkingUnRegistered = true
		return
	end
	
	local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead = C_TalkingHead.GetCurrentLineInfo()
	
	--Another way to do the filtering but it's a bit odd as sometimes the audio plays briefly.
	-- if (talkingHeadDB[vo]) then
		-- C_Timer.After(1, TalkingHeadFrame_CloseImmediately)
	-- else
		-- talkingHeadDB[vo] = true
	-- end
	
	local inInstance, instanceType = IsInInstance()

	--only do the talking head filtering in instances, in outside world for quests and stuff don't filter it
	if inInstance and vo then
		if not talkingHeadDB[vo] then
			_G.TalkingHeadFrame:PlayCurrent()
			talkingHeadDB[vo] = true
		else
			--don't spam the notice
			if lastTalkingVO ~= vo or lastText ~= text then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF96xanUI: TalkingHead conversation silenced.|r")
				lastTalkingVO = vo
				lastText = text
			end
		end
	else
		_G.TalkingHeadFrame:PlayCurrent()
	end
	
end

local function EnableFilterTalkingHeads()
	if not addon.IsRetail then return end
	
	moduleFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableFilterTalkingHeads, name=moduleName } )

