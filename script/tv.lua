function init()
	screen = FindScreen("tv")
	body = GetShapeBody(GetScreenShape(screen))
end

function tick(dt)
	if HasTag(body, "interact") then
		if IsBodyBroken(body) then
			RemoveTag(body, "interact")
		else
			if IsScreenEnabled(screen) then
				SetTag(body, "interact", "Turn off")
			else
				SetTag(body, "interact", "Turn on")
			end
		end
	end
	if GetPlayerInteractBody() == body and InputPressed("interact") then
		if IsScreenEnabled(screen) then
			SetScreenEnabled(screen, false)
			SetTag(body, "interact", "Turn on")
		else
			SetScreenEnabled(screen, true)
			SetTag(body, "interact", "Turn off")
		end
	end
end


