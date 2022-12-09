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

local function EnableFilterTalkingHeads()
	if not addon.IsRetail then return end
	
	hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function(self)

		--https://github.com/tomrus88/BlizzardInterfaceCode/blob/c8c436d8b47a53472bee62c9af06dea1cb50f868/Interface/FrameXML/TalkingHeadUI.lua
		local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead = C_TalkingHead.GetCurrentLineInfo()
		
		local inInstance, instanceType = IsInInstance()

		--only do the filtering in dungeons or instances, in outside world for quests, allow it
		if inInstance and vo and text then
			if not talkingHeadDB[vo] then
				talkingHeadDB[vo] = true
			else
				--don't spam the notice
				if lastTalkingVO ~= vo or lastText ~= text then
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF96xanUI: TalkingHead conversation silenced.|r")
					lastTalkingVO = vo
					lastText = text
				end
				self:CloseImmediately()
			end
		end

	end)

end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableFilterTalkingHeads, name=moduleName } )

