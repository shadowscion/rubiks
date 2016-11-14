/*
---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER

local TYPE = { META = {} }
local META = TYPE.META

RUBIKS.TYPES["TEMPLATE"] = TYPE


----------------------------------------------------------------
function TYPE.GenerateData()
    local size   = math.Clamp(size or 2, 2, 6)
    local length = size*6

    local maxs = Vector(length, length, length)
    local mins = -maxs

    local hull = {
    }

    local data = {
        SIZE   = size,
        LENGTH = length,
        MAXS   = maxs,
        MINS   = mins,
        HULL   = hull,
        SEQ    = "FBRLDU" .. size,
    }

    if CLIENT then
        data.MASTER = {}

        data.CREATE = function()
            local puzzle = {}
            return puzzle
        end
    end

    return data
end


----------------------------------------------------------------
function META:BuildPhysics()
    if not self.RUBIKS_DATA then return end

    self:PhysicsInitConvex(self.RUBIKS_DATA.HULL)
    self:SetMoveType(MOVETYPE_CUSTOM)
    self:SetSolid(SOLID_VPHYSICS)
    self:EnableCustomCollisions(true)

    if CLIENT then
        self:SetRenderBounds(self.RUBIKS_DATA.MINS, self.RUBIKS_DATA.MAXS)
    end
end


----------------------------------------------------------------
if SERVER then
    function META:HandleInput(ply, trace)
        local send = {}

        net.Start("RUBIKS.MOVE")
            net.WriteEntity(self)
            net.WriteTable({ send })
        net.Broadcast()

        return send
    end
end


----------------------------------------------------------------
if SERVER then return end


----------------------------------------------------------------
function META:GetRotation()
    self.RUBIKS_TASK = table.remove(self.RUBIKS_QUEUE, 1)

    local MASTER = self.RUBIKS_DATA.MASTER
    local PUZZLE = self.RUBIKS_PUZZLE
    local TASK = self.RUBIKS_TASK

    if not MASTER[TASK.key] then self.RUBIKS_TASK = nil return end
end


----------------------------------------------------------------
function META:DoRotation()
    local PUZZLE = self.RUBIKS_PUZZLE
    local TASK = self.RUBIKS_TASK

    self.RUBIKS_TASK = nil
end


----------------------------------------------------------------
local nullify = not file.Exists("models/rubiks/cube_core.mdl", "GAME")

function META:DrawPuzzle(RENDER)
    if nullify then self:Debug() return end

    -- RENDER:SetModel("models/rubiks/cube_core.mdl")
    -- RENDER:SetModelScale(1, 0)

    -- for i, part in ipairs(self.RUBIKS_PUZZLE) do
    --     if not part then continue end
    --     for j = 1, 6 do
    --         RENDER:SetSubMaterial(j, part.sub[j] and ("rubiks/color_" .. part.sub[j]) or "rubiks/border")
    --     end

    --     RENDER:SetRenderOrigin(self:LocalToWorld(part.pos))
    --     RENDER:SetRenderAngles(self:LocalToWorldAngles(part.ang))
    --     RENDER:SetupBones()
    --     RENDER:DrawModel()
    -- end
end


----------------------------------------------------------------
function META:Debug()
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self.RUBIKS_DATA.MINS, self.RUBIKS_DATA.MAXS, Color(0, 255, 255), true)

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText(self, "TargetIDSmall", pos.x, pos.y, Color(255, 255, 255), 1)
    cam.End2D()
end
*/
