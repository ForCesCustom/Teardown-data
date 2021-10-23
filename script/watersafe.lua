function init()
	target = FindBody("target")
	shapes = GetBodyShapes(target)
	timer = 0
	done = false
	submergedSound = LoadSound("submerged.ogg")
	warningSound = LoadLoop("warning-beep.ogg")
	warningTimer = 0
end


function tick(dt)
	local alarm = GetBool("level.alarm")

	--Blink light
	timer = timer + dt
	local t = math.mod(timer, 1.0)
	local e = 0
	local period = 0.8
	if alarm then
		period = 0.5
	end
	if t > period then
		e = 1
	end
	if warningTimer  > 0.0 then
		e = 1
	end
	for i=1, #shapes do
		SetShapeEmissiveScale(shapes[i], e)
	end

	if not done then
		local pos = GetBodyTransform(target).pos
		local inWater, depth = IsPointInWater(pos)
		if inWater then
			SetTag(target, "target", "cleared")
			PlaySound(submergedSound, pos)
			if not alarm then
				SetBool("level.alarm", true)
				SetString("hud.notification", "Alarm triggered by water")
			end
			warningTimer = 0
			done = true
		elseif not alarm then
			QueryRejectBody(target)
			local inDoors, dist = QueryRaycast(pos, Vec(0,1,0), 100)
 			if inDoors then
				warningTimer = 0
			else
				if warningTimer == 0 then
					SetString("hud.notification", "Rain detected")
				end
				warningTimer = warningTimer + dt
				PlayLoop(warningSound, pos)
				if warningTimer > 2 then
					SetString("hud.notification", "Alarm triggered by rain")
					SetBool("level.alarm", true)
					warningTimer = 0
				end
			end
		end
	end
end

