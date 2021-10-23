function init()
	screen = FindScreen("terminal")
	body = GetShapeBody(GetScreenShape(screen))
end

function tick(dt)
	if HasTag(body, "interact") then
		if GetPlayerScreen() == screen then
			SetTag(body, "interact", "Leave")
		else
			SetTag(body, "interact", "Operate")
		end
	end
	if GetPlayerScreen() ~= screen and GetPlayerInteractBody() == body and InputPressed("interact") then
		SetPlayerScreen(screen)
	end
end


