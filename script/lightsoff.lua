tag = GetStringParam("tag","turnoff")
everywhere = GetBoolParam("global",false)
lights = FindLights(tag,everywhere)
function init()
	for i=1, #lights do
		SetLightEnabled(lights[i], false)
	end
end