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

    local move_from = self.rubiks.master[self.rubiks.task.key].map
    local move_to = self.rubiks.master[self.rubiks.task.key][self.rubiks.task.rot == 1 and "ccw" or "cw"]

    local copy = {}
    for i = 1, #move_from do
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

    local rotation = HELPER.SmoothStep(self.rubiks.task.tween)*90
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
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self.rubiks_mins, self.rubiks_maxs, Color(0, 255, 255), true)
    render.DrawLine(self:GetPos(), self:GetPos() + self:GetForward()*self.rubiks_length, Color(0, 255, 0), false)
    render.DrawLine(self:GetPos(), self:GetPos() + self:GetRight()*self.rubiks_length, Color(255, 0, 0), false)
    render.DrawLine(self:GetPos(), self:GetPos() + self:GetUp()*self.rubiks_length, Color(0, 0, 255), false)

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText(self.rubiks_name, "TargetID", pos.x, pos.y, Color(255, 255, 255))
    cam.End2D()
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:Draw()
    if halo.RenderedEntity() == self then return end

    if not self.rubiks then return end
    if not self.rubiks.puzzle then return end

    local RENDER = RUBIKS.RENDER

    if not IsValid(RENDER) then return end

    RENDER:SetModel("models/rubiks/cube_core.mdl")
    RENDER:SetModelScale(1, 0)

    for i, part in ipairs(self.rubiks.puzzle) do
        if not part then continue end
        for j = 1, 6 do
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
    local ply = LocalPlayer()

    if not self:ShouldDrawHUD(ply) then return end

    local trace = ply:GetEyeTrace()
    local pos, dir = self:CubeTrace(trace)

    local time = TimedSin(1/3, -1/2, 1/2, 0)

    if ply:KeyDown(IN_SPEED) then
        local row, col, rneg, cneg = self:CubeTraceLayers(pos, dir)

        if row then
            local len = (math.floor(self.rubiks_size*0.5) - string.len(row))*12 + (self.rubiks_size % 2 == 0 and 6 or 12)

            local fdir = self.rubiks.master[row].dir
            local udir = fdir:Cross(dir*rneg):GetNormalized()
            local offset = dir*self.rubiks_length + fdir*len

            local anim = time*udir
            local line_a = offset + udir*(self.rubiks_length + 1) - anim
            local line_b = offset + udir*(self.rubiks_length + 13) - anim

            local tex = line_a:Distance(line_b)/12
            render.SetMaterial(arrow_lmb)
            render.DrawBeam(self:LocalToWorld(line_b), self:LocalToWorld(line_a), 12, 0, tex, arrow_color)
        end

        if col then
            local len = (math.floor(self.rubiks_size*0.5) - string.len(col))*12 + (self.rubiks_size % 2 == 0 and 6 or 12)

            local fdir = self.rubiks.master[col].dir
            local udir = fdir:Cross(dir*cneg):GetNormalized()
            local offset = dir*self.rubiks_length + fdir*len

            local anim = time*udir
            local line_a = offset + udir*(self.rubiks_length + 1) + anim
            local line_b = offset + udir*(self.rubiks_length + 13) + anim

            local tex = line_a:Distance(line_b)/12
            render.SetMaterial(arrow_rmb)
            render.DrawBeam(self:LocalToWorld(line_b), self:LocalToWorld(line_a), 12, 0, tex, arrow_color)
        end
    else
        local side = self:CubeTraceSide(dir)
        local nl, _, _, nu = self:CubeTraceNeighbors(side)

        if not nl then return end

        local udir = self.rubiks.master[nu].dir
        if side == "u" then
            udir = -udir
        end

        local rdir = dir:Cross(udir):GetNormal()

        local length = self.rubiks_length + 6
        local line_a = rdir*6 + udir*length + dir*length
        local line_b = -rdir*6 + udir*length + dir*length

        local anim = 320 + time*self.rubiks_size

        HELPER.RotateVectorAroundAxis(line_a, dir, anim)
        HELPER.RotateVectorAroundAxis(line_b, dir, anim)

        local tex = line_a:Distance(line_b)/12

        render.SetMaterial(arrow_lmb)
        render.DrawBeam(self:LocalToWorld(line_a), self:LocalToWorld(line_b), 12, 0, tex, arrow_color)

        HELPER.RotateVectorAroundAxis(line_a, dir, -anim*2)
        HELPER.RotateVectorAroundAxis(line_b, dir, -anim*2)

        render.SetMaterial(arrow_rmb)
        render.DrawBeam(self:LocalToWorld(line_b), self:LocalToWorld(line_a), 12, 0, tex, arrow_color)
    end
end
