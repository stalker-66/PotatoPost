-- @author: Narkoz
-- @desc: tutorial scene

local sceneManager = require("sceneManager")

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

M.animTo = function()
	transition.cancel( M.ui.animHand )

	M.ui.animHand = transition.to( M.ui.hand, {
		time = 1000, 
		x = screen.centerX + 180,
		onComplete = M.animFrom
	})
end

M.animFrom = function()
	transition.cancel( M.ui.animHand )

	M.ui.animHand = transition.to( M.ui.hand, {
		time = 1000, 
		x = screen.centerX + 70,
		onComplete = M.animTo
	})
end

M.show = function()
	if (isShow) then
		return true
	end
	isShow = true

	M.ui = {}
	M.groups = {}
	M.groups.ui = display.newGroup()

	M.ui.background = display.newRect( M.groups.ui, screen.centerX, screen.centerY, screen.width, screen.height )
	M.ui.background:setFillColor( 0, 0, 0, 0.8 )

	M.ui.background:addEventListener( "tap", function() return true end )
	M.ui.background:addEventListener( "touch", function() return true end )

	M.ui.hand = display.newImage( M.groups.ui, "hand.png", screen.centerX + 70, screen.centerY, true )
	M.animTo()

	M.ui.karma = display.newText( M.groups.ui, "Rules:\n\n1. Press\n2. Move\n3. Release\n\n and match the color...", screen.centerX, screen.centerY, native.systemFont, 65 )

	M.ui.ok = display.newImage( M.groups.ui, "ok.png", screen.centerX, screen.centerY + 600, true )
	M.ui.ok:addEventListener( 'touch', function(e)
		if e.target.isLock then
			return true
		end
		if e.phase=='began' then
			e.target.alpha = .5
			e.target.isFocus = true
			display.getCurrentStage():setFocus(e.target)
		end
		if e.phase=='moved' and e.target.isFocus==true then
			if math.abs(e.y-e.yStart)>100 or math.abs(e.x-e.xStart)>100 then
				e.target.alpha = 1
				e.target.isFocus = false
				display.getCurrentStage():setFocus(nil)
			end
		end
		if (e.phase=='ended' or e.phase=='cancelled') and e.target.isFocus==true then
			e.target.alpha = 1
			e.target.isLock = true
			e.target.isFocus = false
			display.getCurrentStage():setFocus(nil)

			sceneManager.hide("Tutor")
		end
		return true
	end)
end

M.hide = function()
	if (not isShow) then
		return true
	end
	isShow = false

	display.currentStage:setFocus(nil)

	transition.cancel( M.ui.animHand )

	for k,v in pairs(M.groups) do
		display.remove(M.groups[k])
		M.groups[k] = nil
	end

	M.ui = nil
	M.groups = nil
end

return M