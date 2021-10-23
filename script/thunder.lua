#include "common.lua"

function init()
	lightBody = FindBody("thunder")
	local s = GetBodyShapes(lightBody)
	lightShape = s[1]
	SetShapeEmissiveScale(lightShape, 0)	
	timer = 2
	lightning = 0
	lightningStrength = 0
	thunderSound = LoadSound("thunder0.ogg")
	
	nextSoundTimer = 0
	nextSound = 0
	nextSoundVolume = 0
	nextSoundTimer = 0
end


function tick(dt)
	if not GetBool("game.map.enabled") then
		timer = timer - dt
	end
	if timer <= 0 then
		lightning = math.random(2, 5)*0.1
		lightningStrength = 0
		local x = math.random(-100, 100)
		local y = 80
		local z = math.random(-100, 100)
		SetBodyTransform(lightBody, Transform(Vec(x, y, z)))
		nextSoundVolume = 0.5 + math.random(1, 5)*0.1
		nextSoundTimer = 0.5 + math.random(1, 10)*0.1
		timer = math.random(3, 10)
	end

	if nextSoundTimer > 0 then
		nextSoundTimer = nextSoundTimer - dt
		if nextSoundTimer <= 0 then
			PlaySound(thunderSound, GetPlayerPos(), nextSoundVolume)
		end
	end
	
	if lightning > 0 then
		lightning = lightning - dt
		lightningStrength = clamp(lightningStrength + math.random(-10,10)*0.1, 0.1, 1.0)
	end

	if lightning > 0 then
		SetShapeEmissiveScale(lightShape, lightningStrength)	
	else
		SetShapeEmissiveScale(lightShape, 0)	
	end
end

