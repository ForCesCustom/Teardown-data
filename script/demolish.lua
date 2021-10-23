-- Demolish building 
-- Put trigger around demolition zone and tag with "demolish"
-- Put empty body as target at the desired height level and tag with "target=custom"

#include "common.lua"

pSprite = GetStringParam("sprite", "")
pSpriteSizeX = GetFloatParam("spritex", 7)
pSpriteSizeY = GetFloatParam("spritey", 8)

function init()
	done = false
	demolishPos = Vec()
	demolishHeight = 0
	
	trigger = FindTrigger("demolish")
	target = FindBody("target")
	maxHeight = GetBodyTransform(target).pos[2]

	if pSprite ~= "" then
		sprite = LoadSprite(pSprite)
	end
end


function tick(dt)
	if not done then
		if sprite then
			DrawSprite(sprite, GetBodyTransform(target), pSpriteSizeX, pSpriteSizeY, 1, 1, 1, 1, true, false)
		end
		local empty, p = IsTriggerEmpty(trigger, true)
		if not empty and p[2] > maxHeight then
			demolishPos = p
			demolishHeight = p[2] - maxHeight		
		else
			SetString("hud.notification", "Demolition complete")
			SetTag(target, "target", "cleared")
			done = true
		end
	end
end


function draw()
	if not done and not GetBool("game.map.enabled") then
 		UiPush()
			local pos = demolishPos
			local cp = GetCameraTransform().pos
			local dx = pos[1]-cp[1]
			local dz = pos[3]-cp[3]
			local dist = math.sqrt(dx*dx+dz*dz)
			if dist < 25 then
				local h = demolishHeight
				local x, y, dist = UiWorldToPixel(pos)
				if dist > 0 then
					UiFont("regular.ttf", 20)
					UiTranslate(x, y)
					UiAlign("center middle")
					UiImage("ui/common/dot.png")
					UiTranslate(0, -20)
					UiAlign("center middle")
					UiText(math.ceil(h*10)/10 .. " METERS TOO TALL")
				end
			end
		UiPop()
	end
end

