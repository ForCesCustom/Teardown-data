#include "common.lua"


function init()
	targets = FindBodies("target", true)
end


function tick(dt)
	for i=1, #targets do
		if IsPointInWater(GetBodyTransform(targets[i]).pos) and GetTagValue(targets[i], "target") == "custom" then
			SetTag(targets[i], "target", "cleared")
		end
	end
end
