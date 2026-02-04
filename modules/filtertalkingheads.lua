local ADDON_NAME, private = ...
local L = (private and private.L) or setmetatable({}, { __index = function(_, key) return key end })
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "filtertalkingheads"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
addon:EmbedEvents(moduleFrame)

----------------------------------------------------------------
---Shows talking head dialogue only once per session, don't spam it constantly
----------------------------------------------------------------

local talkingHeadDB = {}

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
				DEFAULT_CHAT_FRAME:AddMessage(L.TalkingHeadSilenced)
				self:CloseImmediately()
			end
		end

	end)

end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableFilterTalkingHeads, name=moduleName } )

