#include "game.lua"


function init()
	gScoreDisplay = GetInt("savegame.hub.score")
	gScoreDisplayTimer = 1
	gScoreCurrent = getTotalScore()
	gScoreRank = getRank(gScoreDisplay)
	gScoreRankScale = 0
	gScoreRankTimer = 0
	gScoreRankZoom = 0
end


function drawPartOne()
	UiPush()
		UiColor(0,0,0)
		UiRect(UiWidth(), UiHeight())
		UiFont("bold.ttf", 64)
		UiTranslate(UiCenter(), UiMiddle())
		UiColor(1,1,1)
		UiScale(2)
		UiAlign("center middle")
		UiText("PART ONE")
		SetBool("game.disableinput", true)
	UiPop()
end


function getTotalScore()
	local score = 0
	local missions = ListKeys("savegame.mission")
	for i=1,#missions do
		score = score + GetInt("savegame.mission."..missions[i]..".score")
	end
	return score
end


function getRank(score)
	local r = 0
	for i=1,#gRanks do
		if score >= gRanks[i].score then
			r = i
		end
	end
	return r
end


function drawRank()
	if not GetBool("game.player.usescreen") and gScoreCurrent > 0 then
		if gScoreDisplay < gScoreCurrent then
			if gScoreDisplayTimer > 0 then
				gScoreDisplayTimer = gScoreDisplayTimer - GetTimeStep()
				if gScoreDisplayTimer <= 0 then
					gScoreDisplay = gScoreDisplay + 1
					UiSound("score.ogg")
					if gScoreDisplay == gScoreCurrent then
						SetInt("savegame.hub.score", gScoreCurrent)
					end
					gScoreDisplayTimer = 0.2
				end
			end
		end
		UiPush()
			local r = getRank(gScoreDisplay)
			if r ~= gScoreRank then
				gScoreRank = r
				gScoreRankScale	= 0
				SetValue("gScoreRankScale", 1, "bounce", 0.5)
				gScoreRankTimer = 0
				gScoreRankZoom = 1
				UiSound("new-rank.ogg")
			end
			UiFont("bold.ttf", 22)
			local w,h = UiGetTextSize(gRanks[gScoreRank].name)
			w = w + 130
			h = 34
			UiTranslate(20+w/2, 10+h/2)
			UiColor(1,1,1, 0.5)
			UiAlign("center middle")
			UiImageBox("ui/common/box-solid-10.png", w, h, 10, 10)
			UiWindow(w, h)
			UiAlign("left")
			UiColor(0,0,0)
			UiTranslate(30, 24)
			UiText("Score " .. gScoreDisplay)
			UiTranslate(90, 0)
			UiText(gRanks[gScoreRank].name)
		UiPop()
		if gScoreRankScale > 0 then
			UiPush()
				local x = 190 * (1-gScoreRankZoom) + UiCenter() * gScoreRankZoom
				local y = 110 * (1-gScoreRankZoom) + UiMiddle() * gScoreRankZoom
				UiTranslate(x, y)
				UiColor(0,0,0, 0.5+gScoreRankZoom*0.5)
				UiAlign("center middle")
				UiScale(1,gScoreRankScale)
				UiScale(1+0.5*gScoreRankZoom)

				UiImageBox("ui/common/box-solid-10.png", 340, 120, 10, 10)
				UiWindow(340, 120)
				UiFont("bold.ttf", 22)
				UiTranslate(UiCenter(), 30)
				UiAlign("center middle")
				UiPush()
					UiScale(1.5)
					UiColor(1, 1, .4)
					UiText(gRanks[gScoreRank].name)
				UiPop()
				UiTranslate(0, 35)
				UiColor(1,1,1)
				UiText("You reached a new rank")
				UiTranslate(0, 22)
				UiColor(.7, .7, .7)
				if gRanks[gScoreRank].tool then
					UiText("A new tool has been delivered")
				end
				if gRanks[gScoreRank].cash then
					UiText("A cash reward has been delivered")
				end
			UiPop()
			gScoreRankTimer = gScoreRankTimer + GetTimeStep()
			if gScoreRankTimer > 3 and gScoreRankZoom == 1 then
				SetValue("gScoreRankZoom", 0, "cosine", 0.5)
			end
			local hide = false
			--Hide rank notification when picked up (if tool) or on timer (if cash)
			if gScoreRankTimer > 1 and gScoreRankScale == 1 and not GetBool("level.toolspawn") then
				SetValue("gScoreRankScale", 0, "easein", 0.25)
			end
		end
	end
end


function draw()
	if not GetBool("savegame.mission.mall_intro") and GetTime() < 3 then
		drawPartOne()
		SetBool("hud.disable", true)
	else
		drawRank()
	end
end

