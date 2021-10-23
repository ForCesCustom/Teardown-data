#include "common.lua"
function init()
	j_rotate = FindJoint("rotate")
	f_speed = GetFloatParam("speed",500)
	f_speed2 = GetFloatParam("speed2",2000)
	f_transitionTime = GetFloatParam("transitiontime",3)
end

function tick(dt)
	if GetString("challenge.state") == "done" then
		f_speed = math.clamp(f_speed + dt * f_speed2 / f_transitionTime,f_speed,f_speed2)
	end
	SetJointMotor(j_rotate, f_speed*dt)
end