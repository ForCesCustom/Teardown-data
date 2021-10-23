size = GetIntParam("size", 10)
count = GetIntParam("count", 200)
dist = GetFloatParam("dist", 20)

function init()
	trigger = FindTrigger("debriscleanup")
	mi, ma = GetTriggerBounds(trigger)
	aabbMin = {}
	aabbMax = {}
	for i=1, 10 do
		aabbMin[i] = Vec(mi[1] + (ma[1]-mi[1]) * (i-1)/10, mi[2], mi[3])
		aabbMax[i] = Vec(mi[1] + (ma[1]-mi[1]) * (i-0)/10, ma[2], ma[3])
	end
	frame = 0
end


function tick()
	QueryRequire("dynamic large")
	frame = (frame + 1) % 10
	local bodies = QueryAabbBodies(aabbMin[frame+1], aabbMax[frame+1])
	local camPos = GetCameraTransform().pos
	for i=1, #bodies do
		local b = bodies[i]
		local bodyPos = TransformToParentPoint(GetBodyTransform(b), GetBodyCenterOfMass(b))
		if VecLength(VecSub(bodyPos, camPos)) > dist then
			local v = GetBodyVelocity(b)
			if VecLength(v) < 1.0 and IsBodyBroken(b) then
				local shapes = GetBodyShapes(b)
				if #shapes == 1 then
					local shape = shapes[1]
					local sx, sy, sz = GetShapeSize(shape)
					if sx < size and sy < size and sz < size and GetShapeVoxelCount(shape) < count then
						Delete(b)
					end
				end
			end
		end
	end
end

