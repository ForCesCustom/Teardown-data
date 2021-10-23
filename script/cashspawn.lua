#include "common.lua"
#include "game.lua"

pCash = GetIntParam("cash", 0)

function init()
	body = FindBody("cash")
	transform = GetBodyTransform(body)
	SetBodyTransform(body, Transform(Vec(0,-20,0)))
	snd = LoadSound("valuable.ogg")
	spawned = false
	arrow = LoadSprite("gfx/arrowdown.png")
end

function tick(dt)
	if not spawned and not GetBool("savegame.reward."..pCash) then
		local score = GetInt("savegame.hub.score")
		for i=1,#gRanks do
			if score >= gRanks[i].score and gRanks[i].cash == pCash then
				SetBodyTransform(body, transform)
				SetTag(body, "interact", "Pick up")
				spawned = true
				SetBool("level.toolspawn", true)
			end
		end
	end
	
	if spawned then
		--Make sure cash reward cannot be picked up twice after quickload
		if GetBool("savegame.reward."..pCash) then
			Delete(body)
			body = nil
		end
		if body ~= nil then
			if GetPlayerInteractBody() == body then
				if InputPressed("interact") then
					PlaySound(snd)
					SetBool("savegame.reward."..pCash, true)
					SetInt("savegame.cash", GetInt("savegame.cash")+pCash)
					Delete(body)
					body = nil
					SetBool("level.toolspawn", false)
					SetString("hud.notification", "Picked up $"..pCash.." cash reward")
				end
			else
				local t = TransformCopy(transform)
				t.rot = QuatLookAt(t.pos, GetCameraTransform().pos)
				local offset = 3 + math.sin(4.0*GetTime())*0.5
				t.pos[2] = t.pos[2] + offset
				DrawSprite(arrow, t, 2, 2, 1, 1, 1, 1, false, true)
			end
		end
	end	
end
