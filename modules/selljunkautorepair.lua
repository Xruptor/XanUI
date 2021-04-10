local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "selljunkautorepair"
local LibAceTimer = LibStub('AceTimer-3.0')

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

----------------------------------------------------------------
---Sell Junk at Vendors
----------------------------------------------------------------
eventFrame:RegisterEvent("MERCHANT_SHOW")

local doGuildRepairs = false
eventFrame.GreyLootList = {}
eventFrame.moneyCount = 0
eventFrame.itemCount = 0
eventFrame.sellAttempts = 0
eventFrame.totalSlots = 0

local ignoreList = {
	[140662] = "Deformed Eredar Head", --warlock artifact quest
	[140661] = "Damaged Eredar Head", --warlock artifact quest
	[140663] = "Malformed Eredar Head", --warlock artifact quest
	[140664] = "Deficient Eredar Head", --warlock artifact quest
	[140665] = "Nearly Satisfactory Eredar Head", --warlock artifact quest
	--these two items for some reason break the selling
	------
	[158178] = "Mangled Tortollan Scroll", -- mangled-tortollan-scroll
	--[167873] = "Remnant of the Void", -- remnant-of-the-void
	------
}

function eventFrame:StopSellingTimer(endedEarly)
	LibAceTimer:CancelTimer(eventFrame.sellGreyTimer)
	eventFrame.sellGreyTimer = nil
	if endedEarly then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: (WARNING) you exited merchant before addon could finish selling greys.")
	end

	if eventFrame.moneyCount > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: <"..eventFrame.itemCount.."> Total grey items vendored. ["..GetCoinTextureString(eventFrame.moneyCount).."]")
	end		
end

function eventFrame:MERCHANT_SHOW()
	
	--reset our variables
	eventFrame.moneyCount = 0
	eventFrame.itemCount = 0
	eventFrame.GreyLootList = {}
	eventFrame.totalSlots = 0
	eventFrame.sellIndexCount = 0
	
	-- gather info
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and not ignoreList[itemID] then
				local _, stackCount, _, quality, _, _, itemLink, _, noValue = GetContainerItemInfo(bag, slot)
				if quality == 0 and not noValue then
					local _, _, _, _, _, itemType, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
					--make sure it's not a quest item and it has a sell value
					if itemType ~= "Quest" and quality == 0 and itemSellPrice > 0 then
						local stackPrice = (itemSellPrice or 0) * stackCount
						table.insert(eventFrame.GreyLootList, {bag=bag, slot=slot, itemID=itemID, stackCount=stackCount, stackPrice=stackPrice, itemSellPrice=itemSellPrice} )
					end
				end
			end
			eventFrame.totalSlots = eventFrame.totalSlots + 1
		end
	end
	
	--do the timer for selling, only if we have something to work with
	if #eventFrame.GreyLootList > 0 and not eventFrame.sellGreyTimer then
		eventFrame.sellGreyTimer = LibAceTimer:ScheduleRepeatingTimer(function()
			
			--if they closed early then send a warning
			if not MerchantFrame:IsVisible() then eventFrame:StopSellingTimer(true) end
			
			--if our attempts are more than wants on the list or more than our total amount of slots then exit
			if eventFrame.sellIndexCount > #eventFrame.GreyLootList or eventFrame.sellIndexCount >= eventFrame.totalSlots or eventFrame.sellIndexCount > 2000 then
				eventFrame:StopSellingTimer()
				return
			end
			
			eventFrame.sellIndexCount = eventFrame.sellIndexCount + 1
			
			--grab the next entry in our table
			if eventFrame.GreyLootList[eventFrame.sellIndexCount] then
			
				local index = eventFrame.sellIndexCount
				--print(index, eventFrame.GreyLootList[index].bag, eventFrame.GreyLootList[index].slot, eventFrame.GreyLootList[index].itemID, eventFrame.GreyLootList[index].stackCount, eventFrame.GreyLootList[index].stackPrice, eventFrame.GreyLootList[index].itemSellPrice)
				
				eventFrame.moneyCount = eventFrame.moneyCount + eventFrame.GreyLootList[index].stackPrice
				eventFrame.itemCount = eventFrame.itemCount + 1
				
				--print(eventFrame.itemCount , eventFrame.moneyCount)
				UseContainerItem(eventFrame.GreyLootList[index].bag, eventFrame.GreyLootList[index].slot)	
			else
				--we don't have another index so exit the timer
				eventFrame:StopSellingTimer()
			end
		
		end, 0.15)
	end
	
	--do repairs
	if CanMerchantRepair() then
		local repairCost, canRepair = GetRepairAllCost()
		if canRepair and repairCost > 0 then
			if doGuildRepairs and CanGuildBankRepair() then
				local amount = GetGuildBankWithdrawMoney()
				local guildMoney = GetGuildBankMoney()
				if amount == -1 then
					amount = guildMoney
				else
					amount = min(amount, guildMoney)
				end
				if amount > repairCost then
					RepairAllItems(1)
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Repaired from Guild. ["..GetCoinTextureString(repairCost).."]")
					return
				else
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Insufficient guild funds to make repairs. ["..GetCoinTextureString(repairCost).."]")
				end
			elseif GetMoney() > repairCost then
				RepairAllItems()
				DEFAULT_CHAT_FRAME:AddMessage("xanUI: Repaired all items. ["..GetCoinTextureString(repairCost).."]")
				return
			else
				DEFAULT_CHAT_FRAME:AddMessage("xanUI: Insufficient funds to make repairs. ["..GetCoinTextureString(repairCost).."]")
			end
		end
	end
end
