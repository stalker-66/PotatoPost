-- @author: Narkoz
-- @desc: main game scene

local physics = require( "physics" )

local M = {}

local isShow = false

local screen = { 
	width = display.contentWidth,
	height = display.contentHeight,
	centerX = display.contentWidth * 0.5,
	centerY = display.contentHeight * 0.5,
	safeX = display.safeScreenOriginX,
	safeY = display.safeScreenOriginY,
}

local backgroundMusic = audio.loadStream( "music.mp3" )
local winMusic = audio.loadStream( "win.mp3" )
local loseMusic = audio.loadStream( "lose.mp3" )

local rules = { 
	curMail = 0,
	nextMail = 0,
	karma = 0
}

local variants = {
	{ color = { 86/255, 130/255, 193/255 } },
	{ color = { 186/255, 69/255, 69/255 } },
	{ color = { 219/255, 198/255, 159/255 } },
	{ color = { 150/255, 137/255, 202/255 } }
}

local refreshRules = function()
	rules.curMail = rules.nextMail > 0 and rules.nextMail or math.random(1, #variants)
	M.ui.curMail:setFillColor( unpack( variants[rules.curMail].color ) )

	repeat
		rules.nextMail = math.random(1, #variants)
	until( rules.nextMail ~= rules.curMail )

	M.ui.nextMail:setFillColor( unpack( variants[rules.nextMail].color ) )

	M.ui.karma.text = "Karma: " .. rules.karma

	if rules.karma < 0 then
		M.ui.karma:setFillColor( 199/255, 56/255, 56/255 )
	elseif rules.karma > 0 then
		M.ui.karma:setFillColor( 120/255, 175/255, 42/255 )
	else
		M.ui.karma:setFillColor( 0.5 )
	end
end

local hasCollidedRect = function( obj1, obj2 )
    if (obj1 == nil) then
        return false
    end
    if (obj2 == nil) then
        return false
    end

    local left = obj1.contentBounds.xMin <= obj2.contentBounds.xMin and obj1.contentBounds.xMax >= obj2.contentBounds.xMin
    local right = obj1.contentBounds.xMin >= obj2.contentBounds.xMin and obj1.contentBounds.xMin <= obj2.contentBounds.xMax
    local up = obj1.contentBounds.yMin <= obj2.contentBounds.yMin and obj1.contentBounds.yMax >= obj2.contentBounds.yMin
    local down = obj1.contentBounds.yMin >= obj2.contentBounds.yMin and obj1.contentBounds.yMin <= obj2.contentBounds.yMax

    return ( left or right ) and ( up or down )
end

local launchProjectile = function(e)
    display.remove(M.ui.airMail)
    M.ui.airMail = display.newImage( M.groups.ui, "mail1.png", M.ui.curMail.x, M.ui.curMail.y, true )
    M.ui.airMail:setFillColor( unpack( variants[rules.curMail].color ) )

    physics.addBody( M.ui.airMail, { bounce = 0.2, density = 1.0, radius = 24 } )

    local vx = e.x - e.xStart
    local vy = e.y - e.yStart
    M.ui.airMail:setLinearVelocity( vx, vy )

end

local getTrajectoryPoint = function( startingPosition, startingVelocity, n )
    local t = 1 / display.fps

    local stepVelocity = { 
    	x = t * startingVelocity.x, 
    	y = t * startingVelocity.y
    }

    local gx, gy = physics.getGravity()
    local stepGravity = { 
    	x = t * gx,
    	y = t * gy
    }

    local coef = 0.25
    return {
        x = startingPosition.x + n * stepVelocity.x + coef * (n*n+n) * stepGravity.x,
        y = startingPosition.y + n * stepVelocity.y + coef * (n*n+n) * stepGravity.y
    }
end


local reloadGroupPath = function()
	display.remove(M.groups.path)
	M.groups.path = display.newGroup()
end

local touchListener = function(e)
	if M.ui.airMail then
		return true
	end
	if (e.phase == "moved") then
        reloadGroupPath()

        local startingVelocity = {
        	x = e.x - e.xStart,
        	y = e.y - e.yStart
        }

        for i = 1, 240, 2 do
            local s = { 
            	x = M.ui.curMail.x,
            	y = M.ui.curMail.y
            }
            local trajectoryPosition = getTrajectoryPoint( s, startingVelocity, i )
            local dot = display.newCircle( M.groups.path, trajectoryPosition.x, trajectoryPosition.y, 4 )
            dot:setFillColor(0)
        end

    elseif (e.phase == "ended") then
    	reloadGroupPath()
        launchProjectile( e )
    end
    return true
end

local update = function()
	if M.ui.airMail then
		local potato = 0
		if hasCollidedRect(M.ui.airMail, M.ui.potato1) then
			potato = 1
		end
		if hasCollidedRect(M.ui.airMail, M.ui.potato2) then
			potato = 2
		end
		if hasCollidedRect(M.ui.airMail, M.ui.potato3) then
			potato = 3
		end
		if hasCollidedRect(M.ui.airMail, M.ui.potato4) then
			potato = 4
		end
		if hasCollidedRect(M.ui.airMail, M.ui.floor1)
			or hasCollidedRect(M.ui.airMail, M.ui.floor2)
			or hasCollidedRect(M.ui.airMail, M.ui.floor3)
			or hasCollidedRect(M.ui.airMail, M.ui.floor4) then

			potato = -1
		end

		if potato ~= 0 then
			display.remove(M.ui.airMail)
			M.ui.airMail = nil

			if rules.curMail == potato then
				audio.play( winMusic )
				rules.karma = rules.karma + 1
			else
				audio.play( loseMusic )
				rules.karma = rules.karma - 2
			end

			refreshRules()
		end
	end
end

M.show = function()
	if (isShow) then
		return true
	end
	isShow = true

	M.ui = {}
	M.groups = {}
	M.groups.ui = display.newGroup()

	physics.start()
	physics.setGravity( 0, 50 )

	M.ui.background = display.newImage( M.groups.ui, "background.png", screen.centerX, screen.centerY, true )

	M.ui.curMail = display.newImage( M.groups.ui, "mail1.png", screen.centerX + 105, screen.centerY + 20, true )
	M.ui.nextMail = display.newImage( M.groups.ui, "mail2.png", screen.centerX + 345, screen.centerY + 80, true )

	M.ui.potato1 = display.newRect( M.groups.ui, screen.centerX - 315, screen.centerY + 900, 175, 200 )
	M.ui.potato1:setFillColor( unpack( variants[1].color ) )
	M.ui.potato1.alpha = 0.9
	M.ui.potato1.isVisible = false

	M.ui.potato2 = display.newRect( M.groups.ui, screen.centerX - 70, screen.centerY + 900, 135, 200 )
	M.ui.potato2:setFillColor( unpack( variants[2].color ) )
	M.ui.potato2.alpha = 0.9
	M.ui.potato2.isVisible = false

	M.ui.potato3 = display.newRect( M.groups.ui, screen.centerX + 135, screen.centerY + 900, 135, 200 )
	M.ui.potato3:setFillColor( unpack( variants[3].color ) )
	M.ui.potato3.alpha = 0.9
	M.ui.potato3.isVisible = false

	M.ui.potato4 = display.newRect( M.groups.ui, screen.centerX + 410, screen.centerY + 900, 165, 200 )
	M.ui.potato4:setFillColor( unpack( variants[4].color ) )
	M.ui.potato4.alpha = 0.9
	M.ui.potato4.isVisible = false

	M.ui.floor1 = display.newRect( M.groups.ui, screen.centerX - 540, screen.centerY, 30, screen.height )
	M.ui.floor1:setFillColor( 0, 1, 0 )
	M.ui.floor1.alpha = 0.9
	M.ui.floor1.isVisible = false

	M.ui.floor2 = display.newRect( M.groups.ui, screen.centerX, screen.centerY - 960, screen.width, 30 )
	M.ui.floor2:setFillColor( 0, 1, 0 )
	M.ui.floor2.alpha = 0.9
	M.ui.floor2.isVisible = false

	M.ui.floor3 = display.newRect( M.groups.ui, screen.centerX + 540, screen.centerY, 30, screen.height )
	M.ui.floor3:setFillColor( 0, 1, 0 )
	M.ui.floor3.alpha = 0.9
	M.ui.floor3.isVisible = false

	M.ui.floor4 = display.newRect( M.groups.ui, screen.centerX, screen.centerY + 960, screen.width, 30 )
	M.ui.floor4:setFillColor( 0, 1, 0 )
	M.ui.floor4.alpha = 0.9
	M.ui.floor4.isVisible = false

	M.ui.title = display.newImage( M.groups.ui, "title.png", screen.centerX - 135, screen.centerY - 850, true )

	M.ui.scoreBackGround = display.newImage( M.groups.ui, "karma.png", screen.centerX, screen.centerY - 650, true )
	M.ui.karma = display.newText( M.groups.ui, "Karma: 0", M.ui.scoreBackGround.x, M.ui.scoreBackGround.y, native.systemFont, 70 )

	refreshRules()

	Runtime:addEventListener( "touch", touchListener )
	Runtime:addEventListener( "enterFrame", update )

	local backgroundMusicChannel = audio.play( backgroundMusic, { channel = 1, loops = -1 } )
end

M.hide = function()
	if (not isShow) then
		return true
	end
	isShow = false

	display.currentStage:setFocus(nil)

	physics.stop()
	audio.stop()

	Runtime:removeEventListener( "touch", touchListener )
	Runtime:removeEventListener( "enterFrame", update )

	for k,v in pairs(M.groups) do
		display.remove(M.groups[k])
		M.groups[k] = nil
	end

	M.ui = nil
	M.groups = nil
end

return M