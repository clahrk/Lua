-- Pre-create materials and constants ONCE
local flat = materials.Create("flat", [[
    "UnlitGeneric" {
        "$basetexture"  "vgui/white_additive"
    }
]])

-- Configuration
local TICKS = 10
local ALPHA = 0.8
local NEWEST_COLOR = { 1, 0, 0 }    -- Red
local OLDEST_COLOR = { 0, 1, 0 }    -- Green

-- Pre-calculate all possible colors (optimization)
local COLOR_STEPS = {}
for i = 1, TICKS do
    local fade = i / TICKS
    COLOR_STEPS[i] = {
        NEWEST_COLOR[1] + (OLDEST_COLOR[1] - NEWEST_COLOR[1]) * fade,
        NEWEST_COLOR[2] + (OLDEST_COLOR[2] - NEWEST_COLOR[2]) * fade,
        NEWEST_COLOR[3] + (OLDEST_COLOR[3] - NEWEST_COLOR[3]) * fade
    }
end

-- Weak table for tracking
local drawn_entities = setmetatable({}, { __mode = "k" })

-- Optimized draw model handler
local function on_draw_model(ctx)
    if not ctx:IsDrawingBackTrack() then return end

    local entity = ctx:GetEntity()
    if not entity or not entity:IsPlayer() then return end

    local player_index = entity:GetIndex()
    local draw_count = (drawn_entities[player_index] or 0) + 1
    drawn_entities[player_index] = draw_count

    -- Clamp and get pre-calculated color
    local step = math.min(draw_count, TICKS)
    local color = COLOR_STEPS[step]

    -- Apply settings
    ctx:SetColorModulation(color[1], color[2], color[3])
    ctx:SetAlphaModulation(ALPHA)
    ctx:ForcedMaterialOverride(flat)
end

-- Efficient reset
local function on_draw()
    for k in pairs(drawn_entities) do
        drawn_entities[k] = nil
    end
end

-- Register callbacks
callbacks.Unregister("DrawModel", "backtrack_fade_chams")
callbacks.Register("DrawModel", "backtrack_fade_chams", on_draw_model)
callbacks.Unregister("Draw", "reset_backtrack_counter")
callbacks.Register("Draw", "reset_backtrack_counter", on_draw)