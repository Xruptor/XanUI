local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "selljunkautorepair"
local LibAceTimer = LibStub('AceTimer-3.0')

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
--local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
--local IsTBC_C = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

----------------------------------------------------------------
---Sell Junk at Vendors
----------------------------------------------------------------

local doGuildRepairs = false
moduleFrame.GreyLootList = {}
moduleFrame.moneyCount = 0
moduleFrame.itemCount = 0
moduleFrame.sellAttempts = 0
moduleFrame.totalSlots = 0

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

function moduleFrame:StopSellingTimer(endedEarly)
	LibAceTimer:CancelTimer(moduleFrame.sellGreyTimer)
	moduleFrame.sellGreyTimer = nil
	if endedEarly then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: (WARNING) you exited merchant before addon could finish selling greys.")
	end

	if moduleFrame.moneyCount > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: <"..moduleFrame.itemCount.."> Total grey items vendored. ["..GetCoinTextureString(moduleFrame.moneyCount).."]")
	end		
end

local function GetBagSlots(bagType)
	if bagType == "bag" then
		if IsRetail then
			return BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS 
		else
			return BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS
		end

	elseif bagType == "bank" then
		if IsRetail then
			return NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS
		else
			return NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
		end
	end
end

function moduleFrame:MERCHANT_SHOW()

	--reset our variables
	moduleFrame.moneyCount = 0
	moduleFrame.itemCount = 0
	moduleFrame.GreyLootList = {}
	moduleFrame.totalSlots = 0
	moduleFrame.sellIndexCount = 0
	
	local xGetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
	local xGetContainerInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo
	local xGetContainerItemDurability = (C_Container and C_Container.GetContainerItemDurability) or GetContainerItemDurability
	local xGetContainerItemID = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID
	local xUseContainerItem = (C_Container and C_Container.UseContainerItem) or UseContainerItem
	
	local minCnt, maxCnt = GetBagSlots("bag")
	
	-- gather info
	for bag = minCnt, maxCnt do
		for slot = 1, xGetNumSlots(bag) do
			local itemID = xGetContainerItemID(bag, slot)
			
			if itemID and not ignoreList[itemID] then
				
				local stackCount, quality, itemLink, noValue
				
				if IsRetail then
				
					local containerInfo = xGetContainerInfo(bag, slot)
					if containerInfo and containerInfo.quality and containerInfo.quality == 0 and not containerInfo.hasNoValue then
						local _, _, _, _, _, itemType, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
						--make sure it's not a quest item and it has a sell value
						if itemType ~= "Quest" and containerInfo.quality == 0 and itemSellPrice > 0 then
							local stackPrice = (itemSellPrice or 0) * containerInfo.stackCount
							table.insert(moduleFrame.GreyLootList, {bag=bag, slot=slot, itemID=itemID, stackCount=containerInfo.stackCount, stackPrice=stackPrice, itemSellPrice=itemSellPrice} )
						end
					end

				else
					_, stackCount, _, quality, _, _, itemLink, _, noValue = xGetContainerInfo(bag, slot)
					if quality == 0 and not noValue then
						local _, _, _, _, _, itemType, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
						--make sure it's not a quest item and it has a sell value
						if itemType ~= "Quest" and quality == 0 and itemSellPrice > 0 then
							local stackPrice = (itemSellPrice or 0) * stackCount
							table.insert(moduleFrame.GreyLootList, {bag=bag, slot=slot, itemID=itemID, stackCount=stackCount, stackPrice=stackPrice, itemSellPrice=itemSellPrice} )
						end
					end
				end
				
			end
			moduleFrame.totalSlots = moduleFrame.totalSlots + 1
		end
	end
	
	--do the timer for selling, only if we have something to work with
	if #moduleFrame.GreyLootList > 0 and not moduleFrame.sellGreyTimer then
		moduleFrame.sellGreyTimer = LibAceTimer:ScheduleRepeatingTimer(function()
			
			--if they closed early then send a warning
			if not MerchantFrame:IsVisible() then moduleFrame:StopSellingTimer(true) end
			
			--if our attempts are more than wants on the list or more than our total amount of slots then exit
			if moduleFrame.sellIndexCount > #moduleFrame.GreyLootList or moduleFrame.sellIndexCount >= moduleFrame.totalSlots or moduleFrame.sellIndexCount > 2000 then
				moduleFrame:StopSellingTimer()
				return
			end
			
			moduleFrame.sellIndexCount = moduleFrame.sellIndexCount + 1
			
			--grab the next entry in our table
			if moduleFrame.GreyLootList[moduleFrame.sellIndexCount] then
			
				local index = moduleFrame.sellIndexCount
				--print(index, moduleFrame.GreyLootList[index].bag, moduleFrame.GreyLootList[index].slot, moduleFrame.GreyLootList[index].itemID, moduleFrame.GreyLootList[index].stackCount, moduleFrame.GreyLootList[index].stackPrice, moduleFrame.GreyLootList[index].itemSellPrice)
				
				moduleFrame.moneyCount = moduleFrame.moneyCount + moduleFrame.GreyLootList[index].stackPrice
				moduleFrame.itemCount = moduleFrame.itemCount + 1
				
				--print(moduleFrame.itemCount , moduleFrame.moneyCount)
				xUseContainerItem(moduleFrame.GreyLootList[index].bag, moduleFrame.GreyLootList[index].slot)	
			else
				--we don't have another index so exit the timer
				moduleFrame:StopSellingTimer()
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

local function EnableSellJunkAutoRepair()
	moduleFrame:RegisterEvent("MERCHANT_SHOW")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableSellJunkAutoRepair, name=moduleName } )
