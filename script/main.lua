#include "common.lua"
#include "game.lua"

function init()
	local levelId = GetString("game.levelid")
	enableValuabes = not string.find(levelId, "sandbox") and not string.find(levelId, "ch_")
	valuableSound = LoadSound("valuable.ogg")
	initValuables()

	--Just to make sure the base tools are always available except for tutorial hub
	SetBool("savegame.tool.sledge.enabled", true)
	SetBool("savegame.tool.spraycan.enabled", true)
	SetBool("savegame.tool.extinguisher.enabled", true)

	--Check if playing campaign level
	local campaign = gMissions[GetString("game.levelid")] ~= nil
	SetBool("level.campaign", campaign)
	
	--Copy savegame tools properties over to volatile game properties
	local ammoScale = 1
	if campaign then
		local s = GetFloat("options.game.campaign.ammo")
		if s == -1 then
			ammoScale = 0
		else
			ammoScale = ammoScale + s/100
		end
	end
	for id,tool in pairs(gTools) do
		local enabled = GetBool("savegame.tool."..id..".enabled") or enableAll
		if enabled then
			SetBool("game.tool."..id..".enabled", true)
			for j=1, #tool.upgrades do
				local prop = tool.upgrades[j].id
				local value = tool.upgrades[j].default
				local saved = GetInt("savegame.tool."..id.."."..prop)
				if saved > value then
					value = saved 
				end
				if prop == "ammo" and ammoScale ~= 1 then
					value = math.floor(value * ammoScale)
				end
				SetInt("game.tool."..id.."."..prop, value)
			end
		end
	end
end

function handleCommand(cmd)
	if cmd == "quickload" then
		--After quickload, make sure valuables are consistent with savegame
		initValuables()
	end
end

function initValuables()
	if enableValuabes then
		valuables = FindBodies("valuable", true)
		local valueMin = 10000
		local valueMax = 0
		local valueTotal = 0
		for i=1,#valuables do
			local id = GetTagValue(valuables[i], "valuable")
			local v = tonumber(GetTagValue(valuables[i], "value"))
			valueMin = math.min(valueMin, v)
			valueMax = math.max(valueMax, v)
			valueTotal = valueTotal + v
			if GetBool("savegame.valuable."..id) then
				Delete(valuables[i])
			end
		end
		--print(#valuables .. " valuables worth $" .. valueTotal ..  " ($" .. valueMin .. "-$" .. valueMax .. ")")
		valuables = FindBodies("valuable", true)
		for i=1,#valuables do
			SetTag(valuables[i], "interact", "Grab valuable")
		end
		valuableAlpha = {}
	else
		local v = FindBodies("valuable", true)
		for i=1,#v do
			RemoveTag(v[i], "valuable")
			RemoveTag(v[i], "value")
		end
	end
end

function tick(dt)
	--Check if we're in sandbox mode and all tools should be onlocked
	--This cannot be done in init, since we don't know the init order
	if not allToolsCheck then
		if GetBool("level.sandbox") and GetBool("level.unlimitedammo") and GetInt("options.game.sandbox.unlocktools") == 1 then
			for id,tool in pairs(gTools) do
				SetBool("game.tool."..id..".enabled", true)
			end
		end
		allToolsCheck = true
	end

	--Handle valuables
	if enableValuabes then
		local cp = GetPlayerPos()
		for i=1, #valuables do
			local s = valuables[i]
			if s ~= 0 and IsHandleValid(s) then
				--Remove if broken
				if IsBodyBroken(s) then
					RemoveTag(s, "valuable")
					RemoveTag(s, "interact")
					valuables[i] = 0
				end

				--Outline and picking info
				local pos = GetBodyTransform(s).pos
				local d = VecLength(VecSub(pos, cp))
				if IsBodyVisible(s, 6) then
					if valuableAlpha[s] == nil then
						valuableAlpha[s] = 1
					end
				else
					valuableAlpha[s] = nil
				end
				if valuableAlpha[s] then
					valuableAlpha[s] = valuableAlpha[s] - GetTimeStep()*2
					if valuableAlpha[s] > 0 then
						DrawBodyHighlight(s, valuableAlpha[s])
					end
				end

				--Clear if interacted
				if GetPlayerInteractBody() == s and InputPressed("interact") then
					local id = GetTagValue(s, "valuable")
					SetBool("savegame.valuable."..id, true);
					local value = tonumber(GetTagValue(s, "value"))
					if not value then value = 0 end
					SetInt("savegame.cash", GetInt("savegame.cash") + value)
					SetString("hud.notification", "Picked up "..GetDescription(s).." worth $"..value)
					Delete(s)
					PlaySound(valuableSound)
				end
			end
		end
	end
end

