-- Animate camera (both position and orientation) between two locataions in a given time


pTime = GetFloatParam("time", 10)


function init()
	startTransform = GetLocationTransform(FindLocation("start"))
	endTransform = GetLocationTransform(FindLocation("end"))
	tim = 0.0
end


function tick(dt)
	tim = tim + dt
	local t = tim / pTime
	if t > 1.0 then t = 1.0 end
	local pos = VecLerp(startTransform.pos, endTransform.pos, t)
	local rot = QuatSlerp(startTransform.rot, endTransform.rot, t)
	SetCameraTransform(Transform(pos, rot))
end

