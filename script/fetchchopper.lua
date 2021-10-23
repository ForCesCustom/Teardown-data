-- Will animate chopper from location "start" to location "end" during the
-- last ten seconds of alarm timer, spinning the main and tail rotor.
-- The chopper is rotated to roughly face the player while animated

#include "chopper.lua"

pStartTime = GetFloatParam("starttime", 15)


function init()
	chopperInit()
	startPos = GetLocationTransform(FindLocation("start")).pos
	endPos = GetLocationTransform(FindLocation("end")).pos
	escapeVehicle = FindBody("escapevehicle", true)
end


function tick(dt)
	if GetBool("level.alarm") or GetString("challenge.state") == "done" then
		local timer = GetFloat("level.alarmtimer")
		if timer < pStartTime then

			local t = (pStartTime-timer)/pStartTime
			t = math.sqrt(t)

			local pos = VecLerp(startPos, endPos, t)
			local lookAt = GetPlayerPos()
			if escapeVehicle ~= 0 then
				lookAt = GetBodyTransform(escapeVehicle).pos
			end
			
			chopperTick(dt, pos, lookAt, lookAt)
		end
	end
end


