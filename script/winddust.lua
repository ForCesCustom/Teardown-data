gLargeParticles = 4
gSmallParticles = 2
gSmokeParticles = 24
gParticleColor = {0.3, 0.25, 0.2}
gSmokeColor = {0.7, 0.65, 0.6}


function rnd(mi, ma)
	return math.random(1000)/1000*(ma-mi) + mi
end


function rndVec(t)
	return Vec(rnd(-t, t), rnd(-t, t), rnd(-t, t))
end
 
 
function getParticlePos(rMin, rMax, life)
	local camPos = GetCameraTransform().pos
	local p = rndVec(1)
	p[2] = 0
	local d = rnd(rMin, rMax)
	p = VecScale(VecNormalize(p), d)
	p = VecAdd(p, camPos)
	p = VecSub(p, VecScale(GetWindVelocity(p), life * 0.5))
	p[2] = 20;
	local hit, dist = QueryRaycast(p, Vec(0,-1,0), 20)
	if not hit then dist = 20 end
	p[2] = math.max(p[2] - dist, 1)
	p[2] = p[2] + rnd(0, 2)
	return p, d
end


function update(dt)
	ParticleReset()
	ParticleType("plain")
	ParticleRadius(0.8)
	ParticleColor(gParticleColor[1], gParticleColor[2], gParticleColor[3])
	ParticleAlpha(1, 1, "constant", 0.5, 0.5)
	ParticleCollide(0)
	ParticleTile(8)
	for i = 1, gLargeParticles do
		local life = 1.0
		local p, d = getParticlePos(8, 12, life);
		local vel = GetWindVelocity(p);
		SpawnParticle(p, vel, life)
	end
	
	ParticleReset()
	ParticleType("plain")
	ParticleRadius(0.02)
	ParticleGravity(-5)
	ParticleColor(gParticleColor[1], gParticleColor[2], gParticleColor[3])
	ParticleAlpha(1, 1, "constant", 0.5, 0.5)
	ParticleCollide(1)
	ParticleTile(4)
	for i = 1, gSmallParticles do
		local life = 1.0
		local p, d = getParticlePos(6, 10, life);
		local vel = GetWindVelocity(p);
		SpawnParticle(p, vel, life)
	end

	ParticleReset()
	ParticleType("plain")
	ParticleGravity(-5)
	ParticleColor(gSmokeColor[1], gSmokeColor[2], gSmokeColor[3])
	ParticleAlpha(0.1, 0.1, "constant", 0.5, 0.5)
	ParticleCollide(1)
	ParticleTile(0)
	for i = 1, gSmokeParticles do
		local life = 1.0
		local p, d = getParticlePos(8, 32, life);
		local vel = GetWindVelocity(p);
		ParticleRadius(d/10)
		SpawnParticle(p, vel, life)
	end
end

