local vide = require(script.Parent.vide)
local app = require(script.app)

vide.root(function() app(plugin) end)
