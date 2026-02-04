local ADDON_NAME, private = ...
local L = (private and private.L) or setmetatable({}, { __index = function(_, key) return key end })
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "selljunkautorepair"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
addon:EmbedEvents(moduleFrame)

local IsRetail = addon.IsRetail

local UseContainerAPI = C_Container and C_Container.GetContainerItemInfo
local GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local GetContainerItemInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo
local GetContainerItemID = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID
local UseContainerItem = (C_Container and C_Container.UseContainerItem) or UseContainerItem
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetCoinString = function(amount)
	if addon.GetCoinString then
		return addon:GetCoinString(amount)
	end
	local coinFn = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString or GetCoinText
	return coinFn and coinFn(amount or 0) or tostring(amount or 0)
end

----------------------------------------------------------------
---Sell Junk at Vendors
----------------------------------------------------------------

local doGuildRepairs = false
moduleFrame.GreyLootList = {}
moduleFrame.moneyCount = 0
moduleFrame.itemCount = 0
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
	if moduleFrame.sellGreyTimer then
		moduleFrame.sellGreyTimer:Cancel()
		moduleFrame.sellGreyTimer = nil
	end
	if endedEarly then
		DEFAULT_CHAT_FRAME:AddMessage(L.SellGreysInterrupted)
	end

	if moduleFrame.moneyCount > 0 then
		DEFAULT_CHAT_FRAME:AddMessage(string.format(L.SellGreysSummary, moduleFrame.itemCount, GetCoinString(moduleFrame.moneyCount)))
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

	local minCnt, maxCnt = GetBagSlots("bag")

	-- gather info
	for bag = minCnt, maxCnt do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID
			local stackCount
			local quality
			local noValue

			if UseContainerAPI then
				local containerInfo = GetContainerItemInfo(bag, slot)
				if containerInfo then
					itemID = containerInfo.itemID
					stackCount = containerInfo.stackCount or 1
					quality = containerInfo.quality
					noValue = containerInfo.hasNoValue
				end
			else
				local _, count, _, q, _, _, _, _, nv = GetContainerItemInfo(bag, slot)
				itemID = GetContainerItemID and GetContainerItemID(bag, slot) or itemID
				stackCount = count
				quality = q
				noValue = nv
			end

			if itemID and not ignoreList[itemID] and quality == 0 and not noValue then
				local _, _, _, _, _, itemType, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
				--make sure it's not a quest item and it has a sell value
				if itemType ~= "Quest" and itemSellPrice and itemSellPrice > 0 then
					local stackPrice = itemSellPrice * (stackCount or 1)
					table.insert(moduleFrame.GreyLootList, {
						bag = bag,
						slot = slot,
						itemID = itemID,
						stackCount = stackCount or 1,
						stackPrice = stackPrice,
						itemSellPrice = itemSellPrice,
					})
				end
			end
			moduleFrame.totalSlots = moduleFrame.totalSlots + 1
		end
	end

	--do the timer for selling, only if we have something to work with
	if #moduleFrame.GreyLootList > 0 and not moduleFrame.sellGreyTimer then
		moduleFrame.sellGreyTimer = C_Timer.NewTicker(0.15, function()

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
				UseContainerItem(moduleFrame.GreyLootList[index].bag, moduleFrame.GreyLootList[index].slot)
			else
				--we don't have another index so exit the timer
				moduleFrame:StopSellingTimer()
			end

		end)
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
				if amount >= repairCost then
					RepairAllItems(true)
					DEFAULT_CHAT_FRAME:AddMessage(string.format(L.RepairGuild, GetCoinString(repairCost)))
					return
				else
					DEFAULT_CHAT_FRAME:AddMessage(string.format(L.RepairGuildInsufficient, GetCoinString(repairCost)))
				end
			elseif GetMoney() >= repairCost then
				RepairAllItems()
				DEFAULT_CHAT_FRAME:AddMessage(string.format(L.RepairAll, GetCoinString(repairCost)))
				return
			else
				DEFAULT_CHAT_FRAME:AddMessage(string.format(L.RepairInsufficient, GetCoinString(repairCost)))
			end
		end
	end
end

local function EnableSellJunkAutoRepair()
	moduleFrame:RegisterEvent("MERCHANT_SHOW")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableSellJunkAutoRepair, name=moduleName } )
