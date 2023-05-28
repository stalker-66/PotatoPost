-- @author: Narkoz
-- @desc: scene manager

local M = {}

M.show = function(sceneName)
	require(sceneName).show()
end

M.hide = function(sceneName)
	require(sceneName).hide()
end

return M