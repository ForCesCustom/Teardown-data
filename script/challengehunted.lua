pId = GetStringParam("id", "tmp")
pMinDistans = GetFloatParam("mindist", 10.0)
pMaxDistans = GetFloatParam("maxdist", 95.0)

pStar1 = GetIntParam("star1", 5)
pStar2 = GetIntParam("star2", 10)
pStar3 = GetIntParam("star3", 15)
pStar4 = GetIntParam("star4", 20)
pStar5 = GetIntParam("star5", 25)

function init()
	done = false
	stars = 0
	
	limiter = true

	score = 0
	scorePosition = 0
	progressBarFill = 0
	thresholds = {pStar1, pStar2, pStar3, pStar4, pStar5}

	despawnSound = LoadSound("warning-beep.ogg")
	itemDespawnTimer = 0

	pickupSound = LoadSound("pickup.ogg")

	spawnLocationChecks = 0
	lastLocationIndex = 0

	pickup = FindShape("pickup")
	body = FindBody("pickup")
	bt = GetBodyTransform(body)

	SetTag(body, "interact", "Pick up")

	locations = FindLocations("itemlocation")
	locationIndex = 0

	arrow = LoadSprite("gfx/arrowdown.png")

	movePickup()

	--dispatch normal helicopter
	SetBool("challenge.chopper1",true)
	secondHelicopterThreshold = 15
	hardThreshold = 25
	
	SetString("challenge.state","")
end


function getStars()
	local s = 0

	if score >= 5 then
		s = 1
	end
	if score >= 10 then
		s = 2
	end
	if score >= 15 then
		s = 3
	end
	if score >= 20 then
		s = 4
	end
	if score >= 25 then
		s = 5
	end

	if s > 5 then s = 5 end
	return s
end


function tick(dt)
	if done then
		return
	end
	SetBool("level.disablequicksave", true)
	--SetPlayerHealth(1)

	if not done and GetFloat("game.player.health") == 0 then
		done = true
		--Player died, set state to done
		SetFloat("challenge.score", score)
		SetInt("challenge.stars", getStars())
		if score == 1 then
			SetString("challenge.scoredetails", score .." chest")
		else
			SetString("challenge.scoredetails", score .." chests")
		end		
		SetString("challenge.state", "done")
	end
	
	stars = getStars()

	if limiter and stars >= 3 then
		limiter = false
		pMinDistans = pMinDistans + 30.0
	end

	-- Add arrow to the pickup
	bt = GetBodyTransform(body)
	local arrowPos = TransformCopy(bt).pos
	local c = GetCameraTransform().pos
	c[2] = arrowPos[2]
	local p = VecCopy(arrowPos)
	p[2] = p[2] + math.sin(GetTime()*5)*0.3+0.3 + 2
	local t = Transform(p, QuatLookAt(arrowPos, c))
	DrawSprite(arrow, t, 2, 2, 1, 1, 1, 1, false, true)

	--Pickup
	if GetPlayerInteractShape() == pickup and InputPressed("interact") then
		score = score + 1 
		PlaySound(pickupSound)
		movePickup()

		if score == secondHelicopterThreshold and not GetBool("challenge.chopper2") then
			SetBool("challenge.chopper2",true)
		end
		if score == hardThreshold and not GetBool("challenge.hardmode") then
			SetBool("challenge.hardmode",true)
		end
	end

	if GetTime() > 3.3 then
		SetValue("scorePosition", 1, "linear", 0.5)
	end

	--Despawn items that are too deep in water for too long
	local inWater, depth = IsPointInWater(bt.pos)
	if inWater and depth > 1 then
		if itemDespawnTimer == 0 then
			itemDespawnTimer = GetTime()
		end
		if GetTime() - itemDespawnTimer > 4 then
			movePickup()
			PlaySound(despawnSound)
			itemDespawnTimer = 0
		end
	end
end


function movePickup()
	locationIndex = math.random(1,#locations)
	closestDist = VecLength(VecSub(GetLocationTransform(locations[locationIndex]).pos,GetPlayerTransform().pos))

	-- If the closest pickup is too close we run again
	if limiter == true then
		if closestDist < pMinDistans or closestDist > pMaxDistans  or lastLocationIndex == locationIndex then
			spawnLocationChecks = spawnLocationChecks + 1
			movePickup()
			return
		end
	else
		if closestDist < pMinDistans or lastLocationIndex == locationIndex then
			spawnLocationChecks = spawnLocationChecks + 1
			movePickup()
			return
		end
	end

	t = GetLocationTransform(locations[locationIndex])
	local a = QuatEuler(0, math.random(0,360), 0)
	t.rot = QuatRotateQuat(t.rot, a)

	local height = 1.3
	--QueryRaycast(origin, direction, maxDist, [radius], [rejectTransparent])
	local hit, dist = QueryRaycast(Vec(t.pos[1], t.pos[2] + height, t.pos[3]), Vec(0, -1, 0), height)	
	if hit then
		--print("location not empty: transform: ", t.pos[1], t.pos[2], t.pos[3], "  dist: " , dist)
		--move until on top
		while(hit)
		do
			hit, dist = QueryRaycast(Vec(t.pos[1], t.pos[2] + height, t.pos[3]), Vec(0, -1, 0), height)	
			spawnLocationChecks = spawnLocationChecks + 1

			t.pos[2] = t.pos[2] + math.max(0.1, (height - dist))
		end
	end

	local flyCheckHit, flyDist = QueryRaycast(Vec(t.pos[1], t.pos[2], t.pos[3]), Vec(0, -1, 0), 20)	
	if flyDist > 0.1 then
		t.pos[2] = t.pos[2] - flyDist
	end

	--double check distance to player after movement
	closestDist = VecLength(VecSub(t.pos,GetPlayerTransform().pos))
	if closestDist < 10 then
		spawnLocationChecks = spawnLocationChecks + 1
		movePickup()
		return
	end

	--make sure the pickup is not in water
	local pickupInwater, d = IsPointInWater(t.pos)
	if pickupInwater then
		--print("spawnpoint was in water")
		spawnLocationChecks = spawnLocationChecks + 1
		movePickup()
		return
	end

	--Set the pickup location
	SetBodyTransform(body, t)

	--print("spawnLocationChecks: ", spawnLocationChecks)
	spawnLocationChecks = 0
	lastLocationIndex = locationIndex
end


function draw()
	if not done then
		if score > 0 or GetTime() > 3.3 then
			UiPush()
				UiTranslate(0, -60 + 60*scorePosition)

				UiTranslate(UiCenter(), 65)
				UiAlign("center")
				UiTextOutline(0, 0, 0, 1)
				UiColor(1, 1, 1)
				UiFont("bold.ttf", 32)

				SetValue("progressBarFill", score / thresholds[5], "linear", 0.2)
								
				local progressBarWidth = 240
			UiPop()
			UiPush()
				UiTranslate(20,UiHeight()-80 + 80*(1-scorePosition))
				
				progressBar(progressBarWidth, 36, math.min(progressBarFill, 1.0), 1.0)
				--stars
				UiPush()											
					UiColor(1,1,0.5)							
					for i=1,stars do
						UiPush()	
							UiAlign("center middle")
							UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth - (progressBarWidth/10), 18)
							UiColor(0,0,0)
							UiImage("ui/common/star.png")
						UiPop()	
						if i < 5 then
							UiPush()
								--print("drawing one black line")
								UiAlign("center middle")
								UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth, 18)
								UiColor(0,0,0, 0.5)
								UiImage("../ui/hud/meterline.png")
							UiPop()	
						end
					end
					
					for i=1, 4 do		
						UiPush()
							UiAlign("center middle")
							UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth, 18)
							UiColor(1,1,1, 0.25)
							UiImage("../ui/hud/meterline.png")
						UiPop()							
					end
				UiPop()

				--amount of chests
				UiTranslate(progressBarWidth + 10, 18)
				UiFont("bold.ttf", 36)			
				UiAlign("left middle")
				UiText(score)

			UiPop()		
		end
	end
end

function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("../ui/common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("../ui/common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end