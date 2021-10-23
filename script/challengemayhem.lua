pStar1 = GetIntParam("star1", 200000)
pStar2 = GetIntParam("star2", 400000)
pStar3 = GetIntParam("star3", 600000)
pStar4 = GetIntParam("star4", 800000)
pStar5 = GetIntParam("star5", 1000000)
pGraceLimit = GetIntParam("grace", 1000)

function init()
	d = 0
	timeLeft = 60
	done = false
	stars = 0

	notificationAlpha = 1

	progressBarFill = 0
	thresholds = {pStar1, pStar2, pStar3, pStar4, pStar5}
	
	scorePosition = 0
end


function getStars()
	local s = 0
	if d > pStar1 then
		s = 1
	end
	if d > pStar2 then
		s =  2
	end
	if d > pStar3 then
		s =  3
	end
	if d > pStar4 then
		s =  4
	end
	if d > pStar5 then
		s =  5
	end

	if s > 5 then s = 5 end
	return s
end


function tick(dt)
	if not done and GetFloat("game.player.health") == 0 then
		done = true
		--Player died, set state to fail
		SetString("challenge.state", "fail")
	end
	
	if not done then
		d = GetInt("game.brokenvoxels") 
		stars = getStars()

		--make sure to not overlap intro description
		if GetTime() > 3.3 then
			SetValue("scorePosition", 1, "linear", 0.5)
		end

		if d > pGraceLimit then
			--Tell challenge script to play heist music
			SetString("challenge.music", "heist.ogg")
			
			SetBool("level.disablequicksave", true)

			timeLeft = math.max(0, timeLeft - dt)
			if timeLeft == 0 then
				--Challenge is over, write score, stars and score details to registry and set state to done
				SetFloat("challenge.score", d)
				SetInt("challenge.stars", getStars())
				SetString("challenge.scoredetails", d.." voxels")
				SetString("challenge.state", "done")
				done = true
			end
		end
	end
end


function draw()
	if not done then
		if d > 0 or GetTime() > 3.3 then
			
			if GetTime() < 8.0 then
				UiPush()				
					local n = notificationAlpha
					UiTextOutline(0,0,0,0)
					UiTranslate(UiCenter(), 100)
					UiAlign("center middle")

					local notification = "The timer starts when 1000 voxels have been destroyed."

					UiFont("bold.ttf", 24)
					local w,h = UiGetTextSize(notification)
					UiColor(0,0,0, 0.7*n)
					UiImageBox("ui/common/box-solid-10.png", w+32, h+16, 10, 10)
					UiColor(1,1,1, n)
					UiText(notification)
				UiPop()
			end
			if GetTime() > 7.5 then
				SetValue("notificationAlpha", 0, "linear", 0.5)
			end
			
			if timeLeft >= 0 then
				UiPush()
					UiTranslate(0, -140 + 140*scorePosition)

					UiFont("bold.ttf", 32)
					local timeText = ""
					if math.ceil(timeLeft*10) % 10 == 0 then
						timeText = (math.ceil(timeLeft*10)/10 .. ".0")
					else
						timeText = (math.ceil(timeLeft*10)/10)
					end
					
					UiTranslate(UiCenter(), 65)
					UiAlign("left")
					UiTextOutline(0, 0, 0, 1)
					UiColor(1, 1, 1)

					UiPush()
						if timeLeft > 10 then
							UiTranslate(-40, 0)
						else
							UiTranslate(-20, 0)
						end
						UiScale(2.0)
						UiTranslate(-10,0)
						UiText(timeText)
					UiPop()
				UiPop()
				UiPush()
					UiTranslate(20,UiHeight()-80 + 80*(1-scorePosition))
					if pGraceLimit ~= 0 and d < pGraceLimit then
						local progressBarWidth = 240
						UiPush()							
							--UiTranslate(-progressBarWidth/2, 65)
							--UiTranslate(-progressBarWidth/2, 10)
							progressBar(progressBarWidth, 36, math.min(d / pGraceLimit, 1.0))
							UiTranslate(progressBarWidth + 10, 18)
							UiFont("bold.ttf", 36)			
							UiAlign("left middle")
							UiText(d)
						UiPop()						
					else
						
						local progressBarWidth = 240
						SetValue("progressBarFill", d / thresholds[5], "linear", 0.2)
						--progressbar							
						--UiTranslate(-progressBarWidth/2, 65)
						--UiTranslate(-progressBarWidth/2, 10)
						progressBar(progressBarWidth, 36, math.min(progressBarFill, 1.0), 1.0)
						--stars
						UiPush()											
							UiColor(1,1,0.5)							
							for i=1,stars do
								UiPush()	
									UiAlign("center middle")
									UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth - (progressBarWidth/10), 18)
									UiColor(0,0,0)
									UiImage("ui/common/star.png")
								UiPop()	
								if i < 5 then
									UiPush()
										--print("drawing one black line")
										UiAlign("center middle")
										UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth, 18)
										UiColor(0,0,0, 0.5)
										UiImage("../ui/hud/meterline.png")
									UiPop()	
								end
							end
							
							for i=1, 4 do		
								UiPush()
									UiAlign("center middle")
									UiTranslate((thresholds[i]/thresholds[5]) * progressBarWidth, 18)
									UiColor(1,1,1, 0.25)
									UiImage("../ui/hud/meterline.png")
								UiPop()							
							end
						UiPop()

						--Destroyed voxels
					--	UiTranslate(progressBarWidth/2, 56)
						UiTranslate(progressBarWidth + 10, 18)
						UiFont("bold.ttf", 36)			
						UiAlign("left middle")
						UiText(d)
					end
				UiPop()
			end			
		end
	end
end


function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("../ui/common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("../ui/common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end