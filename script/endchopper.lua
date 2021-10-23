-- Animate chopper to chase player

#include "common.lua"

pSpeed = 15
pShootDistance = 40
pSlowdownDistance = 35


function rndFloat(mi, ma)
	return mi + (ma-mi)*(math.random(0, 1000000)/1000000.0)
end

function init()
	chopper = FindBody("chopper")
	chopperTransform = GetBodyTransform(chopper)
	
	mainRotor = FindBody("mainrotor")
	mainRotorLocalTransform = TransformToLocalTransform(chopperTransform, GetBodyTransform(mainRotor))

	tailRotor = FindBody("tailrotor")
	tailRotorLocalTransform = TransformToLocalTransform(chopperTransform, GetBodyTransform(tailRotor))

	lightSource = FindLight("light")

	searchLight = FindBody("light")
	searchLightLocalTransform = TransformToLocalTransform(chopperTransform, GetBodyTransform(searchLight))
	
	chopperSound = LoadLoop("chopper-loop.ogg")
	chopperChargeSound = LoadSound("chopper-charge.ogg")
	chopperShootSound = LoadSound("chopper-shoot0.ogg")
	chopperRocketSound = LoadSound("tools/launcher0.ogg")
	
	chopperStartSound = LoadSound("chopper-start.ogg")
	chopperEndSound = LoadSound("chopper-end.ogg")
	chopperSoundSound = LoadSound("chopper-sound.ogg")
	
	angle = 0.0
	targetPos = chopperTransform

	chopperHeight = 15
	chopperVel = Vec()
	chopperTargetPos = VecAdd(chopperTransform.pos, Vec(0,0,0))
	chopperTargetRot = QuatEuler()
	searchLightTargetRot = QuatEuler()
	searchLightRot = QuatEuler()
	
	shootMode = "search"
	shootTimer = 0
	
	timeSinceSeen = 0
	timeSeen = 0
	inVehicle = false
	
	visible = 0

	playerSeen = false
end


function getDistanceToPlayer()
	local playerPos = GetPlayerPos()
	return VecLength(VecSub(playerPos, chopperTransform.pos))
end


function canSeePlayer()
	local playerPos = GetPlayerPos()

	--Direction to player
	local dir = VecSub(playerPos, chopperTransform.pos)
	local dist = VecLength(dir)
	dir = VecNormalize(dir)

	QueryRejectVehicle(GetPlayerVehicle())
	QueryRejectBody(chopper)
	return not QueryRaycast(chopperTransform.pos, dir, dist, 0, true)
end


function shoot()
	local hoverPos = VecCopy(targetPos)

	local toPlayer = VecSub(hoverPos, chopperTargetPos)
	toPlayer[2] = 0
	local l = VecLength(toPlayer)

	PlaySound(chopperShootSound, chopperTransform.pos, 5, false)

	local p = chopperTransform.pos
	local d = VecNormalize(VecSub(targetPos, p))
	local perp = Vec(rndFloat(-1, 1), rndFloat(-1, 1), rndFloat(-1, 1))
	perp = VecNormalize(VecSub(perp, VecScale(d, VecDot(d, perp))))
	local spread = (1-visible)*6.0
	local v = GetPlayerVehicle()
	if v ~= 0 then
		spread = spread * 2
	end
	spread = spread + rndFloat(0.0, 0.5)
	--In player is hidden, use random spread
	if timeSinceSeen > 5.0 then
		spread = rndFloat(0.0, 8.0)
	end
	local offPos = VecAdd(targetPos, VecScale(perp, spread))
	d = VecNormalize(VecSub(offPos, p))
	p = VecAdd(p, VecScale(d, 5))
	Shoot(p, d)	
end


function rocket()
	PlaySound(chopperRocketSound, chopperTransform.pos, 5, false)

	local p = chopperTransform.pos
	local d = VecNormalize(VecSub(targetPos, p))
	local spread = 0.03
	d[1] = d[1] + (math.random()-0.5)*2*spread
	d[2] = d[2] + (math.random()-0.5)*2*spread
	d[3] = d[3] + (math.random()-0.5)*2*spread
	d = VecNormalize(d)
	p = VecAdd(p, VecScale(d, 5))
	Shoot(p, d, 1)
end


function tickShooting(dt)
	if GetFloat("game.player.health") == 0.0 or GetString("level.state") == "win" then
		return
	end

	local inRange = (getDistanceToPlayer() < pShootDistance)
	
	if shootTimer > 0 then
		shootTimer = shootTimer - dt
		return
	end
	if shootMode == "search" then
		if inRange then
			shootMode = "charge"
			shootTimer = 1
			PlaySound(chopperChargeSound, chopperTransform.pos, 2, false)
		end
	elseif shootMode == "charge" then
		shootMode = "shoot"
		shootCount = math.random(3, 4)
	elseif shootMode == "shoot" then
		if shootCount > 0 then
			shootCount = shootCount - 1
			shoot();
			shootTimer = 0.2
		else
			if inRange then
				shootMode = "charge"
				shootTimer = 4
			else
				shootMode = "search"
			end
		end
	end
end


function tick(dt)
	if not GetBool("level.endchopper") then
		return
	end

	playerSeen = canSeePlayer()
	targetPos = GetPlayerPos()

	if playerSeen then
		timeSinceSeen = 0
		timeSeen = timeSeen + GetTimeStep()
		visible = visible + GetTimeStep() * 0.125
	else
		timeSinceSeen = timeSinceSeen + GetTimeStep()
		timeSeen = 0
		visible = visible - GetTimeStep() * 0.25
	end
	
	if inVehicle then
		if GetPlayerVehicle() == 0 then
			inVehicle = false
			visible = math.min(visible, 0.5)
		end
	else
		if GetPlayerVehicle() ~= 0 then
			inVehicle = true
			visible = math.min(visible, 0.5)
		end
	end
	
	visible = math.clamp(visible, 0.0, 1.0)
	
	--Shoot more if player is seen
	if playerSeen then
		shootTimer = math.min(1.0, shootTimer)
	end
	
	angle = angle + 0.6

	tickShooting(dt)

	local hoverPos = VecCopy(targetPos)
	local toPlayer = VecSub(hoverPos, chopperTargetPos)
	toPlayer[2] = 0
	local l = VecLength(toPlayer)
	local minDist = 0.5
	if l > minDist then
		--Make helicopter slower close to player
		local speed = (l-minDist)/(pSlowdownDistance)*pSpeed
		speed = clamp(speed, 1, pSpeed)
		toPlayer = VecNormalize(toPlayer)
		chopperTargetPos = VecAdd(chopperTargetPos, VecScale(toPlayer, speed*dt))
	end

	chopperTargetPos[2] = chopperHeight
	QueryRejectBody(chopper)
	QueryRejectBody(mainRotor)
	QueryRejectBody(tailRotor)
	QueryRejectBody(searchLight)
	local probe = VecCopy(chopperTargetPos)
	probe[2] = 100
	local hit, dist = QueryRaycast(probe, Vec(0,-1,0), 100, 2.0)
	if hit then
		chopperHeight = 100 - dist + 15
	end
	chopperTargetPos[2] = chopperHeight

	local toTarget = VecNormalize(VecSub(targetPos, chopperTargetPos))
	toTarget[2] = clamp(toTarget[2], -0.1, 0.1);
	local lookPoint = VecAdd(chopperTargetPos, toTarget);
	lookPoint[2] = chopperTargetPos[2]
	local rot = QuatLookAt(chopperTargetPos, lookPoint)
	rot = QuatRotateQuat(rot, QuatEuler(math.sin(angle*0.053)*10, math.sin(angle*0.04)*10, 0))
	chopperTargetRot = rot

	SetBodyTransform(chopper, chopperTransform)
	PlayLoop(chopperSound, chopperTransform.pos, 8, false)
	
	mainRotorLocalTransform.rot = QuatEuler(0, angle*57, 0)
	SetBodyTransform(mainRotor, TransformToParentTransform(chopperTransform, mainRotorLocalTransform))

	tailRotorLocalTransform.rot = QuatEuler(angle*57, 0, 0)
	SetBodyTransform(tailRotor, TransformToParentTransform(chopperTransform, tailRotorLocalTransform))

	--Searchlight
	local aimPos = VecCopy(targetPos)
	local radius = 2
	if not aimAngle then aimAngle = 0 end
	aimAngle = aimAngle + dt*1.0
	local x = math.cos(aimAngle) * radius
	local z = math.sin(aimAngle*1.7) * radius
	aimPos = VecAdd(aimPos, Vec(x, 0, z))

	local lightTransform = TransformToParentTransform(chopperTransform, searchLightLocalTransform)
	searchLightTargetRot = QuatLookAt(lightTransform.pos, aimPos)
	lightTransform.rot = searchLightRot
	SetBodyTransform(searchLight, lightTransform)

	if not playerSeen then
		local alpha = clamp(1.0 - (getDistanceToPlayer()-50) / 50, 0.0, 0.5)
		if alpha > 0.1 then
			DrawBodyOutline(chopper, alpha)
			DrawBodyOutline(mainRotor, alpha)
			DrawBodyOutline(tailRotor, alpha)
		end
	end
end

function update(dt)
	--Move chopper towards target position smoothly
	local acc = VecSub(chopperTargetPos, chopperTransform.pos)
	chopperVel = VecAdd(chopperVel, VecScale(acc, dt))
	chopperVel = VecScale(chopperVel, 0.98)
	chopperTransform.pos = VecAdd(chopperTransform.pos, VecScale(chopperVel, dt))

	--Rotate chopper smoothly towards target rotation
	chopperTransform.rot = QuatSlerp(chopperTransform.rot, chopperTargetRot, 0.02)

	--Rotate search light smoothly towards target rotation
	searchLightRot = QuatSlerp(searchLightRot, searchLightTargetRot, 0.05)
end
