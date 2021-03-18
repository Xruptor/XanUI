local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "showmailboxgold"

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

---------------------------------------------------------
---Shows total gold if any in the mailbox
----------------------------------------------------------------
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")

function eventFrame:MAIL_SHOW()
	if not MailFrame.totalMoneyInBox then
		MailFrame.totalMoneyInBox = MailFrame:CreateFontString(nil, "OVERLAY")
		MailFrame.totalMoneyInBox:SetFontObject('NumberFontNormal')
		MailFrame.totalMoneyInBox:SetPoint("CENTER", MailFrame, "TOP", 0, 12)
	end
end

function eventFrame:MAIL_INBOX_UPDATE()
	if not MailFrame.totalMoneyInBox then return end

	local mountCount = 0

	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			local packageIcon, stationeryIcon, sender, subject, money = GetInboxHeaderInfo(mailIndex)
			if money > 0 then
				mountCount = mountCount + money
			end
		end
	end
	
	if mountCount > 0 then
		MailFrame.totalMoneyInBox:SetText("Total Money: "..GetCoinTextureString(mountCount))
	else
		MailFrame.totalMoneyInBox:Hide()
	end
end

function eventFrame:MAIL_CLOSED()
	if MailFrame.totalMoneyInBox then MailFrame.totalMoneyInBox:Hide() end
end
