-- Control light tagged with "alarm" when alarm is active. There are four types:
-- 1) Slow blink
-- 2) Three short flashes
-- 3) Fast blink
-- 4) Rotating light (no sound)

pType = GetIntParam("type", 1)

function init()
	light = FindLight("alarm")
	pos = GetLightTransform(light).pos
	setLightEnabled(false)
	
	if pType == 1 then snd = LoadSound("alarm1.ogg") end
	if pType == 2 then loop = LoadLoop("alarm2-loop.ogg") end
	if pType == 3 then loop = LoadLoop("alarm3-loop.ogg") end

	frame = math.random(0, 60)
end


function setLightEnabled(enabled)
	SetLightEnabled(light, enabled)
end


function update(dt)
	frame = frame + 1
	if GetBool("level.alarm") then
		if pType == 1 then
			local period = 60
			local t = frame%period
			if t == 0 then PlaySound(snd, pos) end
			if t == 0 then setLightEnabled(true) end
			if t == 30 then setLightEnabled(false)	end
		end
		if pType == 2 then
			PlayLoop(loop, pos)
			local period = 60
			local t = frame%period
			if t == 0 then setLightEnabled(true) end
			if t == 5 then setLightEnabled(false)	end
			if t == 10 then setLightEnabled(true)	end
			if t == 15 then setLightEnabled(false)	end
			if t == 20 then setLightEnabled(true)	end
			if t == 25 then setLightEnabled(false)	end
		end
		if pType == 3 then
			PlayLoop(loop, pos)
			local period = 14
			local t = frame%period
			if t == 0 then setLightEnabled(true) end
			if t == 10 then setLightEnabled(false)	end
		end
		if pType == 4 then
			setLightEnabled(true)
			shape = GetLightShape(light)
			joints = GetShapeJoints(shape)
			SetJointMotor(joints[1], 10)
		end
	end
end

