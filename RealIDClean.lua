
local myname, ns = ...


ns:RegisterEvent("ADDON_LOADED")
function ns:ADDON_LOADED(event, addon)
	if addon ~= myname then return end
	self:InitDB()

	-- Do anything you need to do after addon has loaded

	LibStub("tekKonfig-AboutPanel").new(myfullname, myname) -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function ns:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	-- Do anything you need to do after the player has entered the world
	self:CheckFriendsMatches()

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function ns:PLAYER_LOGOUT()
	self:FlushDB()
	-- Do anything you need to do as the player logs out
end


function ns:CollectRealIDFriends()
  local friends = BNGetNumFriends()
  for i=1,friends do
    local _, givenName, surname = BNGetFriendInfo(i)
    local fullName = givenName .. surname
    if not ns.db.friends[fullName] then
      Debug("New Real ID friend found: " .. fullName)
      ns.db.friends[fullName] = {}
    end
  end
end

function ns:CollectRealIDToons()
  local _,online = BNGetNumFriends()
  for i=1,online do
    local _, givenName, surname, toonName, _, _, _, _, _, _, _, note = BNGetFriendInfo(i)
    local fullName = givenName .. surname
    local found = false
    for _,name in ipairs(ns.db.friends[fullName]) do
      if name == fullName then found = true end
    end
    if not found then
      Debug("New alt found for " .. fullName .. ": " .. toonName)
      table.insert(ns.db.friends[fullName], toonName)
    end
  end
end


function ns:ListRealIDAlts(fullName)
  if ns.db.friends[fullName] then
    return join(ns.db.friends[fullName], ", ")
  else
    return "No known alts"
  end
end


function ns:CheckFriendsMatches()
  self:CollectRealIDFriends()
  self:CollectRealIDToons()

  local friend_toons = {}
  for name, toons in pairs(ns.db.friends) do
    for i=1, #(toons) do
      friend_toons[toons[i]] = name
    end
  end

  local numFriends = GetNumFriends()
  for i=1,numFriends do
    local name = GetFriendInfo(i)
    if friend_toons[name] then
      Debug(name .. " appears to belong to " .. friend_toons[name])
    end
  end
end