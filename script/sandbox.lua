dieFade = 0
weatherAlpha = 0
weatherActive = false

pUnlimited = GetBoolParam("unlimited", true)
pWeather = GetBoolParam("weather", true)

function init()
	SetBool("level.sandbox", true)
	SetBool("level.unlimitedammo", pUnlimited)
end

function tick(dt)
	--Fade to black and respawn when dead
	if GetFloat("game.player.health") == 0 then
		if dieFade == 0 then
			SetValue("dieFade", 1, "linear", 4)
		end
		if dieFade == 1 then
			RespawnPlayer()
			SetValue("dieFade", 0, "linear", 1)
		end	
	end

	--Unlimited ammo
	if pUnlimited then
		local tools = ListKeys("game.tool")
		for i=1,#tools do
			SetInt("game.tool."..tools[i]..".ammo", 9999)
		end
	end
	
	if pWeather then
		if PauseMenuButton("Change weather") then
			weatherActive = true
		end
		
		if weatherActive and weatherAlpha == 0.0 then
			SetValue("weatherAlpha", 1.0, "easeout", 0.3)
		end
		if not weatherActive and weatherAlpha == 1.0 then
			SetValue("weatherAlpha", 0.0, "easein", 0.3)
		end
	end
end


function draw(dt)
	if dieFade > 0 then
		UiColor(0,0,0, dieFade)
		UiRect(UiWidth(), UiHeight())
	end
	
	if weatherAlpha > 0.0 then
		if weatherActive then
			UiMakeInteractive()
			SetBool("game.disablepause", true)
		end
		
		local height = 450
		UiTranslate(-280+270*weatherAlpha, UiMiddle())
		UiAlign("left middle")
		UiColor(.0, .0, .0, 0.75*weatherAlpha)
		UiImageBox("ui/common/box-solid-10.png", 280, height, 10, 10)
		UiWindow(280, height)

		UiAlign("top left")
		if not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb") then
			weatherActive = false
		end
		if InputPressed("pause") then
			weatherActive = false
		end

		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2, 50)

			UiFont("regular.ttf", 26)

			local bw = 230
			local bh = 40
			local space = 7
			local sep = 20

			UiColor(0.96, 0.96, 0.96)
			UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96, 0.8)

			if UiTextButton("Sunrise", 200, bh) then
				setWeather("sunrise")
			end
			UiTranslate(0, bh+space)
			
			if UiTextButton("Sunny", 200, bh) then
				setWeather("sunny")
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Foggy", 200, bh) then
				setWeather("foggy")
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Light rain", 200, bh) then
				setWeather("rain")
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Sunset", 200, bh) then
				setWeather("sunset")
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Night", 200, bh) then
				setWeather("night")
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Rainy night", 200, bh) then
				setWeather("rainynight")
			end
			UiTranslate(0, bh+space)

			UiTranslate(0, sep)

			if UiTextButton("Close", 150, bh) then
				weatherActive = false
			end
		UiPop()
	end
end


function setWeather(env)
	SetEnvironmentDefault()
	if env == "sunset" then
		SetEnvironmentProperty("skybox", "sunset.dds")
		SetEnvironmentProperty("skyboxtint", 1, 0.5, 0.2) 
		SetEnvironmentProperty("fogColor", 0.3, 0.2, 0.08) 
		SetEnvironmentProperty("fogParams", 80, 200, 1, 6)
		SetEnvironmentProperty("sunBrightness", 1)
		SetEnvironmentProperty("sunColorTint", 0.2, 0.3, 1) 
		SetEnvironmentProperty("sunFogScale", 1.0)
		SetEnvironmentProperty("sunGlare", 0.8)
		SetEnvironmentProperty("exposure", 1, 5)
		SetEnvironmentProperty("nightlight", false)
	elseif env == "sunny" then
		SetEnvironmentProperty("skybox", "day.dds")
		SetEnvironmentProperty("skyboxbrightness", 0.7)
		SetEnvironmentProperty("fogColor", 0.9, 0.9, 0.9) 
		SetEnvironmentProperty("fogParams", 50, 200, 0.9, 8) 
		SetEnvironmentProperty("sunBrightness", 4) 
		SetEnvironmentProperty("sunColorTint", 1, 0.8, 0.6)
		SetEnvironmentProperty("exposure",1, 5)
		SetEnvironmentProperty("sunFogScale",0.15)
		SetEnvironmentProperty("nightlight", false)
	elseif env == "night" then
		SetEnvironmentProperty("skybox", "cloudy.dds")
		SetEnvironmentProperty("skyboxbrightness", 0.05)
		SetEnvironmentProperty("fogColor", 0.02, 0.02, 0.024)
		SetEnvironmentProperty("fogParams", 20, 120, 0.9, 2)
		SetEnvironmentProperty("exposure", 1, 5)
		SetEnvironmentProperty("ambience", "outdoor/night.ogg")
		SetEnvironmentProperty("nightlight", true)
	elseif env == "sunrise" then
		SetEnvironmentProperty("skybox", "cloudy.dds")
		SetEnvironmentProperty("skyboxtint", 1, 0.4, 0.2)
		SetEnvironmentProperty("skyboxbrightness", 0.6)
		SetEnvironmentProperty("fogColor", 1, 0.2, 0.1)
		SetEnvironmentProperty("fogParams", 30, 160, 0.95, 6)
		SetEnvironmentProperty("exposure", 1, 5)
		SetEnvironmentProperty("nightlight", true)
	elseif env == "foggy" then
		SetEnvironmentProperty("skybox", "cloudy.dds")
		SetEnvironmentProperty("skyboxtint", 1.0, 0.6, 0.4)
		SetEnvironmentProperty("fogColor", 0.2, 0.18, 0.15)
		SetEnvironmentProperty("fogParams", 0, 60, 0.9, 3)
		SetEnvironmentProperty("exposure", 1, 5)
		SetEnvironmentProperty("wetness", 0.4)
		SetEnvironmentProperty("puddleamount", 0.3)
		SetEnvironmentProperty("nightlight", false)
		SetEnvironmentProperty("slippery", 0.1)
	elseif env == "rain" then
		SetEnvironmentProperty("skybox", "cloudy.dds")
		SetEnvironmentProperty("skyboxtint", 1.0, 0.6, 0.4)
		SetEnvironmentProperty("fogColor", 0.1, 0.1, 0.1)
		SetEnvironmentProperty("fogParams", 0, 70, 0.9, 1)
		SetEnvironmentProperty("exposure", 1, 5)
		SetEnvironmentProperty("wetness", 0.5)
		SetEnvironmentProperty("puddleamount", 0.5)
		SetEnvironmentProperty("puddlesize", 0.7)
		SetEnvironmentProperty("rain", 0.5)
		SetEnvironmentProperty("ambience", "outdoor/rain_light.ogg")
		SetEnvironmentProperty("nightlight", false)
		SetEnvironmentProperty("slippery", 0.2)
	elseif env == "rainynight" then
		SetEnvironmentProperty("skybox", "cloudy.dds")
		SetEnvironmentProperty("skyboxbrightness", 0.02)
		SetEnvironmentProperty("fogColor", 0.02, 0.02, 0.024)
		SetEnvironmentProperty("fogParams", 10, 90, 0.9, 2)
		SetEnvironmentProperty("exposure", 1, 5)
		SetEnvironmentProperty("wetness", 0.7)
		SetEnvironmentProperty("puddleamount", 0.7)
		SetEnvironmentProperty("puddlesize", 0.7)
		SetEnvironmentProperty("rain", 0.9)
		SetEnvironmentProperty("ambience", "outdoor/rain_heavy.ogg")
		SetEnvironmentProperty("nightlight", true)
		SetEnvironmentProperty("slippery", 0.3)
	end
end
