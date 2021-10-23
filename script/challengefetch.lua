#include "common.lua"
#include "missions.lua"

pStar1 = GetIntParam("star1", 2)
pStar2 = GetIntParam("star2", 4)
pStar3 = GetIntParam("star3", 6)
pStar4 = GetIntParam("star4", 8)
pStar5 = GetIntParam("star5", 10)

function init()
	done = false
	stars = 0

	collectedTargets = 0

	progressBarFill = 0
	thresholds = {pStar1, pStar2, pStar3, pStar4, pStar5}
	
	scorePosition = 0
	------------------------
	SetBool("level.alarm", false)

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

	requiredCount = 0
	
	SetInt("challenge.primary", primaryCount)
	SetInt("challenge.secondary", secondaryCount)
	SetInt("challenge.required", requiredCount)
	--SetBool("level.complete", true) 
	SetFloat("level.alarmtimer",60)

	clearedPrimary = 0
	clearedSecondary = 0
	
	targetSound = LoadSound("pickup.ogg")
	alarmBackgroundLoop = LoadLoop("alarm-background.ogg")
end


function getStars()
	local s = 0
	if collectedTargets >= pStar1 then
		s = 1
	end
	if collectedTargets >= pStar2 then
		s =  2
	end
	if collectedTargets >= pStar3 then
		s =  3
	end
	if collectedTargets >= pStar4 then
		s =  4
	end
	if collectedTargets >= pStar5 then
		s =  5
	end

	if s > 5 then s = 5 end
	return s
end

function writeScore()
	SetFloat("challenge.score", collectedTargets)
	SetInt("challenge.stars", getStars())
	SetString("challenge.scoredetails", collectedTargets.." targets")
	SetString("challenge.state", "done")
end


function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("../ui/common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("../ui/common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end

-----------------------------------------------------------------------------------------------------------------------------------------------------


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

	SetInt("challenge.clearedprimary", clearedPrimary)
	SetInt("challenge.clearedsecondary", clearedSecondary)
end


function tick(dt)
	if done then
		return
	end

	if GetFloat("game.player.health") == 0 then
		--Player died, set state to fail
		SetString("challenge.state", "fail")
		done = true
	end

	if GetString("challenge.state") == "done" then
		writeScore()
		done = true
	end

	collectedTargets = GetInt("challenge.clearedprimary") +	GetInt("challenge.clearedsecondary")
	stars = getStars()
	--------------------------------------------------------------------------------------------------------------------------------------------------------

	--Tick down alarm timer and lose if it reaches zero
	if GetBool("level.alarm") and GetString("challenge.state") == "" then
		SetString("challenge.music", "heist.ogg")
		
		local t = GetFloat("level.alarmtimer")
		t = t - dt
		if t <= 0.0 then
			t = 0.0
			SetString("challenge.state", "fail")
		end
		SetFloat("level.alarmtimer", t)
		if GetString("challenge.state") ~= "done" then
			PlayLoop(alarmBackgroundLoop)	
		end
	end

	--Compute time left
	local timeLeft = 9999
	if GetBool("level.alarm") then
		timeLeft = GetFloat("level.alarmtimer")
	end
	local timeLimit = GetFloat("challenge.timelimit")
	if timeLimit > 0 then
		local missionTimeLeft = math.max(0, timeLimit - GetFloat("challenge.missiontime"))
		timeLeft = math.min(timeLeft, missionTimeLeft)
	end
	if timeLeft == 9999 then
		SetFloat("challenge.timeleft", -1)
	else
		SetFloat("challenge.timeleft", timeLeft)
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
							
			if GetPlayerInteractBody() == targets[i] and InputPressed("interact") then				
				clearTarget(targets[i])
				Delete(targets[i])
			end
		end
	end
	
	-- Complete when cleared target count is at least the required count AND all primary (if any) are cleared
	local complete = clearedPrimary + clearedSecondary >= requiredCount
	if primaryCount > 0 and clearedPrimary < primaryCount then
		complete = false
	end
	SetBool("challenge.complete", complete)
end


function draw()		
	if not done then
		if GetTime() > 3.3 then			
			SetValue("scorePosition", 1, "linear", 0.5)
			if GetBool("level.alarm") and GetFloat("challenge.timeleft") > 0 then
				drawTimer()
			end
			if GetString("challenge.state") ~= "fail" then
				drawStars()
			end
		end
	end
end

function drawStars()
	UiPush()
		UiTranslate(20,UiHeight()-80 + 80*(1-scorePosition))
					
		local progressBarWidth = 240
		SetValue("progressBarFill", collectedTargets / thresholds[5], "linear", 0.2)
		--progressbar
		progressBar(progressBarWidth, 36, math.min(progressBarFill, 1.0), 1.0)
		--stars
		UiPush()											
			UiColor(1,1,0.5)							
			for i=1,stars do
				UiPush()	
					UiAlign("center middle")
					UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth - (progressBarWidth/10), 18)
					UiColor(0,0,0)
					UiImage("ui/common/star.png")
				UiPop()	
				if i < 5 then
					UiPush()
						--print("drawing one black line")
						UiAlign("center middle")
						UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth, 18)
						UiColor(0,0,0, 0.5)
						UiImage("../ui/hud/meterline.png")
					UiPop()	
				end
			end
			
			for i=1, 4 do		
				UiPush()
					UiAlign("center middle")
					UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth, 18)
					UiColor(1,1,1, 0.25)
					UiImage("../ui/hud/meterline.png")
				UiPop()							
			end
		UiPop()			

		--amount of chests
		UiTranslate(progressBarWidth + 10, 18)
		UiFont("bold.ttf", 36)			
		UiAlign("left middle")
		UiText(collectedTargets)
	UiPop()
end

------------------------------------------------------------------------------------
-- TIMER
------------------------------------------------------------------------------------

function drawTimer()
	local timeLeft = GetFloat("challenge.timeleft")
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