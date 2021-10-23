-- This is the main script for heist game mode:
-- * Identifies the goal and all targets in the level
-- * Starts a timer when the alarm goes off
-- * Tracks mission time and time limit, if present
-- * Removes targets when they are picked up or moved to the goal trigger
-- * Communicates state and progression to HUD script through global variables
-- * Plays appropriate music depending on state

#include "common.lua"
#include "missions.lua"

pTimeLimit = GetFloatParam("timelimit", 0)
pRequired = GetIntParam("required", 0)
pMusic = GetStringParam("music", "")
pFireAlarm = GetBoolParam("firealarm", true)

function init()
	local alarmTime = 60
	if gMissions[GetString("game.levelid")] ~= nil then
		alarmTime = alarmTime + GetFloat("options.game.campaign.time")
	end
	SetFloat("level.missiontime", 0)
	SetFloat("level.alarmtimer", alarmTime)
	SetFloat("level.timelimit", pTimeLimit)
	SetBool("level.alarm", false)
	SetString("level.state", "")

	targets = FindBodies("target", true)
	targetShapeCount = {}
	secondaryCount = 0
	primaryCount = 0	
	for i=1,#targets do
		if HasTag(targets[i], "optional") then
			secondaryCount = secondaryCount + 1
		else
			primaryCount = primaryCount + 1
		end
		if GetTagValue(targets[i], "target") == "" then
			SetTag(targets[i], "interact", "Pick up target")
		end
		local shapes = GetBodyShapes(targets[i])
		targetShapeCount[targets[i]] = #shapes
	end

	SetBool("level.firealarm", pFireAlarm)

	--If the required number of targets is not specified as parameter it defaults to number of primary targets
	if pRequired > 0 then
		requiredCount = pRequired
	else
		requiredCount = primaryCount
		if requiredCount == 0 then
			requiredCount = secondaryCount
		end
	end

	SetInt("level.primary", primaryCount)
	SetInt("level.secondary", secondaryCount)
	SetInt("level.required", requiredCount)

	goal = FindTrigger("goal", true)

	clearedPrimary = 0
	clearedSecondary = 0
	
	targetSound = LoadSound("pickup.ogg")
	alarmBackgroundLoop = LoadLoop("alarm-background.ogg")
end


function isTargetBroken(target)
	local shapes = GetBodyShapes(target)
	if #shapes < targetShapeCount[target] then
		return true
	end
	for i=1,#shapes do
		if IsShapeBroken(shapes[i]) then
			return true
		end
	end
	return false
end


function clearTarget(target)
	PlaySound(targetSound)

	if HasTag(target, "optional") then
		clearedSecondary = clearedSecondary + 1
	else
		clearedPrimary = clearedPrimary + 1
	end

	SetInt("level.clearedprimary", clearedPrimary)
	SetInt("level.clearedsecondary", clearedSecondary)
end


function tick(dt)
	--Play music on win and lose
	local state = GetString("level.state")
	if state ~= "" then
		if state == "win" then
			PlayMusic("win.ogg")

			--Save score once
			if GetString("level.state") == "win" and not savedScore then
				saveScore()
				savedScore = true
			end
		else
			PlayMusic("fail.ogg")
		end
		return
	end

	
	--Set fail state if player dies
	if GetFloat("game.player.health") == 0 then
		SetString("level.state", "fail_dead")
	end

	--Tick down alarm timer and lose if it reaches zero
	if GetBool("level.alarm") then
		local t = GetFloat("level.alarmtimer")
		t = t - dt
		if t <= 0.0 then
			t = 0.0
			SetString("level.state", "fail_alarmtimer")
		end
		SetFloat("level.alarmtimer", t)
		PlayMusic("heist.ogg")
		PlayLoop(alarmBackgroundLoop)
	else
		if pMusic ~= "custom" then
			if pMusic ~= "" then
				PlayMusic(pMusic)
			else
				StopMusic()
			end
		end

		--Set off alarm if a lot of fires
		if pFireAlarm and GetFireCount() >= 100 then
			SetBool("level.alarm", true)
			SetString("hud.notification", "Alarm triggered by fire")
		end
	end

	--Tick mission time
	local missionTime = GetFloat("level.missiontime")
	missionTime = missionTime + dt
	--Lose if passed time limit
	local timeLimit = GetFloat("level.timelimit")
	if timeLimit > 0 and missionTime >= timeLimit then
		missionTime = timeLimit
		SetString("level.state", "fail_missiontimer")
	end
	SetFloat("level.missiontime", missionTime)
	
	--Compute time left
	local timeLeft = 9999
	if GetBool("level.alarm") then
		timeLeft = GetFloat("level.alarmtimer")
	end
	local timeLimit = GetFloat("level.timelimit")
	if timeLimit > 0 then
		local missionTimeLeft = math.max(0, timeLimit - GetFloat("level.missiontime"))
		timeLeft = math.min(timeLeft, missionTimeLeft)
	end
	if timeLeft == 9999 then
		SetFloat("level.timeleft", -1)
	else
		SetFloat("level.timeleft", timeLeft)
	end
	
	local allPrimaryTargetsCleared = true
	for i=1, #targets do
		if IsHandleValid(targets[i]) then
			--Draw target outline
			local dist = VecLength(VecSub(GetPlayerPos(), GetBodyTransform(targets[i]).pos))
			if dist < 8 then
				if GetPlayerInteractBody() == targets[i] then
					DrawBodyOutline(targets[i], 1.0)
				else
					DrawBodyOutline(targets[i], 0.6*(1-dist/8))
				end
			end

			if not HasTag(targets[i], "optional") then
				allPrimaryTargetsCleared = false
			end
				
			local targetType = GetTagValue(targets[i], "target")
			if targetType == "heavy" then
				if IsBodyInTrigger(goal, targets[i]) then
					clearTarget(targets[i])
					Delete(targets[i])
				end
			elseif targetType == "destroy" then
				if isTargetBroken(targets[i]) then
					clearTarget(targets[i])
					RemoveTag(targets[i], "target")
					targets[i] = 0
				end
			elseif targetType == "cleared" then
				clearTarget(targets[i])
				RemoveTag(targets[i], "target")
				targets[i] = 0
			elseif targetType == "custom" then
				--Cleared logic is in some other script for custom targets
			else
				if GetPlayerInteractBody() == targets[i] and InputPressed("interact") then
					if GetString("game.levelid") == "lee_login" and not GetBool("game.canquickload") and not GetBool("level.alarm") then
						SetBool("hud.quicksavehint", true)
						SetPaused(true)
					else
						clearTarget(targets[i])
						Delete(targets[i])
					end
				end
			end
		end
	end
	
	-- Complete when cleared target count is at least the required count AND all primary (if any) are cleared
	local complete = clearedPrimary + clearedSecondary >= requiredCount
	if primaryCount > 0 and clearedPrimary < primaryCount then
		complete = false
	end
	SetBool("level.complete", complete)
end


function draw()
	local state = GetString("level.state")
	local alarm = GetBool("level.alarm")
	
	if state == "" then
		drawTargetInfo()
	end
	
	if state=="" and not alarm and pFireAlarm then
		drawFireMeter()
	end
	
	if state=="" then
		drawTimer()
	end
end


------------------------------------------------------------------------------------
-- SAVE SCORE
------------------------------------------------------------------------------------

function saveScore()
	--Save score to registry if this is a campaign mission
	local missionId = GetString("game.levelid")
	if gMissions[missionId] then
		local primary = GetInt("level.clearedprimary")
		local secondary = GetInt("level.clearedsecondary")
		local timeLeft = GetFloat("level.timeleft")
		local missionTime = GetFloat("level.missiontime")
		local score = primary + secondary
		
		local missionKey = "savegame.mission."..missionId
		local bestScore = GetInt(missionKey..".score")
		local bestTimeLeft = GetFloat(missionKey..".timeleft")
		local bestMissionTime = GetFloat(missionKey..".missiontime")

		--Determine if new score is better
		local saveScore = false
		if score > bestScore then
			saveScore = true
		elseif score == bestScore then
			if timeLeft > 0 then
				if timeLeft > bestTimeLeft then
					saveScore = true
				end
			else
				if missionTime < bestMissionTime then
					saveScore = true
				end
			end
		end
		
		--Save to registry
		if saveScore then
			SetBool("level.highscore", true)
			if GetInt(missionKey..".score") == 0 then
				SetString("savegame.lastcompleted", missionId)
			end
			SetInt(missionKey..".score", score)
			SetFloat(missionKey..".timeleft", timeLeft)
			SetFloat(missionKey..".missiontime", missionTime)
			if timeLeft > 0 then
				Command("game.path.save", missionId.."-best")
			end
		end
	end
end


------------------------------------------------------------------------------------
-- TIMER
------------------------------------------------------------------------------------

function drawTimer()
	local timeLeft = GetFloat("level.timeleft")
	if timeLeft >= 0 then
		UiPush()
			UiFont("bold.ttf", 32)
			UiPush()
				UiTranslate(UiCenter()-50, 65)
				UiAlign("left")
				UiTextOutline(0, 0, 0, 1)
				UiColor(1, 1, 1)
				UiScale(2.0)
				if timeLeft <= 60 then
					UiText(math.ceil(timeLeft*10)/10)
				else
					local t = math.ceil(timeLeft)
					local m = math.floor(t/60)
					local s = math.ceil(t-m*60)
					if s < 10 then
						UiText(m .. ":0" .. s)
					else
						UiText(m .. ":" .. s)
					end
				end
			UiPop()
		UiPop()
	end
end


------------------------------------------------------------------------------------
-- TARGET INFO
------------------------------------------------------------------------------------

tiScale = 0
tiText = ""
tiTextTimer = 0
tiTextScale = 0
tiRequired = 0
tiOptional = 0
function drawTargetInfo()
	local primary = GetInt("level.primary")
	local primaryTaken = GetInt("level.clearedprimary")
	local secondary = GetInt("level.secondary")
	local secondaryTaken = GetInt("level.clearedsecondary")
	local required = GetInt("level.required")

	local requiredPrimary = primary
	local requiredPrimaryTaken = primaryTaken
	local requiredSecondary = required - primary
	local requiredSecondaryTaken = clamp(secondaryTaken, 0, requiredSecondary)
	local required = requiredPrimary + requiredSecondary
	local requiredTaken = requiredPrimaryTaken + requiredSecondaryTaken
	local optional = secondary - requiredSecondary
	local optionalTaken = clamp(secondaryTaken-requiredSecondary, 0, optional)

	if requiredTaken+optionalTaken > tiRequired+tiOptional then
		SetValue("tiTextScale", 1, "easeout", 0.25)
		if requiredTaken == required and requiredTaken > tiRequired then
			tiText = "Mission complete"
		elseif requiredTaken+optionalTaken == required+optional then
			tiText = "All targets cleared"
		else
			tiText = "Target cleared"
		end
		tiTextTimer = 3.0
	end
	tiRequired = requiredTaken
	tiOptional = optionalTaken

	local show = primaryTaken + secondaryTaken > 0
	if show and tiScale==0 then
		SetValue("tiScale", 1, "easeout", 0.5)
	elseif not show and tiScale==1 then
		SetValue("tiScale", 0, "easein", 0.5)
	end

	local mapFade = GetFloat("game.map.fade")
	local visible = math.max(tiScale, mapFade)

	if visible > 0 then
		UiPush()
			local y = 50
			if optional > 0 then
				y = y + 32
			end
			UiTranslate(20, UiHeight()-y*visible)

			if tiTextScale > 0 then
				UiPush()
					UiFont("regular.ttf", 32)
					UiTranslate(10, -18)
					UiScale(1, tiTextScale)
					UiAlign("left middle")
					UiText(tiText)
					if tiTextTimer > 0 then
						tiTextTimer = tiTextTimer - GetTimeStep()
						if tiTextTimer <= 0 then
							SetValue("tiTextScale", 0, "easein", 0.25)
						end
					end
				UiPop()
			end

			for i=1, 2 do
				if i == 1 or optional > 0 then
					UiPush()
						local w = 95 + 20
						if i==1 and required > 0 then
							w = w + required * 24
						end
						if i==2 and optional > 0 then
							w = w + optional * 24
						end

						UiColor(0,0,0, 0.35 + 0.65*mapFade)
						UiImageBox("ui/common/box-solid-10.png", w, 30, 10, 10)

						UiPush()
							UiColor(1,1,1)
							UiFont("bold.ttf", 22)
							UiTranslate(15, 22)
							if i==1 then
								UiColor(1,1,1)
								UiText("Required")
							else
								UiColor(0.8,0.8,0.8)
								UiText("Optional")
							end
						UiPop()

						UiTranslate(120, 15)
						UiAlign("center middle")

						if i==1 then
							UiColor(1,1,0.5)
							for i=1, primary do
								if i <= primaryTaken then
									UiImage("ui/hud/target-taken.png")
								else
									UiImage("ui/hud/target.png")
								end
								UiTranslate(24, 0)
							end
							UiColor(1,1,1)
							for i=1, requiredSecondary do
								if i <= requiredSecondaryTaken then
									UiImage("ui/hud/target-taken.png")
								else
									UiImage("ui/hud/target.png")
								end
								UiTranslate(24, 0)
							end
						else
							UiColor(0.8,0.8,0.8)
							for i=1, optional do
								if i <= optionalTaken then
									UiImage("ui/hud/target-taken.png")
								else
									UiImage("ui/hud/target.png")
								end
								UiTranslate(24, 0)
							end
						end
					UiPop()
					UiTranslate(0, 32)
				end
			end
		UiPop()
	end
end


------------------------------------------------------------------------------------
-- FIRE METER
------------------------------------------------------------------------------------

fmScale = 0
function drawFireMeter()
	local fireCount = math.clamp(GetFireCount(), 0, 100)
	if fireCount == 0 and fmScale == 1 then
		SetValue("fmScale", 0, "easein", 0.5)
	end
	if fireCount > 10 and fmScale == 0 then
		SetValue("fmScale", 1, "easeout", 0.5)
	end
	if fmScale > 0 then
		UiPush()
			UiAlign("center top")
			UiTranslate(UiCenter(), -70 + 70*fmScale)
			UiWindow(200, 50)
			UiFont("bold.ttf", 24)
			UiTextOutline(0,0,0,1, 0.1)
			UiPush()
				UiTranslate(UiCenter(), 20)
				UiText("FIRE ALERT")
			UiPop()
			UiTranslate(0, 48)
			local t = fireCount/100
			progressBar(200, 20, math.min(t, 1.0))
		UiPop()
	end
end

