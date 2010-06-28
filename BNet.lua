-- Handles everything to do with B.Net connections, events and friends

local myname, ns = ...


function ns:BN_DISCONNECTED()
  self:UnregisterEvents("BN_FRIEND_LIST_SIZE_CHANGED","BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
end


function ns:BN_FRIEND_LIST_SIZE_CHANGED()
  self:CollectRealIDFriends()
end


function ns:BN_FRIEND_TOON_ONLINE()
  self:CollectRealIDToons()
end
ns.BN_FRIEND_ACCOUNT_ONLINE = ns.BN_FRIEND_TOON_ONLINE -- No idea if this actually does what I'm hoping


function ns:BN_CONNECTED()
  self:RegisterEvents("BN_FRIEND_LIST_SIZE_CHANGED","BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
end


function ns:CollectRealIDFriends()
  local friends = BNGetNumFriends()
  for i=1,friends do
    local _, givenName, surname = BNGetFriendInfo(i)
    local fullName = givenName .. " " .. surname
    if not self.db.friends[fullName] then
      self.Debug("New Real ID friend found: " .. fullName)
      self.db.friends[fullName] = {}
    end
  end
end


function ns:CollectRealIDToons()
  local _,online = BNGetNumFriends()
  for i=1,online do
    local _, givenName, surname, toonName, _, client, _, _, _, _, _, note = BNGetFriendInfo(i)
    local fullName = givenName .. " " .. surname
    local _,_,_, realm = BNGetFriendToonInfo(i,1)
    if client == "WoW" then
      if not self.db.friends[fullName][realm] then self.db.friends[fullName][realm] = {} end
      if not tContains(self.db.friends[fullName][realm], toonName) then
        self.Debug("New alt found for " .. fullName .. ": " .. toonName .. " on " .. realm)
        table.insert(self.db.friends[fullName][realm], toonName)
      end
    end
  end
end


function ns:AddRealIDAlts()
  local myRealm, friends = GetRealmName(), GetNumFriends()
  for name, realms in pairs(self.db.friends) do
    for realm, toons in pairs(realms) do
      if realm == myRealm and friends < 100 then
        for _, toon in ipairs(toons) do
          if not self.dbpc.automaticallyAdded[myRealm] then self.dbpc.automaticallyAdded[myRealm] = {} end
          table.insert(self.dbpc.automaticallyAdded[myRealm], name)
          if friends < 100 then
            self:AddFriend(name)
            friends = friends + 1
          end
        end
      end
    end
  end
end


function ns:RemoveAutomaticallyAdded()
  local myRealm = GetRealmName()
  if self.db.automaticallyAdded[myRealm] and #(self.db.automaticallyAdded[myRealm]) > 0 then
    for _,name in ipairs(self.db.automaticallyAdded[myRealm]) do
      RemoveFriend(name)
    end
    wipe(self.db.automaticallyAdded[myRealm])
  end
end