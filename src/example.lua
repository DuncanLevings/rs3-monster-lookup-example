-- the example owns a lookup handle; opening the standard window never replaces this handle
local view = require("src/view")
local extensions = require("src/extensions")

local example = {}

local SUBSCRIPTION = "monster_lookup_example"

local state = {
    revision = 0,
    panels = {},
}

local function copy_options(options)
    local copy = {}

    for key, value in pairs(options or {}) do
        copy[key] = value
    end

    return copy
end

local function cancel()
    state.revision = state.revision + 1

    if state.lookup then
        state.lookup.cancel()
    end
end

local function destroy_window()
    cancel()
    if state.view then
        state.view.destroy()
        state.view = nil
    end

    state.record = nil
end

local function destroy_panels()
    for _, panel in pairs(state.panels) do
        panel:Destroy()
    end

    state.panels = {}
end

local function select_monster(selection)
    if not state.started or not state.view then
        return
    end

    cancel()
    state.selection = {
        name = selection.name,
        wiki_title = selection.wiki_title,
        npc_id = selection.npc_id,
    }

    local focus = copy_options(selection.focus)
    state.focus = focus
    state.record = nil

    local revision = state.revision

    state.view.loading(state.selection)

    state.lookup.fetch(state.selection, function(record, problem, metadata)
        -- a late callback cannot touch a closed window or replace a newer selection
        if state.started and state.view and state.revision == revision then
            state.record = record
            state.view.result(record, problem, metadata, focus)
        end
    end)
end

local function open_standard(show_extension_tab)
    if not state.record then
        return
    end

    local options = copy_options(state.focus)
    if show_extension_tab then
        options.tab = extensions.TAB_ID
    end

    if not MonsterLookup.open(state.selection, options) then
        log("Monster Lookup is not ready to open a window yet.")
    end
end

function example.open()
    if not state.started then
        return false
    end

    if not state.view then
        local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
        if not parent or parent.width <= 0 or parent.height <= 0 then
            log("Open the example after entering the game.")
            return false
        end

        state.view = view.new(parent, {
            on_select = select_monster,
            on_open = open_standard,
            on_close = cancel,
        })
    end

    state.view.show()
    if not state.record then
        select_monster(state.selection or { name = "Goblin", wiki_title = "Goblin" })
    end

    return true
end

local function panel_ready(key, event)
    if state.panels[key] then
        state.panels[key]:Destroy()
    end

    local panel = prettyui.SimpleView.new(event.component, {
        width = 0,
        height = 0,
        widthAnchor = 1,
        heightAnchor = 1,
    })
    state.panels[key] = panel

    panel:AddText("Developer example: custom layout, searches and extensions.")
    panel:AddSimpleButton("Open example", example.open)
end

function example.start()
    if state.started then
        return
    end

    assert(MonsterLookup.version().api.major == 1, "Example requires Monster Lookup API 1")
    assert(MonsterDataCore.info().schema == 1, "Example requires Monster Data Core schema 1")

    state.dispose_extensions = extensions.register()
    state.lookup = MonsterLookup.lookup()
    state.started = true

    Event.ContentLayerReady.Subscribe(SUBSCRIPTION, function(event)
        panel_ready("content", event)
    end)
    Event.SettingsLayerReady.Subscribe(SUBSCRIPTION, function(event)
        panel_ready("settings", event)
    end)
    Event.GameStateChanged.Subscribe(SUBSCRIPTION, function(event)
        if event.newState == GameState.LOBBY or event.newState == GameState.LOGINSCREEN then
            destroy_window()
            destroy_panels()
        end
    end)
    log("Open Monster Lookup Example from the Plugins ribbon or Plugin Hub settings.")
end

function example.stop()
    if not state.started then
        return
    end

    state.started = false

    Event.ContentLayerReady.Unsubscribe(SUBSCRIPTION)
    Event.SettingsLayerReady.Unsubscribe(SUBSCRIPTION)
    Event.GameStateChanged.Unsubscribe(SUBSCRIPTION)

    destroy_window()

    state.lookup.destroy()
    state.lookup = nil

    destroy_panels()

    state.dispose_extensions()
    state.dispose_extensions = nil
end

return example
