---------------------------------------------------------------
---------------------------------------------------------------
resource.AddWorkshop("795252655")

AddCSLuaFile()
AddCSLuaFile("autorun/client/cl_rubiks.lua")

AddCSLuaFile("rubiks/libraries/helper.lua")
AddCSLuaFile("rubiks/libraries/matrix.lua")

AddCSLuaFile("rubiks/property.lua")
AddCSLuaFile("rubiks/network.lua")
AddCSLuaFile("rubiks/render.lua")

AddCSLuaFile("rubiks/types/cube.lua")
AddCSLuaFile("rubiks/types/tetra.lua")
AddCSLuaFile("rubiks/types/skewb.lua")
AddCSLuaFile("rubiks/types/megaminx.lua")

----------------------------------------------------------------
RUBIKS = { TYPES = {} }


----------------------------------------------------------------
include("rubiks/libraries/helper.lua")

include("rubiks/property.lua")
include("rubiks/network.lua")

include("rubiks/types/cube.lua")
include("rubiks/types/tetra.lua")
include("rubiks/types/skewb.lua")
include("rubiks/types/megaminx.lua")
