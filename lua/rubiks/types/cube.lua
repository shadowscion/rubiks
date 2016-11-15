---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER

local TYPE = { META = {} }
local META = TYPE.META

RUBIKS.TYPES["CUBE"] = TYPE


----------------------------------------------------------------
function TYPE.GenerateData(size)
    local size   = math.Clamp(size or 2, 2, 6)
    local length = size*6

    local maxs = Vector(length, length, length)
    local mins = -maxs

    local hull = {
        Vector(-length, -length, -length),
        Vector(-length, -length, length),
        Vector(-length, length, -length),
        Vector(-length, length, length),
        Vector(length, -length, -length),
        Vector(length, -length, length),
        Vector(length, length, -length),
        Vector(length, length, length)
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
        if TYPE.GenerateClientData then
            TYPE.GenerateClientData(data)
        else
            data.MASTER = {}

            data.CREATE = function()
                local puzzle = {}
                return puzzle
            end
        end
    end

    return data
end


----------------------------------------------------------------
if SERVER then
    function META:HandleInput(ply, trace)
        local pos, dir = self:CubeTrace(trace)
        if not pos or not dir then return end

        local send = {}
        if ply:KeyDown(IN_SPEED) then
            local row, col, rneg, cneg = self:CubeTraceLayers(pos, dir)
            if not row or not col or not rneg or not cneg then return end

            if ply:KeyDown(IN_ATTACK) then
                send.key = row
                send.rot = rneg
            else
                send.key = col
                send.rot = cneg
            end
        else
            local side = self:CubeTraceSide(dir)
            if not side then return end

            send.key = side
            send.rot = ply:KeyDown(IN_ATTACK) and 1 or -1
        end

        net.Start("RUBIKS.MOVE")
            net.WriteEntity(self)
            net.WriteTable({ send })
        net.Broadcast()

        return send
    end
end


----------------------------------------------------------------
function META:CubeTrace(trace)
    local hitpos = trace.HitPos
    local hitnorm = trace.HitNormal

    if trace.Entity ~= self then return false end

    local pos
    if self.RUBIKS_DATA.SIZE % 2 == 0 then
        pos = HELPER.SnapVector(self:WorldToLocal(hitpos) - Vector(6, 6, 6), 12)/12
        if pos.x >= 0 then pos.x = pos.x + 1 end
        if pos.y >= 0 then pos.y = pos.y + 1 end
        if pos.z >= 0 then pos.z = pos.z + 1 end
    else
        pos = HELPER.SnapVector(self:WorldToLocal(hitpos), 12)/12
    end

    local half = math.floor(self.RUBIKS_DATA.SIZE*0.5)
    pos.x = math.Clamp(pos.x, -half, half)
    pos.y = math.Clamp(pos.y, -half, half)
    pos.z = math.Clamp(pos.z, -half, half)

    local dir = HELPER.SnapVector(self:WorldToLocal(hitpos), self.RUBIKS_DATA.LENGTH*2)/(self.RUBIKS_DATA.LENGTH*2)

    return pos, dir
end


----------------------------------------------------------------
function META:CubeTraceSide(dir)
        if dir == Vector(1, 0, 0)  then return "f", 2, 3
    elseif dir == Vector(-1, 0, 0) then return "b", 2, 3
    elseif dir == Vector(0, 1, 0)  then return "r", 1, 3
    elseif dir == Vector(0, -1, 0) then return "l", 1, 3
    elseif dir == Vector(0, 0, 1)  then return "u", 2, 1
    elseif dir == Vector(0, 0, -1) then return "d", 2, 1
    end
    return false
end


----------------------------------------------------------------
function META:CubeTraceNeighbors(side)
        if side == "f" then return "l", "r", "d", "u"
    elseif side == "b" then return "l", "r", "d", "u"
    elseif side == "r" then return "b", "f", "d", "u"
    elseif side == "l" then return "b", "f", "d", "u"
    elseif side == "u" then return "l", "r", "b", "f"
    elseif side == "d" then return "l", "r", "b", "f"
    end
    return false
end


----------------------------------------------------------------
function META:CubeTraceLayers(pos, dir)
    local side, row, col = self:CubeTraceSide(dir)
    if not side then
        return false, false
    end

    row = pos[row]
    col = pos[col]

    local layer_row = false
    local layer_col = false

    local half = math.floor(self.RUBIKS_DATA.SIZE*0.5)
    local nl, nr, nd, nu = self:CubeTraceNeighbors(side)

    if row ~= 0 then layer_row = string.Trim(string.rep(row < 0 and nl or nr, half - math.abs(row) + 1)) end
    if col ~= 0 then layer_col = string.Trim(string.rep(col < 0 and nd or nu, half - math.abs(col) + 1)) end

    local rneg = (row < 0) and (col > 0 and 1 or -1) or (col > 0 and -1 or 1)
    local cneg = (col > 0) and (row > 0 and 1 or -1) or (row > 0 and -1 or 1)

    if side == "r" or side == "u" or side == "b" then
        rneg = -rneg
        cneg = -cneg
    end

    return layer_row, layer_col, rneg, cneg
end


----------------------------------------------------------------
----------------------------------------------------------------
if SERVER then return end


----------------------------------------------------------------
function META:GetRotation()
    self.RUBIKS_TASK = table.remove(self.RUBIKS_QUEUE, 1)

    local MASTER = self.RUBIKS_DATA.MASTER
    local PUZZLE = self.RUBIKS_PUZZLE
    local TASK = self.RUBIKS_TASK

    if not MASTER[TASK.key] then self.RUBIKS_TASK = nil return end

    local old = MASTER[TASK.key].map
    local new = MASTER[TASK.key][TASK.rot == 1 and "ccw" or "cw"]

    local copy = {}
    for i = 1, #old do
        local old_index = old[i]
        copy[old_index] = table.Copy(PUZZLE[old_index])
        PUZZLE[old_index] = nil
    end

    for i = 1, #new do
        PUZZLE[old[i]] = copy[new[i]]
    end

    TASK.transform_axis = MASTER[TASK.key].dir*TASK.rot
    TASK.transform_pos = {}
    TASK.transform_ang = {}

    for i = 1, #old do
        if not PUZZLE[old[i]] then continue end
        TASK.transform_pos[i] = PUZZLE[old[i]].pos
        TASK.transform_ang[i] = PUZZLE[old[i]].ang
    end

    TASK.old = old
    TASK.tween = 0
end


----------------------------------------------------------------
function META:DoRotation()
    local PUZZLE = self.RUBIKS_PUZZLE
    local TASK = self.RUBIKS_TASK

    local rate = self:GetAnimationSpeed() or 1
    TASK.tween = math.min(TASK.tween + FrameTime()*rate, 1)

    local rotation = HELPER.SmoothStep(TASK.tween)*90
    for i = 1, #TASK.old do
        if not PUZZLE[TASK.old[i]] then continue end

        local ang = Angle(TASK.transform_ang[i])
        local pos = Vector(TASK.transform_pos[i])

        ang:RotateAroundAxis(TASK.transform_axis, rotation)
        HELPER.RotateVectorAroundAxis(pos, TASK.transform_axis, rotation)

        PUZZLE[TASK.old[i]].ang = ang
        PUZZLE[TASK.old[i]].pos = pos
    end

    if TASK.tween == 1 then
        self.RUBIKS_TASK = nil
    end
end


----------------------------------------------------------------
local nullify = not file.Exists("models/rubiks/cube_core.mdl", "GAME")

function META:DrawPuzzle(RENDER)
    if nullify then self:Debug() return end

    RENDER:SetModel("models/rubiks/cube_core.mdl")
    RENDER:SetModelScale(1, 0)

    for i, part in ipairs(self.RUBIKS_PUZZLE) do
        if not part then continue end
        for j = 1, 6 do
            RENDER:SetSubMaterial(j, part.sub[j] and ("rubiks/color_" .. part.sub[j]) or "rubiks/border")
        end

        RENDER:SetRenderOrigin(self:LocalToWorld(part.pos))
        RENDER:SetRenderAngles(self:LocalToWorldAngles(part.ang))
        RENDER:SetupBones()
        RENDER:DrawModel()
    end
end


----------------------------------------------------------------
function META:Debug()
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self.RUBIKS_DATA.MINS, self.RUBIKS_DATA.MAXS, Color(0, 255, 255), true)

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText(self, "TargetIDSmall", pos.x, pos.y, Color(255, 255, 255), 1)
    cam.End2D()
end


----------------------------------------------------------------
local keys = {
    f = { id = 1, dir = Vector(1, 0, 0) },
    b = { id = 2, dir = Vector(-1, 0, 0) },
    r = { id = 3, dir = Vector(0, 1, 0) },
    l = { id = 4, dir = Vector(0, -1, 0) },
    d = { id = 5, dir = Vector(0, 0, -1) },
    u = { id = 6, dir = Vector(0, 0, 1) },
}


----------------------------------------------------------------
function TYPE.GenerateClientData(data)
    data.MASTER = {}

    local size = data.SIZE
    local size_f = math.floor(size*0.5)
    local size_c = math.ceil(size*0.5)

    for k, side in pairs(keys) do
        for l = 1, size_f do
            local key = string.rep(k, l)

            data.MASTER[key] = {
                map = {},
                ccw = {},
                cw  = {},
                dir = side.dir,
            }

            if l == 1 then
                data.MASTER[key].id = side.id
            end
        end
    end

    local index = 0
    for x = 1, size do
        for z = 1, size do
            for y = 1, size do
                local ignore = (x > 1 and x < size) and (z > 1 and z < size) and (y > 1 and y < size)

                index = index + 1
                for key, _ in pairs(keys) do
                    local xyz = (key == "f" and x or key == "b" and -x or key == "u" and z or key == "d" and -z or key == "l" and y or key == "r" and -y)
                    local abs = math.abs(xyz)

                    if xyz > 0 and abs <= size_f then
                        local id = string.rep(key, xyz)
                        table.insert(data.MASTER[id].map, ignore and 0 or index)
                    end
                    if xyz < 0 and abs > size_c then
                        local id = string.rep(key, size + xyz + 1)
                        table.insert(data.MASTER[id].map, ignore and 0 or index)
                    end
                end
            end
        end
    end

    for key, layer in pairs(data.MASTER) do
        local mat = RUBIKS.MATRIX.FromTable(layer.map)
        local side = string.sub(key, 1, 1)

            if side == "b" then RUBIKS.MATRIX.ReverseRows(mat)
        elseif side == "u" then RUBIKS.MATRIX.ReverseColumns(mat)
        elseif side == "r" then RUBIKS.MATRIX.Transpose(mat)
        elseif face == "l" then
            RUBIKS.MATRIX.Transpose(mat)
            RUBIKS.MATRIX.ReverseRows(mat)
        end

        local ccw = table.Copy(mat)
              RUBIKS.MATRIX.Transpose(ccw)
              RUBIKS.MATRIX.ReverseColumns(ccw)

        local cw = table.Copy(mat)
              RUBIKS.MATRIX.Transpose(cw)
              RUBIKS.MATRIX.ReverseRows(cw)

        layer.map = RUBIKS.MATRIX.ToTable(mat)
        layer.ccw = RUBIKS.MATRIX.ToTable(ccw)
        layer.cw = RUBIKS.MATRIX.ToTable(cw)
    end

    data.CREATE = function()
        local puzzle = {}

        local index = 0
        for x = 1, size do
            for z = 1, size do
                for y = 1, size do
                    local ignore = (x > 1 and x < size) and (z > 1 and z < size) and (y > 1 and y < size)

                    index = index + 1
                    if ignore then
                        puzzle[index] = false
                    else
                        puzzle[index] = {
                            id = index,
                            sub = {},
                            pos = Vector(-x*2 + size + 1, y*2 - size - 1, -z*2 + size + 1)*6,
                            ang = Angle()
                        }
                    end
                end
            end
        end

        for key, layer in pairs(data.MASTER) do
            if not layer.id then continue end
            for _, id in ipairs(layer.map) do
                puzzle[id].sub[layer.id] = key
            end
        end

        return puzzle
    end
end
