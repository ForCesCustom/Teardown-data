function init()
	boxes = FindShapes("blink")
	server = FindShape("server")
	boxesSpeed = {}
	blinkTimer = {}
	for i = 1, #boxes do
		boxesSpeed[i] = math.random() * 4.0 + 1
		blinkTimer[i] = 0
		SetShapeEmissiveScale(boxes[i], 0)
	end
	duration = GetFloatParam("duration",0.5)
	doBlink = true
end


function tick(dt)
	if IsShapeBroken(server) then
		doBlink = false
		for i = 1, #boxes do
			SetShapeEmissiveScale(boxes[i], 0)
		end
	end
	if doBlink then
		for i = 1, #boxes do
			blinkTimer[i] = blinkTimer[i] + (dt * boxesSpeed[i])
			local t = math.mod(blinkTimer[i], 1.0)

			if doBlink then
				if t < duration then
					SetShapeEmissiveScale(boxes[i], 1)
				else
					SetShapeEmissiveScale(boxes[i], 0)
				end
			end
		end
	end
end

