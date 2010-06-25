
local myname, ns = ...


ns.defaults = {
  --[[
  friends = {}, -- Real ID friends
  ignored = {},
  auto = false,
  ]]
}
ns.defaultsPC = {
  --[[
  removed = {},
  recentlyRemoved = {},
  ]]
} -- No need to save non-Real ID friends list in DBPC (yet)


function ns.InitDB()
	-- local myname = "RealIDClean"
	_G[myname.."DB"] = setmetatable(_G[myname.."DB"] or {}, {__index = ns.defaults})
	ns.db = _G[myname.."DB"]
	if not ns.db.friends then ns.db.friends = {} end
	if not ns.db.ignored then ns.db.ignored = {} end
	if ns.db.auto == nil then ns.db.auto = false end
	
	_G[myname.."DBPC"] = setmetatable(_G[myname.."DBPC"] or {}, {__index = ns.defaultsPC})
	ns.dbpc = _G[myname.."DBPC"]
	if not ns.dbpc.removed then ns.dbpc.removed = {} end
	if not ns.dbpc.recentlyRemoved then ns.dbpc.recentlyRemoved = {} end
end


function ns.FlushDB()
	for i,v in pairs(ns.defaults) do if ns.db[i] == v then ns.db[i] = nil end end
	for i,v in pairs(ns.defaultsPC) do if ns.dbpc[i] == v then ns.dbpc[i] = nil end end
end
