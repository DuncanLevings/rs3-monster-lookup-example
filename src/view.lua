-- the caller owns this layout, pages and component lifetimes; no private Lookup modules
local view = {}

local TAB = {
    PREVIEW = 1,
    MONSTERS = 2,
    ITEMS = 3,
    STATS = 4,
    COMBINED = 5,
    DROPS = 6,
    LOCATIONS = 7,
}

local PADDING = 8
local COLUMN_GAP = 12
local OVERVIEW_Y = 90
local MIN_MODEL_HEIGHT = 220

local TEXT = 0xE7D7B0FF
local MUTED = 0xB9AD98FF

local RESIZE = "monster_lookup_example_preview_resize"

local function label(parent, y, text, height)
    local component = prettyui.Text.new(parent, {
        x = PADDING,
        y = y,
        width = -2 * PADDING,
        widthAnchor = 1,
        height = height,
        maxLines = 0,
        text = text,
        font = id.Font.MUSEO_SANS_11PT_REGULAR,
        colour = MUTED,
    })

    component.clickthrough = true
    component.enabled = false

    return component
end

function view.new(parent, callbacks)
    local constructors = MonsterLookup.components()
    local state = {
        tab = TAB.PREVIEW,
        open = false,
        variant = 1,
        variants = {},
        searches = {},
    }
    local controller = {}
    local layout, update_active_components, show_selected_variant

    local window = prettyui.Window.new(parent, {
        title = "Monster Lookup Example",
        x = 80,
        y = 80,
        width = 940,
        height = 600,
        minWidth = 800,
        minHeight = 420,
        resizable = true,
        scrollable = false,
        destroyOnClose = false,
        onClose = function()
            state.open = false
            if update_active_components then
                update_active_components()
            end

            callbacks.on_close()
        end,
    })
    local tabs = window:AddTabs({
        { text = "Preview" },
        { text = "Monsters" },
        { text = "Items" },
        { text = "Stats" },
        { text = "Combined" },
        { text = "Drops" },
        { text = "Locations" },
    }, {
        height = 420,
        scrollStep = 32,
        onChange = function(_, index)
            state.tab = index
            if state.ready then
                update_active_components()
            end
        end,
    })
    tabs.root:SetSize(-tabs.root.x * 2, -tabs.root.y - PADDING, 1, 1)

    local page = tabs:GetPage(TAB.PREVIEW)
    local status = label(page.content, 42, "Select a monster from any search tab.", 40)
    local variant_text = label(page.content, 320, "", 24)
    local overview = ui.Layer.new(page.content)
    overview:SetPos(PADDING, OVERVIEW_Y)
    overview:SetSize(-2 * PADDING, MIN_MODEL_HEIGHT, 1, 0)
    overview.clickthrough = true

    -- choose the rows here; the library does not own this layout
    local stats = constructors.stats(overview, {
        overlay_parent = parent,
        page = page,
        fields = { "Weakness", "Aggressive", "Susceptible to" },
    })
    local immunities = constructors.stats(overview, {
        overlay_parent = parent,
        page = page,
        fields = { "Poison", "Stun", "Deflect", "Stat drain" },
    })
    local model = constructors.model(overview, {
        width = 240,
        height = MIN_MODEL_HEIGHT,
        overlay_parent = parent,
        zoom_min = 1,
        zoom_max = 1.5,
        turn = false,
    })
    local slayer = constructors.slayer(page.content, {
        overlay_parent = parent,
        page = page,
        expanded = false,
        on_toggle = function()
            layout()
        end,
    })
    local details = constructors.detailed_stats(page.content, {
        overlay_parent = parent,
        page = page,
        expanded = false,
        on_toggle = function()
            layout()
        end,
    })
    -- opening the standard window is separate from selecting a search result
    local open_button = prettyui.SimpleButton.new(page.content, "Open Monster Lookup", function()
        callbacks.on_open(false)
    end, { x = PADDING, y = PADDING, width = 190, height = 26, colour = TEXT, disabled = true })
    local extension_button = prettyui.SimpleButton.new(page.content, "Open example tab", function()
        callbacks.on_open(true)
    end, { x = 210, y = PADDING, width = 170, height = 26, colour = TEXT, disabled = true })
    local variant_button = prettyui.SimpleButton.new(page.content, "Next variant", function()
        if state.record then
            state.variant = state.variant % #state.variants + 1
            show_selected_variant()
        end
    end, { x = 392, y = PADDING, width = 130, height = 26, colour = TEXT, disabled = true })
    local drops = constructors.drops(
        tabs:GetPage(TAB.DROPS),
        { overlay_parent = parent, live_prices = false }
    )
    local locations = constructors.locations(tabs:GetPage(TAB.LOCATIONS))

    -- each search owns its query and runs only while its tab is visible
    for _, entry in ipairs({
        { TAB.MONSTERS, constructors.search_monsters },
        { TAB.ITEMS, constructors.search_items },
        { TAB.STATS, constructors.search_stats },
        { TAB.COMBINED, constructors.search },
    }) do
        state.searches[entry[1]] = entry[2](tabs:GetPage(entry[1]), {
            on_select = callbacks.on_select,
        })
    end

    layout = function()
        if state.destroyed or state.laying_out then
            return
        end

        state.laying_out = true

        local width = math.max(200, page.content.width - 2 * PADDING)
        state.width = page.content.width

        -- leave two thirds for data and one third for the preview
        local summary_width = math.floor((width - COLUMN_GAP) * 2 / 3)
        local summary_height = stats.layout(summary_width, 0)
        local immunity_height = immunities.layout(summary_width, summary_height + PADDING)
        local height = math.max(MIN_MODEL_HEIGHT, summary_height + PADDING + immunity_height)
        overview:SetSize(-2 * PADDING, height, 1, 0)
        model.resize(width - summary_width - COLUMN_GAP, height)
        model.set_position(summary_width + COLUMN_GAP, 0)

        local y = OVERVIEW_Y + height + PADDING
        variant_text:SetPos(PADDING, y)
        y = y + 32
        y = y + slayer.layout(width, y) + PADDING
        y = y + details.layout(width, y) + PADDING
        page:SetContentHeight(y)

        state.laying_out = false
    end

    update_active_components = function()
        if state.destroyed then
            return
        end

        for index, search in pairs(state.searches) do
            search.set_active(state.open and state.tab == index)
        end

        stats.hide_tooltips()
        immunities.hide_tooltips()
        slayer.hide_tooltips()
        details.hide_tooltips()
        drops.hide_tooltips()
        model.hide_tooltip()
        model.set_active(state.open and state.tab == TAB.PREVIEW and state.record ~= nil)
        if state.open and state.tab == TAB.PREVIEW then
            layout()
        end
    end

    show_selected_variant = function()
        local variant = state.variants[state.variant]
        local info = variant and variant.info or {}
        local title = state.record and state.record.title

        stats.set_info(info, title)
        immunities.set_info(info, title)
        slayer.set_info(info, title)
        details.set_info(info, title)
        variant_text.content = variant and ("Variant: " .. variant.name) or ""
        model.set_monster(
            state.record and { title = title, info = info, selection = state.selection }
        )

        variant_button:SetDisabled(#state.variants < 2)

        update_active_components()
        layout()
    end

    function controller.loading(selection)
        if state.destroyed then
            return
        end

        state.selection = selection
        state.record = nil
        state.variants = {}
        state.variant = 1
        status.content = "Loading " .. selection.name .. "..."
        open_button:SetDisabled(true)
        extension_button:SetDisabled(true)
        drops.set_monster(nil)
        locations.set_monster(nil)
        show_selected_variant()
        tabs:SetActive(TAB.PREVIEW)
    end

    function controller.result(record, problem, metadata, focus)
        if state.destroyed then
            return
        end

        local updating = state.record and record and state.record.title == record.title

        state.record = record
        state.variants = record and MonsterDataCore.variants(record) or {}
        state.variant = math.min(state.variant, math.max(1, #state.variants))

        if record then
            local source = metadata and metadata.bundled and "local data" or "saved/Wiki data"
            status.content = record.title
                .. " - "
                .. source
                .. (problem and (". " .. problem) or "")

            if updating then
                drops.update(record)
            else
                drops.set_monster(record, focus)
            end
        else
            status.content = problem or "No record available."
            drops.set_monster(nil)
        end

        open_button:SetDisabled(record == nil)
        extension_button:SetDisabled(record == nil)
        locations.set_monster(record)
        show_selected_variant()
    end

    function controller.show()
        if state.destroyed then
            return
        end

        state.open = true
        window:Show()
        update_active_components()
    end

    function controller.destroy()
        if state.destroyed then
            return
        end

        state.destroyed = true

        -- the resize hook belongs to this page and dies when the window is destroyed
        -- children release callbacks and native models before their pages disappear
        for _, search in pairs(state.searches) do
            search.destroy()
        end

        for _, component in ipairs({ stats, immunities, model, slayer, details, drops, locations }) do
            component.destroy()
        end

        open_button:Destroy()
        extension_button:Destroy()
        variant_button:Destroy()
        status:Destroy()
        variant_text:Destroy()
        overview:Destroy()
        window:Destroy()
    end

    page.content:Subscribe(ui.Hook.ONRESIZE, RESIZE, function()
        if state.ready and state.open and page.content.width ~= state.width then
            layout()
        end
    end)
    state.ready = true

    drops.set_monster(nil)
    update_active_components()

    return controller
end

return view
