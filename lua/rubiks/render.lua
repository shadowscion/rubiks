---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS

RUBIKS.RENDER = RUBIKS.RENDER or nil

timer.Create("RUBIKS.Redraw", 1, 0, function()
    if IsValid(RUBIKS.RENDER) then
        return
    end

    RUBIKS.RENDER = ClientsideModel("models/hunter/blocks/cube025x025x025.mdl")
    RUBIKS.RENDER:SetNoDraw(true)
    RUBIKS.RENDER:Spawn()
end)


----------------------------------------------------------------
-- CreateClientConVar("rubiks_draw_hud", "1", true, false)
CreateClientConVar("rubiks_animation_speed", "2", true, false)


----------------------------------------------------------------
RUBIKS.ANIM_SPEED_MIN = 1/10
RUBIKS.ANIM_SPEED_MAX = 5

local anim = GetConVar("rubiks_animation_speed")

RUBIKS.ANIM_SPEED = math.Clamp(anim:GetFloat(), RUBIKS.ANIM_SPEED_MIN, RUBIKS.ANIM_SPEED_MAX)

cvars.AddChangeCallback("rubiks_animation_speed", function(_, old, new)
    RUBIKS.ANIM_SPEED = math.Clamp(tonumber(new), RUBIKS.ANIM_SPEED_MIN, RUBIKS.ANIM_SPEED_MAX)
end)
