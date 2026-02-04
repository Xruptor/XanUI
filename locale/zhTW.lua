local ADDON_NAME, private = ...
local L = private:NewLocale("zhTW")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - 現在為 [|cFF20ff20%s|r]。"
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - 現在為 [|cFF20ff20%s|r]。"
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - 現在為 [|cFF20ff20%s|r]。"
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - 現在為 [|cFF20ff20%s|r]。"
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - 現在為 [|cFF20ff20%s|r]。"

L.SlashHelpShowRace = "/xanui showrace - 切換顯示種族圖示。"
L.SlashHelpGenderIcon = "/xanui gendericon - 切換顯示性別圖示。"
L.SlashHelpGenderText = "/xanui gendertext - 切換顯示性別文字。"
L.SlashHelpOnlyDrac = "/xanui onlydrac - 僅為 Dracthyr 切換性別圖示/文字。"
L.SlashHelpShowQuests = "/xanui showquests - 切換顯示任務圖示。"

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (警告) 你在插件賣完灰色物品前離開了商人。"
L.SellGreysSummary = "xanUI: 已販售灰色物品 <%d> 件。[%s]"
L.RepairGuild = "xanUI: 使用公會資金修理。[%s]"
L.RepairGuildInsufficient = "xanUI: 公會資金不足，無法修理。[%s]"
L.RepairAll = "xanUI: 已修理所有物品。[%s]"
L.RepairInsufficient = "xanUI: 資金不足，無法修理。[%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: TalkingHead 對話已靜音。|r"

L.MissionMenuTitle = "XanUI 任務選單"
L.Close = "關閉"
L.RightClickSelectExpansion = "|cFF99CC33右鍵選擇資料片。|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
