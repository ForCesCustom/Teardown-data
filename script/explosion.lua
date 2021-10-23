function rnd(mi, ma)
	return math.random(1000)/1000*(ma-mi) + mi
end

function rndVec(t)
	return Vec(rnd(-t, t), rnd(-t, t), rnd(-t, t))
end

explosionPos = Vec()

trails = {}

function trailsAdd(pos, vel, life, size, damp, gravity)
	t = {}
	t.pos = VecCopy(pos)
	t.vel = VecAdd(Vec(0, vel*0.7, 0 ), rndVec(vel))
	t.size = size
	t.age = 0
	t.damp = damp
	t.gravity = gravity
	t.life = rnd(life*0.5, life*1.5)
	t.nextSpawn = 0
	trails[#trails+1] = t
end

function trailsUpdate(dt)
	for i=#trails,1,-1 do
		local t = trails[i]
		t.vel[2] = t.vel[2] + t.gravity*dt
		t.vel = VecScale(t.vel, t.damp)
		t.pos = VecAdd(t.pos, VecScale(t.vel, dt))
		t.age = t.age + dt
		local q = 1.0 - t.age / t.life
		if q > 0.1 then
			local r = t.size * q + 0.05
			local spawnRate = 0.8*r/VecLength(t.vel)
			while t.nextSpawn < t.age do
				local w = 0.8-q*0.5
				local w2 = 0.9
				local v = VecScale(t.vel, 0.25)
				ParticleReset()
				ParticleType("smoke")
				ParticleColor(w, w*0.95, w*0.9, w2, w2*0.95, w2*0.9)
				ParticleRadius(r)
				ParticleAlpha(q, 0)
				ParticleDrag(2.0)
				SpawnParticle(t.pos, v, rnd(0.5, 2.0))
				t.nextSpawn = t.nextSpawn + spawnRate
			end
		else
			trails[i] = trails[#trails]
			trails[#trails] = nil
		end
	end
end

smoke = {}
smoke.age = 0
smoke.size = 0
smoke.life = 0
smoke.next = 0
smoke.vel = 0
smoke.gravity = 0
smoke.amount = 0
function smokeUpdate(pos, dt)
	smoke.age = smoke.age + dt
	if smoke.age < smoke.life then
		local q = 1.0 - smoke.age / smoke.life
		for i=1, smoke.amount*q do
			local w = 0.8-q*0.6
			local w2 = 1.0
			local r = smoke.size*(0.5 + 0.5*q)
			local v = VecAdd(Vec(0, 1*q+q*smoke.vel, 0), rndVec(1*q))
			local p = VecAdd(pos, rndVec(r*0.3))
			ParticleReset()
			ParticleType("smoke")
			ParticleColor(w, w*0.95, w*0.9, w2, w2*0.95, w2*0.9)
			ParticleRadius(0.5*r, r)
			ParticleGravity(rnd(0,smoke.gravity))
			ParticleDrag(1.0)
			ParticleAlpha(q, q, "constant", 0, 0.5)
			SpawnParticle(p, v, rnd(3,5))
		end
	end
end


fire = {}
fire.age = 0
fire.life = 0
fire.size = 0
function fireUpdate(pos, dt)
	fire.age = fire.age + dt
	if fire.age < fire.life then
		local q = 1.0 - fire.age / fire.life
		for i=1, 16 do
			local v = rndVec(fire.size*10*q)
			local p = pos
			local life = rnd(0.2, 0.7)
			life = 0.5 + life*life*life * 1.5
			ParticleReset()
			ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
			ParticleAlpha(1, 0)
			ParticleRadius(fire.size*q, 0.5*fire.size*q)
			ParticleGravity(1, rnd(1, 10))
			ParticleDrag(0.6)
			ParticleEmissive(rnd(2, 5), 0, "easeout")
			ParticleTile(5)
			SpawnParticle(p, v, life)
		end
	end
end


flash = {}
flash.age = 0
flash.life = 0
flash.intensity = 0
function flashTick(pos, dt)
	flash.age = flash.age + dt
	if flash.age < flash.life then
		local q = 1.0 - flash.age / flash.life
		PointLight(pos, 1, 0.5, 0.2, flash.intensity*q) 
	end
end


light = {}
light.age = 0
light.life = 0
light.intensity = 0
function lightTick(pos, dt)
	light.age = light.age + dt
	if light.age < light.life then
		local q = 1.0 - light.age / light.life
		local l = q * q
		local p = VecAdd(pos, rndVec(0.5*l))
		PointLight(p, 1, 0.4, 0.1, light.intensity*l)
	end
end

function explosionSparks(count, vel)
	for i=1, count do
		local v = VecAdd(Vec(0, vel, 0 ), rndVec(rnd(vel*0.5, vel*1.5)))
		local life = rnd(0, 1)
		life = life*life * 5
		ParticleReset()
		ParticleEmissive(5, 0, "easeout")
		ParticleGravity(-10)
		ParticleRadius(0.03, 0.0, "easein")
		ParticleColor(1, 0.4, 0.3)
		ParticleTile(4)
		SpawnParticle(explosionPos, v, life)
	end
end

function explosionDebris(count, vel)
	for i=1, count do
		local r = rnd(0, 1)
		life = 0.5 + r*r*r*3
		r = (0.4 + 0.6*r*r*r)
		local v = VecAdd(Vec(0, r*vel*0.5, 0), VecScale(rndVec(1), r*vel))
		local radius = rnd(0.03, 0.05)
		local w = rnd(0.2, 0.5)
		ParticleReset()
		ParticleColor(w, w, w)
		ParticleAlpha(1)
		ParticleGravity(-10)
		ParticleRadius(radius, radius, "constant", 0, 0.2)
		ParticleSticky(0.2)
		ParticleStretch(0.0)
		ParticleTile(6)
		ParticleRotation(rnd(-20, 20), 0.0, "easeout")
		SpawnParticle(explosionPos, v, life)
	end
end

function explosionSmall(pos)
	explosionPos = pos
	explosionSparks(10, 2)
	explosionDebris(25, 6)

	trails = {}
	for i=1, 8 do
		trailsAdd(pos, 5, 0.4, 0.1, 0.99, -10)
	end

	flash.age = 0
	flash.life = 0.1
	flash.intensity = 200
	
	light.age = 0
	light.life = 0.8
	light.intensity = 15
	
	fire.age = 0
	fire.life = 0.5
	fire.size = 0.2
	
	smoke.age = 0
	smoke.life = 1
	smoke.size = 0.5
	smoke.vel = 1
	smoke.gravity = 3
	smoke.amount = 2
end


function explosionMedium(pos)
	explosionPos = pos
	explosionSparks(30, 3)
	explosionDebris(50, 7)

	trails = {}
	for i=1, 16 do
		trailsAdd(pos, 12, 0.4, 0.15, 0.97, -10)
	end

	flash.age = 0
	flash.life = 0.2
	flash.intensity = 500
	
	light.age = 0
	light.life = 1.0
	light.intensity = 30
	
	fire.age = 0
	fire.life = 0.6
	fire.size = 0.5

	smoke.age = 0
	smoke.life = 1.5
	smoke.size = 0.7
	smoke.vel = 1
	smoke.gravity = 2
	smoke.amount = 2
end


function explosionLarge(pos)
	explosionPos = pos
	explosionSparks(50, 5)
	explosionDebris(100, 10)

	trails = {}
	for i=1, 8 do
		trailsAdd(pos, 12, 0.5, 0.2, 0.97, -10)
	end

	flash.age = 0
	flash.life = 0.4
	flash.intensity = 1000
	
	light.age = 0
	light.life = 1.2
	light.intensity = 50
	
	fire.age = 0
	fire.life = 0.7
	fire.size = 0.8
	
	smoke.age = 0
	smoke.life = 3
	smoke.size = 1.0
	smoke.gravity = -1
	smoke.vel = 8
	smoke.amount = 6
	
	--Sideways fast cloud
	ParticleReset()
	ParticleColor(0.8, 0.75, 0.7)
	ParticleRadius(0.3, 1.0)
	ParticleAlpha(1, 0, "easeout")
	ParticleDrag(0.2)
	for a=0, math.pi*2, 0.05 do
		local x = math.cos(a)*1
		local y = rnd(-0.1, 0.1)
		local z = math.sin(a)*1
		local d = VecNormalize(Vec(x, y, z))
		SpawnParticle(VecAdd(pos, d), VecScale(d, rnd(8,12)), rnd(0.5, 1.5))
	end
end


function tick(dt)
	if HasKey("game.explosion") then
		local strength = GetFloat("game.explosion.strength")
		local pos = Vec(GetFloat("game.explosion.x"), GetFloat("game.explosion.y"), GetFloat("game.explosion.z"))
		if strength >= 2 then
			explosionLarge(pos)
		elseif strength >= 1 then
			explosionMedium(pos)
		else
			explosionSmall(pos)
		end
		ClearKey("game.explosion")
	end
	
	flashTick(explosionPos, dt)
	lightTick(explosionPos, dt)
end


function update(dt)
	trailsUpdate(dt)
	fireUpdate(explosionPos, dt)
	smokeUpdate(explosionPos, dt)
end


