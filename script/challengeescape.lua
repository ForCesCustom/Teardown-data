-- Animated escape vehicle forward when global state is win

#include "common.lua"

pSound = GetStringParam("sound", "escape-boat.ogg")
pAcceleration = GetFloatParam("acceleration", 6)
pMaxSpeed = GetFloatParam("maxspeed", 20)
pFollowCam = GetIntParam("followcam", 1)
pDynamic = GetBoolParam("dynamic", false)
pArrowSize = 2


function init()
	local arrow = FindLocation("arrow")
	if arrow ~= 0 then
		arrowSprite = LoadSprite("gfx/arrowdown.png")
		arrowPos = GetLocationTransform(arrow).pos
		arrowPos[2] = arrowPos[2] + pArrowSize/2
	end

	cameraPos = GetLocationTransform(FindLocation("escapecamera")).pos
	body = FindBody("escapevehicle")
	shapes = GetBodyShapes(body)
	for i=1,#shapes do
		SetShapeEmissiveScale(shapes[i], 0.0)
	end
	SetTag(body, "interact", "Escape")
	SetTag(body, "nocull")
	transform = GetBodyTransform(body)
	dir = TransformToParentVec(transform, Vec(0, 0, -1))
	sound = LoadSound(pSound)
	speed = 0
	followCam = true
	hatch = FindShape("hatch")
end


function tick(dt)
	local state = GetString("challenge.state")

	--Outline escape vehicle when mission is complete
	if state == "" then
		--Draw escape vehicle arrow
		if arrowSprite and GetBool("level.alarm") then
			local c = GetCameraTransform().pos
			c[2] = arrowPos[2]
			local p = VecCopy(arrowPos)
			p[2] = p[2] + math.sin(GetTime()*5)*0.3+0.3
			local t = Transform(p, QuatLookAt(arrowPos, c))
			DrawSprite(arrowSprite, t, pArrowSize, pArrowSize, 1, 1, 1, 1, true, false)
		end
		if GetPlayerInteractBody() == body then
			DrawBodyOutline(body, 1)
			if InputPressed("interact") then
				if GetBool("level.alarm") then
					SetString("challenge.state", "done")				
					SetBool("level.alarm",false)
				else
					SetString("hud.notification", "You need to clear at least one target")
				end
			end
		end
	end

	--Third person win/lose camera
	if state == "done" or state == "fail" then
		if followCam then
			t = Transform(cameraPos, QuatLookAt(cameraPos, GetBodyTransform(body).pos))
			if pFollowCam == 0 then
				followCam = false
			end
		end
		SetCameraTransform(t, 90)
	end
end


function update(dt)
	--Drive away
	if GetString("challenge.state") == "done" then
		if speed == 0 then
			PlaySound(sound)
			for i=1,#shapes do
				SetShapeEmissiveScale(shapes[i], 1.0)
			end
			--Close hatch on trucks
			if hatch ~= 0 then
				local t = GetShapeLocalTransform(hatch)
				t.rot = Quat()
				SetShapeLocalTransform(hatch, t)
			end
		end
		speed = speed + pAcceleration * dt
		if speed > pMaxSpeed then speed = pMaxSpeed end
		local vel = VecScale(dir, speed)
		transform.pos = VecAdd(transform.pos, VecScale(vel, dt))
		if pDynamic then
			SetBodyDynamic(body, true)
			SetBodyVelocity(body, vel)
		end
		SetBodyTransform(body, transform)
	end
end

