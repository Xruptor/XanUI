--Chat Module for XanUI

local StickyTypeChannels = {
  SAY = 1,
  YELL = 0,
  EMOTE = 0,
  PARTY = 1, 
  RAID = 1,
  GUILD = 1,
  OFFICER = 1,
  WHISPER = 1,
  CHANNEL = 1,
};

local function scrollChat(frame, delta)
	--Faster Scroll
	if IsControlKeyDown()  then
		--Faster scrolling by triggering a few scroll up in a loop
		if ( delta > 0 ) then
			for i = 1,5 do frame:ScrollUp(); end;
		elseif ( delta < 0 ) then
			for i = 1,5 do frame:ScrollDown(); end;
		end
	elseif IsAltKeyDown() then
		--Scroll to the top or bottom
		if ( delta > 0 ) then
			frame:ScrollToTop();
		elseif ( delta < 0 ) then
			frame:ScrollToBottom();
		end		
	else
		--Normal Scroll
		if delta > 0 then
			frame:ScrollUp()
		elseif delta < 0 then
			frame:ScrollDown()
		end
	end
end

function XanUI_doChat()
		
	--sticky channels
	for k, v in pairs(StickyTypeChannels) do
	  ChatTypeInfo[k].sticky = v;
	end
		
	--remove alt keypress from the EditBox (no longer need alt to move around)
	ChatFrameEditBox:SetAltArrowKeyMode(nil)
		
	--add more mouse wheel scrolling (alt key = scroll to top, ctrl = faster scrolling)
	local f
	for i=1, NUM_CHAT_WINDOWS do
		f = _G['ChatFrame'..i]
		
		f:EnableMouseWheel(true)
		f:SetScript('OnMouseWheel', scrollChat)

		f:SetMaxLines(250)
	end
		
end





