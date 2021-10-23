#include "challenges.lua"

pMusic = GetStringParam("music", "lee-noheist.ogg")
pFlyOver = GetBoolParam("flyover", true)


-- challenge.state			String for current state: "", "done" or "fail"
-- challenge.score			Floating point score for highscore comparison (higher is better)
-- challenge.stars			Integer with number of stars, always between 0 and 5
-- challenge.scoredetails	String presenting score in text, for example "5 targets" 
-- challenge.music			Plays this music if set, otherwise default


function init()
	gChallengeId = GetString("game.levelid")
	if gChallenges[gChallengeId] then
		gChallengeTitle = gChallenges[gChallengeId].title
		gTitleFade = 1
		gTitleTimer = 3
	else
		gChallengeTitle = ""
		gTitleFade = 0
		gTitleTimer = 0
	end
	gSpawnPos = GetPlayerTransform().pos

	SetString("challenge.state", "")
	gEndScreenScale = 0
end


function tick(dt)
	if GetString("challenge.state") ~= "" and gEndScreenScale == 0 then
		SetValue("gEndScreenScale", 1, "linear", 0.25)
	end
	
	if GetString("challenge.state") == "done" then
		PlayMusic("win.ogg")
	elseif GetString("challenge.state") == "fail" then
		PlayMusic("fail.ogg")
	else
		if GetString("challenge.music") ~= "" then
			PlayMusic(GetString("challenge.music"))
		else
			PlayMusic(pMusic)
		end
	end
end


function draw()
	--Title
	if gTitleFade > 0 then
		if gTitleTimer > 0 then
			if VecLength(VecSub(GetPlayerTransform().pos, gSpawnPos)) > 0.5 then
				gTitleTimer = 0
			end
			gTitleTimer = gTitleTimer - GetTimeStep()
			if gTitleTimer <= 0 then
				SetValue("gTitleFade", 0, "easein", 0.3)
			end
		end
		UiPush()
			UiTranslate(0, -(1-gTitleFade)*140)
			UiColor(0,0,0,0.7*gTitleFade)
			UiRect(UiWidth(), 140)
			UiFont("bold.ttf", 64)
			UiTranslate(UiCenter(), 70)
			UiAlign("center middle")
			UiScale(1.5)
			UiColor(1,1,1, gTitleFade)
			UiText(string.upper(gChallengeTitle .. " challenge"))
		UiPop()
	end

	--End screen
	if gEndScreenScale == 1 then
		if pFlyOver then
			flyover()
		end
		UiMakeInteractive()
	end
	if gEndScreenScale > 0 then
		drawEndScreen(gEndScreenScale, GetString("challenge.state"))
	end
end


function fixedWidthText(txt, width)
	if txt == "" then
		return 0
	else
		UiPush()
			UiFont("bold.ttf", 44)
			local w,h = UiGetTextSize(txt)
			local scale = width/w
			UiScale(scale)
			UiText(txt)
		UiPop()
		return h*scale
	end
end


function drawEndScreen(f, state)
	UiPush()
		UiTranslate(-300+300*f, 0)

		--Dialog
		UiAlign("top left")
		UiColor(0, 0, 0, 0.7*f)
		UiRect(400, UiHeight())
		UiWindow(400, UiHeight())
		UiColor(1,1,1)
		UiPush()
			UiTranslate(0, 50)
			if state == "done" then
				UiPush()
					UiTranslate(UiCenter(), 0)
					UiAlign("center top")
					local h
					h = fixedWidthText(string.upper(gChallengeTitle), 300)
					UiTranslate(0, h)
					h = fixedWidthText("CHALLENGE", 300)
					UiTranslate(0, h)
					h = fixedWidthText("RESULTS", 300)
					UiTranslate(0, h)
				UiPop()

				UiPush()
					local score = GetFloat("challenge.score")
					local stars = GetInt("challenge.stars")
					local scoreDetails = GetString("challenge.scoredetails")
					if stars < 0 then stars = 0 end
					if stars > 5 then stars = 5 end

					if gChallengeId ~= "" then
						local bestScore = GetFloat("savegame.challenge."..gChallengeId..".score")
						if score > bestScore then
							SetFloat("savegame.challenge."..gChallengeId..".score", score)
							SetInt("savegame.challenge."..gChallengeId..".stars", stars)
							SetString("savegame.challenge."..gChallengeId..".scoredetails", scoreDetails)
						end
					end

					UiTranslate(UiCenter(), 250)

					UiPush()
						UiTranslate(-50, 0)
						UiAlign("center middle")
						UiColor(1,1,0.5)
						for i=1,stars do
							UiImage("ui/common/star.png")
							UiTranslate(25, 0)
						end
						for i=stars+1, 5 do
							UiImage("ui/common/star-outline.png")
							UiTranslate(25, 0)
						end
					UiPop()
					UiTranslate(0, 40)			

					UiAlign("center")
					UiFont("bold.ttf", 26)
					UiText(scoreDetails)
				UiPop()
				UiTranslate(0, h)
			else
				local h
				UiPush()
					UiTranslate(UiCenter(), 0)
					UiAlign("center top")
					local h
					UiColor(0.8, 0.8, 0.8)
					h = fixedWidthText(string.upper(gChallengeTitle), 300)
					UiTranslate(0, h)
					h = fixedWidthText("CHALLENGE", 300)
					UiTranslate(0, h)
					UiColor(1, 0, 0)
					h = fixedWidthText("FAILED", 300)
					UiTranslate(0, h)
				UiPop()
				UiTranslate(0, 40+h)
			end
		UiPop()
		UiTranslate(0, 850)
		
		--Buttons at bottom
		UiPush()
			UiTranslate(UiCenter(), 0)
			UiFont("regular.ttf", 26)
			UiAlign("center middle")
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 1, 1, 0.8)

			UiPush()
				if not GetBool("game.canquickload") then
					UiDisableInput()
					UiColorFilter(1,1,1,0.5)
				end
				if UiTextButton("Quick load", 260, 40) then
					Command("game.quickload")
				end
			UiPop()

			UiTranslate(0, 47)

			if UiTextButton("Restart", 260, 40) then
				Restart()
			end
			UiTranslate(0, 47)
				
			UiTranslate(0, 20)
			if UiTextButton("Main menu", 220, 40) then
				Menu()
			end
		UiPop()
	UiPop()
end


function flyoverInit()
	if not flyoverFirst then
		flyoverFirst = true
	end

	flyoverBase = Vec(math.random(-40,40), math.random(0,0), math.random(-40,40))
	local dir = VecNormalize(Vec(math.random(-100, 100), 0.0, math.random(-100, 100)))
	flyoverOffsetStart = VecScale(dir, 30)
	flyoverOffsetEnd = VecAdd(flyoverOffsetStart, Vec(math.random(-10, 10), math.random(-10,10), math.random(-10,10)))
	flyoverPos = 0
	flyoverLength = 8

	flyoverTargetPos = Vec(0,0,0)
	flyoverEyePos = Vec(0,0,0)

	flyoverAngle = math.random()*6.28
	flyoverAngVel = (math.random()-0.5)*0.2

	flyoverPos = 0
	flyoverFrame = 0
end


function flyover()
	if not flyoverFirst or flyoverPos == flyoverLength then
		flyoverInit()
	end

	flyoverPos = math.min(flyoverLength, flyoverPos + GetTimeStep())
	local alpha = 1.0
	if flyoverPos < 1.0 then alpha = flyoverPos end
	if flyoverPos > flyoverLength-1.0 then alpha = flyoverLength-flyoverPos end
	if alpha < 1 then
		UiPush()
		UiColor(0,0,0,1-alpha)
		UiRect(UiWidth(), UiHeight())
		UiPop()
	end

	local target, eye, t
	flyoverAngle = flyoverAngle + GetTimeStep()*flyoverAngVel

	t = flyoverPos / flyoverLength
	target = VecCopy(flyoverBase)
	eye = VecAdd(target, VecScale(flyoverOffsetStart, 1-t))
	eye = VecAdd(eye, VecScale(flyoverOffsetEnd, t))
	eye = VecAdd(eye, Vec(math.sin(flyoverAngle)*0, 30, math.cos(flyoverAngle)*0))

	if flyoverFrame < 2 then
		t = 1.0
	else
		t = 0.02
	end
	flyoverFrame = flyoverFrame + 1
	targetPos = VecAdd(VecScale(targetPos, 1-t), VecScale(target, t))
	eyePos = VecAdd(VecScale(eyePos, 1-t), VecScale(eye, t))
	SetCameraTransform(Transform(eyePos, QuatLookAt(eyePos, targetPos)))
end
