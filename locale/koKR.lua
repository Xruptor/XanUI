local ADDON_NAME, private = ...
local L = private:NewLocale("koKR")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - 이제 [|cFF20ff20%s|r]입니다."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - 이제 [|cFF20ff20%s|r]입니다."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - 이제 [|cFF20ff20%s|r]입니다."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - 이제 [|cFF20ff20%s|r]입니다."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - 이제 [|cFF20ff20%s|r]입니다."

L.SlashHelpShowRace = "/xanui showrace - 종족 아이콘 표시를 전환합니다."
L.SlashHelpGenderIcon = "/xanui gendericon - 성별 아이콘 표시를 전환합니다."
L.SlashHelpGenderText = "/xanui gendertext - 성별 텍스트 표시를 전환합니다."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Dracthyr만 성별 아이콘/텍스트를 전환합니다."
L.SlashHelpShowQuests = "/xanui showquests - 퀘스트 아이콘 표시를 전환합니다."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (경고) 상인을 떠나기 전에 회색 아이템 판매가 완료되지 않았습니다."
L.SellGreysSummary = "xanUI: 회색 아이템 <%d>개 판매됨. [%s]"
L.RepairGuild = "xanUI: 길드 자금으로 수리했습니다. [%s]"
L.RepairGuildInsufficient = "xanUI: 길드 자금이 부족하여 수리할 수 없습니다. [%s]"
L.RepairAll = "xanUI: 모든 아이템을 수리했습니다. [%s]"
L.RepairInsufficient = "xanUI: 자금이 부족하여 수리할 수 없습니다. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: TalkingHead 대화가 음소거되었습니다.|r"

L.MissionMenuTitle = "XanUI 임무 메뉴"
L.Close = "닫기"
L.RightClickSelectExpansion = "|cFF99CC33우클릭하여 확장을 선택합니다.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
