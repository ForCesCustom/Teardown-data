function init()
	box = FindShape("blink")
	target = FindBody("target")
	speed = GetFloatParam("speed",math.random() * 4.0 + 1)
	duration = GetFloatParam("duration",0.5)
	offset = GetFloatParam("offset",0)
	SetShapeEmissiveScale(box, 0)
	wires = GetShapeJoints(box)
	blinkTimer = 0 + offset
	doBlink = true
end


function tick(dt)
	blinkTimer = blinkTimer + (dt * speed)
	local t = math.mod(blinkTimer, 1.0)

	if doBlink then
		--Alarm blink
		if t < duration then
			SetShapeEmissiveScale(box, 1)
		else
			SetShapeEmissiveScale(box, 0)
		end
	end

	--Check if blinker is still connected
	if doBlink then
		for i=1,#wires do
			if IsJointBroken(wires[i]) then
				doBlink = false
				SetShapeEmissiveScale(box, 0)
				blinkTimer = 0
			end
		end
	end

	--Check if target has been completed, i.e., hacked.
	if target ~= 0 and not HasTag(target,"target") then
		doBlink = false
		SetShapeEmissiveScale(box, 0)
	end
end

