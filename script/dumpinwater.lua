-- Dump-in-water target
-- Will clear target once center of body is in water

#include "common.lua"
pDepth = GetFloatParam("depth", 0.8)

function init()
	done = false
	target = FindBody("target")
end


function tick(dt)
	if not done then
		local pos = GetBodyTransform(target).pos
		local inWater, depth = IsPointInWater(pos)
		if inWater and depth > pDepth then
			SetTag(target, "target", "cleared")
			done = true
		end
	end
end

