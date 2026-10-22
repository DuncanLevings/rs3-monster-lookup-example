-- these slots belong to the example, Monster Lookup draws their structured content
local extensions = {}

extensions.TAB_ID = "example.monster_lookup.tab"

function extensions.register()
    local section, problem = MonsterLookup.register_extension({
        id = "example.monster_lookup.section",
        kind = "section",
        title = "Example consumer",
        order = 100,
        content = function(context)
            return {
                rows = {
                    { "Consumer", "Monster Lookup Example" },
                    { "Source", context.source or "Unknown" },
                    { "Variant", context.variant or "Default" },
                },
            }
        end,
    })
    assert(section, problem)

    local tab, tab_problem = MonsterLookup.register_extension({
        id = extensions.TAB_ID,
        kind = "tab",
        title = "Example",
        order = 100,
        content = function(context)
            local info = MonsterDataCore.info()
            return {
                rows = {
                    { "Monster", context.monster and context.monster.title or "None" },
                    { "Data built", info.built or "Unknown" },
                    { "Data schema", tostring(info.schema) },
                    { "Selection revision", tostring(context.revision) },
                },
                text = "This tab is registered by the example plugin. Disable the example to remove it.",
            }
        end,
    })
    if not tab then
        section.dispose()
        error(tab_problem)
    end

    local disposed = false

    return function()
        if not disposed then
            disposed = true

            tab.dispose()
            section.dispose()
        end
    end
end

return extensions
