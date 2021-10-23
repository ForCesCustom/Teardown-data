pMap = GetBoolParam("map", true)
pQuicksave = GetBoolParam("quicksave", true)

function init()
	frame = 0
	pickFrame = 0
	grabFrame = 0
	mapFrame = 0
	
	usedMap = false
	usedTool = false
	usedVehicle = false
	usedGrab = false
	usedThrow = false
	
	escapeNotification = false
	mapNotification = false
	saveNotification = false
	escapeFrame=0
end


function notify(str, t)
	SetString("hud.notification", str)
end


function tick(dt)
	local missionDone = (frame > 60 and not GetBool("level.alarm") and GetBool("level.complete"))
	local alarm = GetBool("level.alarm")

	--Track game state
	if not usedMap and GetBool("game.map.enabled") then 
		usedMap = true 
	end
	if GetBool("game.paused") then
		return
	end
	
	--Generic hints. Only show if no other notifications are showing.
	if pMap then
		if not GetBool("hud.hasnotification") then
			if (frame%1500 == 300) and not usedMap and not missionDone and not alarm then
				notify("Press TAB to toggle map and objectives", 4)
			end
		end
	end

	if pQuicksave and not GetBool("hud.hasnotification") then
		if (frame > 4000) and usedMap and not saveNotification and not missionDone and not alarm then
			notify("Save your progress at any time by pressing ESC and choose Quicksave", 4)
			saveNotification = true
		end
	end
	
	if GetBool("game.map.enabled") then
		mapFrame = mapFrame + 1
		if mapFrame > 60 and not mapNotification then
			notify("Drag and zoom map with mouse", 4)
			mapNotification = true
		end
	end

	if missionDone and not GetBool("game.map.enabled") then
		if escapeFrame%600==0 then
			notify("Mission accomplished. Get to the escape vehicle.", 4)
		end
		escapeFrame = escapeFrame + 1
	end
end


function update(dt)
	if GetBool("game.paused") or GetBool("game.map.enabled") then
		return
	end
	frame = frame + 1
end
