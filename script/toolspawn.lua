#include "common.lua"
#include "game.lua"

pTool = GetStringParam("tool", "none")

function init()
	body = FindBody("tool")
	transform = GetBodyTransform(body)
	SetBodyTransform(body, Transform(Vec(0,-20,0)))
	snd = LoadSound("tool_pickup.ogg")
	spawned = false
	arrow = LoadSprite("gfx/arrowdown.png")
	upgradeTimer = 0
	toolTutorial = 0
end


function tick(dt)
	if not spawned and not GetBool("game.tool."..pTool..".enabled") then
		local score = GetInt("savegame.hub.score")
		for i=1,#gRanks do
			if score >= gRanks[i].score and gRanks[i].tool == pTool then
				SetBodyTransform(body, transform)
				SetTag(body, "interact", "Pick up")
				spawned = true
				SetBool("level.toolspawn", true)
			end
		end
	end
	
	if spawned then
		if body ~= nil then
			if GetPlayerInteractBody() == body then
				if InputPressed("interact") then
					PlaySound(snd)
					SetBool("savegame.tool."..pTool..".enabled", true)
					SetString("game.player.tool", pTool)
					SetBool("game.tool."..pTool..".enabled", true)
					Delete(body)
					body = nil
					upgradeTimer = 3
					--Copy over default configuration for tool
					for j=1, #gTools[pTool].upgrades do
						local id = gTools[pTool].upgrades[j].id
						local value = gTools[pTool].upgrades[j].default
						local saved = GetInt("savegame.tool."..pTool.."."..id)
						if saved > value then
							value = saved 
						end
						SetInt("game.tool."..pTool.."."..id, value)
					end

					if pTool == "plank" then
						SetValue("toolTutorial", 1, "cosine", 0.25) 
					end
					SetBool("level.toolspawn", false)
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
	
	if upgradeTimer > 0 then
		upgradeTimer = upgradeTimer - GetTimeStep()
		if upgradeTimer <= 0 then
			SetString("hud.notification", "You can upgrade your tools in the computer terminal")
		end
	end
end


function draw()
	if toolTutorial > 0 then
		UiMakeInteractive()
		UiPush()
			if not toolTutorialStep then
				toolTutorialStep = 1
			end

			local img
			local txt
			if toolTutorialStep == 1 then
				img = "ui/hud/tutorial/plank-ramp.jpg"
				txt = "Planks can be used to build primitive ramps"
			elseif toolTutorialStep == 2 then
				img = "ui/hud/tutorial/plank-lift.jpg"
				txt = "You can also attach objects with planks to lift or drag heavy items"
			else
				img = "ui/hud/tutorial/plank-complex.jpg"
				txt = "Use multiple planks to build complex structures"
			end

			local visible = toolTutorial
			UiBlur(visible)
			UiColor(0.7,0.7,0.7, 0.25*visible)
			UiRect(UiWidth(), UiHeight())
			UiColorFilter(1,1,1,visible)

			UiTranslate(UiCenter(), UiMiddle())
			UiAlign("center middle")
			UiColor(.0, .0, .0, 0.7*visible)
			UiScale(1, visible)
			UiImageBox("ui/common/box-solid-shadow-50.png", 800, 620, -50, -50)
			UiWindow(800, 620)

			UiAlign("center")
			UiTranslate(UiCenter(), 60)

			UiPush()
				UiFont("bold.ttf", 32)
				UiColor(1,1,1)
				UiScale(1.5)
				UiText("Plank tool")
			UiPop()

			UiFont("regular.ttf", 26)
			UiColor(1, 1, 1)

			UiTranslate(0, 40)
			UiImage(img)

			UiTranslate(0, 400)
			UiPush()
				UiFont("regular.ttf", 22)
				UiText(txt)
			UiPop()

			UiTranslate(0, 80)
			UiPush()
				UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1, 1, 1, 0.8)
				if toolTutorialStep < 3 then
					if UiTextButton("Next", 200, 40) then
						toolTutorialStep = toolTutorialStep + 1
					end
				else
					if UiTextButton("Close", 200, 40) then
						SetValue("toolTutorial", 0, "cosine", 0.25) 
					end
				end
			UiPop()
		UiPop()
	end
end
