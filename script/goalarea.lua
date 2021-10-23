pRadius = GetFloatParam("radius", 5)

function init()
	sprite = LoadSprite("gfx/ring.png")
	pos = GetLocationTransform(FindLocation("pos")).pos
	targets = FindBodies("target", true)
end

function tick(dt)
	local hasHeavy = false
	for i=1, #targets do
		if GetTagValue(targets[i], "target") == "heavy" then
			hasHeavy = true
			break
		end
	end
	if hasHeavy and GetString("level.state")=="" then
		local t = Transform(pos, QuatEuler(90, 0, 0))
		DrawSprite(sprite, t, pRadius*2, pRadius*2, 1, 1, 1, 1, true, false)
	end
end

