-- @author: Narkoz
-- @desc: application entry point

math.randomseed(os.time())
system.setIdleTimer(false)

local sceneManager = require("sceneManager")
sceneManager.show("Game")
sceneManager.show("Tutor")