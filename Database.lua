
local myname, ns = ...


ns.defaults = {}
ns.defaultsPC = {}


function ns.InitDB()
  local realm = GetRealmName()

  _G[myname.."DB"] = setmetatable(_G[myname.."DB"] or {}, {__index = ns.defaults})
  ns.db = _G[myname.."DB"]
  if not ns.db.friends then ns.db.friends = {} end
  if not ns.db.ignored then ns.db.ignored = {} end
  if not ns.db.ignored[realm] then ns.db.ignored[realm] = {} end
  if ns.db.auto == nil then ns.db.auto = false end

  _G[myname.."DBPC"] = setmetatable(_G[myname.."DBPC"] or {}, {__index = ns.defaultsPC})
  ns.dbpc = _G[myname.."DBPC"]
  if not ns.dbpc.removed then ns.dbpc.removed = {} end
  if not ns.dbpc.recentlyRemoved then ns.dbpc.recentlyRemoved = {} end
  if not ns.dbpc.automaticallyAdded then ns.dbpc.automaticallyAdded = {} end

  if not ns.db.version or ns.db.version < 1 then ns.ImportOldData() end
end


function ns.FlushDB()
  for i,v in pairs(ns.defaults) do if ns.db[i] == v then ns.db[i] = nil end end
  for i,v in pairs(ns.defaultsPC) do if ns.dbpc[i] == v then ns.dbpc[i] = nil end end
end


function ns.ImportOldData()
  if not ns.db.version or ns.db.version < 1 then
    for friend,alts in pairs(RealIDCleanDB.friends) do
      for k,v in pairs(alts) do
        if type(v) == "string" then
          local realm, name = strsplit("-", v)
          ns.Debug("Convertigng " .. friend .. " - " .. realm .. ":" .. name)
          if not ns.db.friends[friend][realm] then ns.db.friends[friend][realm] = {} end
          if not tContains(ns.db.friends[friend][realm], name) then tinsert(ns.db.friends[friend][realm], name) end
          ns.db.friends[friend][k] = nil
        end
        if k == "" then
          ns.db.friends[friend][k] = nil
        end
      end
    end
    ns.db.version = 1
  end
end