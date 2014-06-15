
<!-- saved from url=(0119)https://raw.githubusercontent.com/Sophylax/ensage-wip/f973a599e8a3e152a0d7490a381591327f11174f/Libraries/TargetFind.lua -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><style type="text/css"></style></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">--[[
		Save as TargetFind.lua into Ensage\Scripts\libs.

		Functions:
			targetFind:GetLastMouseOver(range): Returns the latest mouse-overed hero if it is in range, if not it will return closest hero to the mouse position.
			targetFind:GetClosestToMouse(range): Returns closest hero to the mouse position that is in range.
			targetFind:GetLowestEHP(range,type): Returns the hero by looking at their hp and resistances.
				Type: Damage type. Possible inputs : "magic", "phys" and nothing
					NoType: Compares purely by current HP
					"phys": Comparation includes armor calculation and ignores ethereal heroes.
					"magic": Comparation includes magic resistance calculation and ignores magic immune heroes.
				Tresh: EHP Threshold. If entered function will only return a hero if it's EHP is lower than given amount
				
		Examples:
			targetFind:GetLastMouseOver(1000)
			targetFind:GetClosestToMouse(500)
			targetFind:GetLowestEHP(600,"phys")
			targetFind:GetLowestEHP(850,"magic")
			targetFind:GetLowestEHP(99999,"magic",300)
			targetFind:GetLowestEHP(1300)
--]]

targetFind = {}
targetFind.handles = {}
targetFind.mTarget = nil

function targetFind:TargetTick(tick)
	local heroes = entityList:FindEntities({type = TYPE_HERO})
	for i,v in ipairs(heroes) do
		if not targetFind.handles[v.handle] then
			targetFind.handles[v.handle] = true
		end
	end
	local mOver = entityList:GetMouseOver()
	if mOver and mOver.visible and mOver.alive and mOver.team == TEAM_ENEMY and not mOver.illusion and targetFind.handles[mOver.handle] then
		targetFind.mTarget = mOver
	end
end

function targetFind:GetLastMouseOver(range)
	if not targetFind.mTarget or GetDistance2D(me,targetFind.mTarget) &gt; range or not targetFind.mTarget.alive or not targetFind.mTarget.visible then
		targetFind.mTarget = nil
	end
	if targetFind.mTarget then
		return targetFind.mTarget
	else
		local _enemies = entityList:FindEntities({type=TYPE_HERO, team = TEAM_ENEMY, distance = {me,range}})
		local real = {}
		for i,v in ipairs(_enemies) do
			if not v.illusion and v.visible and v.alive then
				table.insert(real,v)
			end
		end
		if #real == 1 then
			return real[1]
		else
			return targetFind:GetClosestToMouse(range)
		end
	end
end

function targetFind:GetClosestToMouse(range)
	local lowenemy = nil
	local enemies = entityList:FindEntities({type=TYPE_HERO, team = TEAM_ENEMY, distance = {me,range}})
	for i,v in ipairs(enemies) do
		local distance = GetDistance2D(v,engineClient.mousePosition)
		local distance2 = GetDistance2D(me,v)
		if  v.alive and v.visible and not v.illusion and distance2 &lt;= range then 
			if lowenemy == nil then
				lowenemy = v
			elseif GetDistance2D(v,engineClient.mousePosition) &lt; GetDistance2D(lowenemy,engineClient.mousePosition) then
				lowenemy = v
			end
		end
	end
	return lowenemy
end

function targetFind:GetLowestEHP(range,dmg_type,tresh)
	local lowenemy = nil
	local enemies = entityList:FindEntities({type=TYPE_HERO, team = TEAM_ENEMY, distance = {me,range}})
	for i,v in ipairs(enemies) do
		local immunity
		if dmg_type == "magic" then
			if lowenemy then l_multipler = 1/(1-lowenemy.magicDmgResist) end
			v_multipler = 1/(1-v.magicDmgResist)
			immunity = v.magicImmune
		elseif dmg_type == "phys" then
			if lowenemy then l_multipler = 1/(1-lowenemy.dmgResist)  end
			v_multipler = 1/(1-v.dmgResist) 
			immunity = v.ghost
		else
			l_multipler = 1
			v_multipler = 1
			immunity = false
		end
		local distance = GetDistance2D(me,v)
		if distance &lt;= range and v.alive and not v.illusion and v.visible and not immunity and (not tresh or (v.health*v_multipler) &lt; tresh) then 
			if lowenemy == nil then
				lowenemy = v
			elseif (lowenemy.health*l_multipler) &gt; (v.health*v_multipler) then
				lowenemy = v
			end
		end
	end
	return lowenemy
end

function GetDistance2D(a,b)
	return math.sqrt(math.pow(a.x-b.x,2)+math.pow(a.y-b.y,2))
end

script:RegisterEvent(EVENT_TICK,targetFind.TargetTick)</pre></body></html>
