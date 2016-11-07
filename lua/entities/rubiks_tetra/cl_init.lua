--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
include("shared.lua")


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:Think()
    if not IsValid(self:GetPhysicsObject()) then self:Rebuild() end
    if not self:Synchronized() then return end

    self:HandleQueue()
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:ResetRubiks()
    self.rubiks = {}

    local type = RUBIKS.GetPuzzle(self.rubiks_name)

    if type then
        self.rubiks.master = type.Master
        self.rubiks.puzzle = type.Create()
    end
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:Synchronized(force)
    if not self.rubiks then
        self.rubiks = {}

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(self)
        net.SendToServer()

        return false
    end

    if not self.rubiks.master then return false end
    if not self.rubiks.puzzle then return false end

    return true
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:HandleQueue()
    if not self.rubiks.task then
        if not self.rubiks.queue then
            self.rubiks.queue = {}
            return
        elseif #self.rubiks.queue == 0 then
            return
        else
            self:GetRotation()
        end
    else
        self:DoRotation()
    end
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:AddRotation(data)
    self.rubiks.queue = self.rubiks.queue or {}
    table.insert(self.rubiks.queue, data)
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:GetRotation()
    self.rubiks.task = table.remove(self.rubiks.queue, 1)

    local move_from = {}
    local move_to = {}

    local key = self.rubiks.task.key
    local rkey = self.rubiks.task.rot == 1 and "ccw" or "cw"

    for n = string.len(key), 1, -1 do
        local tbl = self.rubiks.master[string.rep(string.sub(key, 1, 1), n)]
        if not tbl then continue end

        local num = #tbl.outer
        local rot = tbl["outer_" .. rkey]
        for i = 1, num do
            table.insert(move_from, tbl.outer[i])
            if rot then
                table.insert(move_to, rot[i])
            else
                --table.insert(move_to, tbl.outer[i])
            end
        end

        local num = #tbl.inner
        local rot = tbl["inner_" .. rkey]
        for i = 1, num do
            table.insert(move_from, tbl.inner[i])
            if rot then
                table.insert(move_to, rot[i])
            else
                --table.insert(move_to, tbl.inner[i])
            end
        end
    end

    local copy = {}
    for i = 1, #move_from do
        if not move_to[i] then continue end
        local move_from_index = move_from[i]
        copy[move_from_index] = table.Copy(self.rubiks.puzzle[move_from_index])
        self.rubiks.puzzle[move_from_index] = nil
    end

    for i = 1, #move_to do
        self.rubiks.puzzle[move_from[i]] = copy[move_to[i]]
    end

    self.rubiks.task.transform_axis = self.rubiks.master[self.rubiks.task.key].dir*self.rubiks.task.rot
    self.rubiks.task.transform_pos = {}
    self.rubiks.task.transform_ang = {}

    for i = 1, #move_from do
        if not self.rubiks.puzzle[move_from[i]] then continue end
        self.rubiks.task.transform_pos[i] = self.rubiks.puzzle[move_from[i]].pos
        self.rubiks.task.transform_ang[i] = self.rubiks.puzzle[move_from[i]].ang
    end

    self.rubiks.task.move_from = move_from
    self.rubiks.task.tween = 0
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:DoRotation()
    local rate = math.min(#self.rubiks.queue + (RUBIKS.ANIM_SPEED or 1) + 1, 6)
    self.rubiks.task.tween = math.min(self.rubiks.task.tween + FrameTime()*rate, 1)

    local rotation = HELPER.SmoothStep(self.rubiks.task.tween)*120
    for i = 1, #self.rubiks.task.move_from do
        if not self.rubiks.puzzle[self.rubiks.task.move_from[i]] then continue end

        local ang = Angle(self.rubiks.task.transform_ang[i])
        local pos = Vector(self.rubiks.task.transform_pos[i])

        ang:RotateAroundAxis(self.rubiks.task.transform_axis, rotation)
        HELPER.RotateVectorAroundAxis(pos, self.rubiks.task.transform_axis, rotation)

        self.rubiks.puzzle[self.rubiks.task.move_from[i]].ang = ang
        self.rubiks.puzzle[self.rubiks.task.move_from[i]].pos = pos
    end

    if self.rubiks.task.tween == 1 then
        self.rubiks.task = nil
    end
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:DrawDebug()
    for i = 1, #self.convexes do
        for j = i, #self.convexes do
            render.DrawLine(self:LocalToWorld(self.convexes[i]), self:LocalToWorld(self.convexes[j]), Color(0, 255, 255), true)
        end
    end

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText("rubiks_" .. self.rubiks_name .. "(" .. self:EntIndex() .. ")", "TargetID", pos.x, pos.y, Color(255, 255, 255))
    cam.End2D()
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local nullify = not file.Exists("models/rubiks/tetra_core.mdl", "GAME")

function ENT:Draw()
    if nullify then self:DrawDebug() return end

    if halo.RenderedEntity() == self then return end

    if not self.rubiks then return end
    if not self.rubiks.puzzle then return end

    local RENDER = RUBIKS.RENDER

    RENDER:SetModel("models/rubiks/tetra_core.mdl")
    RENDER:SetModelScale(1, 0)

    for i, part in ipairs(self.rubiks.puzzle) do
        if not part then continue end
        for j = 1, 4 do
            RENDER:SetSubMaterial(j, part.sub[j] and ("rubiks/color_" .. part.sub[j]) or "rubiks/border")
        end

        RENDER:SetRenderOrigin(self:LocalToWorld(part.pos))
        RENDER:SetRenderAngles(self:LocalToWorldAngles(part.ang))
        RENDER:SetupBones()
        RENDER:DrawModel()
    end

    self:DrawHUD()
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local bool = GetConVar("rubiks_draw_hud")
function ENT:ShouldDrawHUD(ply)
    if not bool:GetBool() then return false end

    if self:GetNWInt("ownerid") ~= ply:UserID() then
        return false
    end

    local weapon = ply:GetActiveWeapon():GetClass()
    if weapon == "weapon_physgun" or weapon == "gmod_tool" then
        return false
    end

    return true
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local arrow_lmb = Material("rubiks/arrow_lmb.png", "unlitsmooth")
local arrow_rmb = Material("rubiks/arrow_rmb.png", "unlitsmooth")
local arrow_color = Color(255, 255, 255, 150)

local deg2rad = math.pi/180

function ENT:DrawHUD()
    /*
    local ply = LocalPlayer()
    if not self:ShouldDrawHUD(ply) then return end

    local trace = ply:GetEyeTrace()
    if trace.Entity ~= self then return end

    local key, _, face_pos, face_dir = self:GetTetraTrace(trace)

    local fdir = self.rubiks.master[key].dir
    local udir = fdir:Cross(face_dir):GetNormalized()
    local offset = face_pos --+ fdir*10

    local line_a = offset + udir*(12 + 1) + fdir*6
    local line_b = offset + udir*(12 + 13) + fdir*6

    local tex = line_a:Distance(line_b)/9
    render.SetMaterial(arrow_lmb)
    render.DrawBeam(self:LocalToWorld(line_b), self:LocalToWorld(line_a), 9, 0, tex, arrow_color)

    cam.Start2D()
        draw.SimpleText(key, "TargetID", 64, 64, Color(255, 255, 255))
    cam.End2D()
    */
end
