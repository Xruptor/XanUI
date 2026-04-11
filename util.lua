--[[
	Shared utilities for xanUI.
	Includes secret-value safeguards and safe table access helpers.
]]

local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end

local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local Util = addon.Util or {}
addon.Util = Util

local type, pcall, tonumber = type, pcall, tonumber

function Util.IsSecretValue(value)
	return type(issecretvalue) == "function" and issecretvalue(value)
end

function Util.IsSecretTable(value)
	return type(issecrettable) == "function" and issecrettable(value)
end

function Util.CanAccessValue(value)
	if Util.IsSecretValue(value) or Util.IsSecretTable(value) then
		if type(canaccessvalue) == "function" then
			local ok, canAccess = pcall(canaccessvalue, value)
			return ok and canAccess
		end
		return false
	end
	return true
end

function Util.TryUnwrapSecretValue(value)
	if not Util.IsSecretValue(value) then
		return value
	end

	if type(secretunwrap) == "function" then
		local ok, unwrapped = pcall(secretunwrap, value)
		if ok then
			return unwrapped
		end
	end

	return value
end

function Util.SafeToNumber(value)
	value = Util.TryUnwrapSecretValue(value)
	if not Util.CanAccessValue(value) then
		return nil
	end

	if type(value) == "number" then
		return value
	end

	local ok, num = pcall(tonumber, value)
	if ok and Util.CanAccessValue(num) and type(num) == "number" then
		return num
	end

	return nil
end

function Util.SafeCallToNumber(fn, ...)
	local ok, value = pcall(fn, ...)
	if not ok then
		return nil
	end
	return Util.SafeToNumber(value)
end

function Util.IsValueBlockedBySecrets(value)
	if not Util.IsSecretValue(value) and not Util.IsSecretTable(value) then
		return false
	end
	if type(canaccessvalue) == "function" then
		local ok, canAccess = pcall(canaccessvalue, value)
		return (not ok) or (not canAccess)
	end
	return true
end

function Util.SafeIndex(t, key)
	if not t then return nil end
	if Util.IsSecretTable(t) then
		if not Util.CanAccessValue(t) then return nil end
	end
	if Util.IsSecretValue(key) or Util.IsSecretTable(key) then
		if not Util.CanAccessValue(key) then return nil end
	end
	local ok, value = pcall(function() return t[key] end)
	if ok then
		return value
	end
	return nil
end

function Util.SafeSet(t, key, value)
	if not t then return false end
	if Util.IsSecretTable(t) then
		if not Util.CanAccessValue(t) then return false end
	end
	if Util.IsSecretValue(key) or Util.IsSecretTable(key) then
		if not Util.CanAccessValue(key) then return false end
	end
	local ok = pcall(function() t[key] = value end)
	return ok
end

function Util.SafeUnitCall(fn, unit, ...)
	if type(fn) ~= "function" then return nil end
	if not Util.CanAccessValue(unit) then return nil end
	local ok, value = pcall(fn, unit, ...)
	if ok then
		return value
	end
	return nil
end
