-- a separate plugin: only the client dependency exports cross the package boundary
local example = require("src/example")

function PluginShutdown()
    example.stop()
end

example.start()
