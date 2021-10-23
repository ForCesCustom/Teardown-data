chopper = {}

function chopperInit()
	chopper.body = FindBody("chopper")
	chopper.transform = GetBodyTransform(chopper.body)
	
	chopper.mainRotor = FindBody("mainrotor")
	chopper.mainRotorLocalTransform = TransformToLocalTransform(chopper.transform, GetBodyTransform(chopper.mainRotor))

	chopper.tailRotor = FindBody("tailrotor")
	chopper.tailRotorLocalTransform = TransformToLocalTransform(chopper.transform, GetBodyTransform(chopper.tailRotor))

	chopper.searchLight = FindBody("light")
	chopper.searchLightLocalTransform = TransformToLocalTransform(chopper.transform, GetBodyTransform(chopper.searchLight))
	
	chopper.sound = LoadLoop("chopper-loop.ogg")
	
	chopper.angle = 0.0
end


function chopperTick(dt, pos, aimPos, lightAimPos)
	chopper.angle = chopper.angle + 36*dt

	local diff = VecSub(aimPos, pos)
	diff[2] = 0
	local rot = QuatLookAt(pos, VecAdd(pos, diff))
	rot = QuatRotateQuat(rot, QuatEuler(math.sin(chopper.angle*0.053)*10, math.sin(chopper.angle*0.04)*10, 0))

	chopper.transform.pos = pos
	chopper.transform.rot = rot
	SetBodyTransform(chopper.body, chopper.transform)

	chopper.mainRotorLocalTransform.rot = QuatEuler(0, chopper.angle*57, 0)
	SetBodyTransform(chopper.mainRotor, TransformToParentTransform(chopper.transform, chopper.mainRotorLocalTransform))

	chopper.tailRotorLocalTransform.rot = QuatEuler(chopper.angle*57, 0, 0)
	SetBodyTransform(chopper.tailRotor, TransformToParentTransform(chopper.transform, chopper.tailRotorLocalTransform))

	local lp = TransformToLocalPoint(chopper.transform, lightAimPos)
	chopper.searchLightLocalTransform.rot = QuatLookAt(chopper.searchLightLocalTransform.pos, lp)
	SetBodyTransform(chopper.searchLight, TransformToParentTransform(chopper.transform, chopper.searchLightLocalTransform))

	PlayLoop(chopper.sound, chopper.transform.pos, 10)
end


