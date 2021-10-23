#include "common.lua"

function init()
	teslacube = FindShape("teslacube")
	sparks = FindBodies("spark")
	sparkTransforms = {}
	for i = 1,#sparks do
		sparkTransforms[i] = GetBodyTransform(sparks[i])
		SetBodyTransform(sparks[i], Transform(Vec(0,10000,0)))
		SetShapeEmissiveScale(sparks[i], 0)
	end
	sparkSounds = LoadSound("spark0.ogg")
	random = 0
	justSparked = false
	sparkTimer = 0
	glimmerTimer = 0
	unbroken = true
	isdone = false
end

function tick(dt)
	if isdone then return end
	if IsShapeBroken(teslacube) and unbroken then
		SetBool("level.alarm", true)
		glimmerTimer = 0.5
		unbroken = false
	else
		if glimmerTimer > 0 then
			if justSparked then
				SetShapeEmissiveScale(sparks[rndSpark], sparkTimer*4)
				if sparkTimer < 0 then
					random = (math.random(2)-1)*0.3
					SetBodyTransform(sparks[rndSpark], Transform(Vec(0,10000,0)))
					SetShapeEmissiveScale(sparks[rndSpark], 0)
					justSparked = false
				end
			end
			if random < 0 and not justSparked then
				rndSpark = math.random(#sparks)
				SetBodyTransform(sparks[rndSpark], sparkTransforms[rndSpark])
				SetShapeEmissiveScale(sparks[rndSpark], glimmerTimer)
				justSparked = true
				sparkTimer = 0.1
				PlaySound(sparkSounds,GetBodyTransform(sparks[rndSpark]).pos)
			end
			glimmerTimer = glimmerTimer - dt
		end
	end

	if glimmerTimer <= 0 and not unbroken then
		for i = 1,#sparks do
			if justSparked then
				SetBodyTransform(sparks[rndSpark], Transform(Vec(0,10000,0)))
				SetShapeEmissiveScale(sparks[rndSpark], 0)
				justSparked = false
			end		
		end
		isdone = true
	end
	random = random - dt
	sparkTimer = sparkTimer - dt
end
