tag = GetStringParam("tag","awake")
everywhere = GetBoolParam("global",false)
bodies = FindBodies(tag, everywhere)
shapes = FindShapes(tag, everywhere)
function init()
	for i=1, #bodies do
		local b = bodies[i]
		if IsBodyDynamic(b) then
			ApplyBodyImpulse(b, GetBodyTransform(b).pos, Vec(0,0,0))
		end
	end
	for i=1, #shapes do
		local b = GetShapeBody(shapes[i])
		if IsBodyDynamic(b) then
			ApplyBodyImpulse(b, GetBodyTransform(b).pos, Vec(0,0,0))
		end
	end
end
