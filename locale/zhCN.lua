local ADDON_NAME, private = ...
local L = private:NewLocale("zhCN")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - 现在为 [|cFF20ff20%s|r]。"
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - 现在为 [|cFF20ff20%s|r]。"
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - 现在为 [|cFF20ff20%s|r]。"
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - 现在为 [|cFF20ff20%s|r]。"
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - 现在为 [|cFF20ff20%s|r]。"

L.SlashHelpShowRace = "/xanui showrace - 切换显示种族图标。"
L.SlashHelpGenderIcon = "/xanui gendericon - 切换显示性别图标。"
L.SlashHelpGenderText = "/xanui gendertext - 切换显示性别文字。"
L.SlashHelpOnlyDrac = "/xanui onlydrac - 仅为 Dracthyr 切换性别图标/文字。"
L.SlashHelpShowQuests = "/xanui showquests - 切换显示任务图标。"

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (警告) 你在插件卖完灰色物品前离开了商人。"
L.SellGreysSummary = "xanUI: 已出售灰色物品 <%d> 个。[%s]"
L.RepairGuild = "xanUI: 使用公会资金修理。[%s]"
L.RepairGuildInsufficient = "xanUI: 公会资金不足，无法修理。[%s]"
L.RepairAll = "xanUI: 已修理所有物品。[%s]"
L.RepairInsufficient = "xanUI: 资金不足，无法修理。[%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: TalkingHead 对话已静音。|r"

L.MissionMenuTitle = "XanUI 任务菜单"
L.Close = "关闭"
L.RightClickSelectExpansion = "|cFF99CC33右键选择资料片。|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
