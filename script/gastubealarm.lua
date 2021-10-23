-- Alarm box will blink periodically when alarm is not triggered and
-- faster when alarm is triggered. Alarm is triggered if ay of:
-- 1) Box is broken
-- 2) Box becomes dynamic (detached from static object)
-- 3) Any joint (or rope) connected to this box is detached
-- If startAlarm is 1 it sets off alarm when destroyed, if not it calls the chopper (which requires chopper in scene of course)

function init()
	startAlarm = GetIntParam("startalarm",1)
	box = FindShape("alarmbox")
	tube = FindShape("tube")
	target = FindBody("target")
	
	doBlink = true
	SetShapeEmissiveScale(box, 0)
	blinkTimer = 0
	unbroken = true
end


function tick(dt)
	blinkTimer = blinkTimer + dt
	local t = math.mod(blinkTimer, 1.0)
	local alarm = GetBool("level.alarm")

	if doBlink then
		if alarm then
			--Alarm blink
			if t < 0.5 then
				SetShapeEmissiveScale(box, 1)
			else
				SetShapeEmissiveScale(box, 0)
			end
		else
			--Regular blink
			if t > 0.9 then
				SetShapeEmissiveScale(box, 0.5)
			else
				SetShapeEmissiveScale(box, 0)
			end
		end
	else
		SetShapeEmissiveScale(box, 0)
	end

	if unbroken then
		if IsShapeBroken(tube) or IsShapeBroken(box) then
			if startAlarm == 1 then
				SetBool("level.alarm", true)
			else
				SetInt("game.player.dispatch", 1)
				local bodyPos = GetBodyTransform(target).pos
				SetFloat("game.player.hackingx", bodyPos[1])
				SetFloat("game.player.hackingy", bodyPos[2])
				SetFloat("game.player.hackingz", bodyPos[3])
				SetInt("game.player.ishacking", 1)
			end
			blinkTimer = 0
			doBlink = false
			unbroken = false
		end
	end
end

