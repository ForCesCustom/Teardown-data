#include "common.lua"

function init()
	timer = 0
	trigger = FindTrigger("lightning")
	body = FindBody("lightning")
	explosions = FindLocations("explosion")
	fires = FindLocations("fire")
	sound = LoadSound("thunder-strike.ogg")
	transform = GetBodyTransform(body)

	shapes = GetBodyShapes(body)
	
	--Move lightning out of sight
	emissive = 0
	SetBodyTransform(body, Transform(Vec(0,10000,0)))
	setEmissive(0)
	
	smokeTimer = 0
	smokePos = Vec()
	
	done = false
end


function setEmissive(value)
	for i=1,#shapes do
		SetShapeEmissiveScale(shapes[i], value)
	end
end

function tick(dt)
	if not done and IsPointInTrigger(trigger, GetPlayerPos()) then
		timer = 0.7
		SetBodyTransform(body, transform)
		emissive=1
		
		smokePos = transform.pos
		smokeTimer = 2

		for i=1, #explosions do
			local t = GetLocationTransform(explosions[i])
			Explosion(t.pos, 1.5)
		end
		for i=1, #fires do
			local t = GetLocationTransform(fires[i])
			SpawnFire(t.pos)
		end
		PlaySound(sound)
		done = true
	else
		if timer > 0 then
			timer = timer - dt
			if timer <= 0 then
				SetBodyTransform(body, Transform(Vec(0,10000,0)))
				setEmissive(0)
			else
				emissive = clamp(emissive + math.random(-10,10)*0.1, 0.1, 1.0)
				setEmissive(emissive)
			end
		end
	end
	
	if smokeTimer > 0 then
		SpawnParticle("smoke", smokePos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 2.0, 4.0)
		smokeTimer = smokeTimer - dt
	end
end

