--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
--/ Rubiks Puzzle Addon
--/ by shadowscion

--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
RUBIKS = {}


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
AddCSLuaFile("autorun/client/cl_rubiks.lua")


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
AddCSLuaFile("rubiks/libraries/helper.lua")
AddCSLuaFile("rubiks/libraries/matrix.lua")


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
AddCSLuaFile("rubiks/property.lua")
AddCSLuaFile("rubiks/network.lua")
AddCSLuaFile("rubiks/render.lua")
AddCSLuaFile("rubiks/puzzle.lua")


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
AddCSLuaFile("rubiks/puzzles/cube.lua")
AddCSLuaFile("rubiks/puzzles/tetra.lua")


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
include("rubiks/libraries/helper.lua")
include("rubiks/property.lua")
include("rubiks/network.lua")

