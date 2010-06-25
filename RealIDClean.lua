
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
-- Don't scan if player logged in/reloaded in combat
if not InCombatLockdown() then
  self:CollectRealIDFriends()
  self:CollectRealIDToons()
  if self.db.auto then self:CheckFriendsMatches() end

  self:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
  self:RegisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
  self:RegisterEvent("FRIENDLIST_UPDATE")
end

self:RegisterEvents("PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT")

  self:UnregisterEvent("PLAYER_LOGIN")
  self.PLAYER_LOGIN = nil
end


function ns:PLAYER_LOGOUT()
  self:FlushDB()
  -- Do anything you need to do as the player logs out
end


-- Be combat friendly
function ns:PLAYER_ENTER_COMBAT()
  StaticPopup_Hide("REALID_CLEAN_PROMPT")
  self:UnregisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
  self:UnregisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
  self:UnregisterEvent("FRIENDLIST_UPDATE")
end


-- Re-activate after combat
function ns:PLAYER_LEAVE_COMBAT()
  self:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
  self:RegisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
  self:RegisterEvent("FRIENDLIST_UPDATE")
end


function ns:BN_FRIEND_LIST_SIZE_CHANGED()
  self.Debug("BN_FRIEND_LIST_SIZE_CHANGED")
  self:CollectRealIDFriends()
end


function ns:BN_FRIEND_TOON_ONLINE()
  self.Debug(event) -- Should hopefully print "BN_FRIEND_TOON_ONLINE" / "BN_FRIEND_ACCOUNT_ONLINE" if I'm doinitrite
  self:CollectRealIDToons()
end
ns.BN_FRIEND_ACCOUNT_ONLINE = ns.BN_FRIEND_TOON_ONLINE -- No idea if this actually does what I'm hoping


function ns:FRIENDLIST_UPDATE()
  self.Debug(event)
  self:CheckFriendsMatches()
end


function ns:BN_DISCONNECTED()
  self:UnregisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
  self:UnregisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
  self:UnregisterEvent("FRIENDLIST_UPDATE")
end


function ns:BN_CONNECTED()
  self:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
  self:RegisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
  self:RegisterEvent("FRIENDLIST_UPDATE")
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
    local found, fullName = false, givenName .. " " .. surname
    local _,_,_, realm = BNGetFriendToonInfo(i,1)
    if client == "WoW" then
      self.Debug(givenName, surname, toonName, realm, client)
      for _,nameAndRealm in ipairs(self.db.friends[fullName]) do
        local checkRealm, checkName = strsplit("-",nameAndRealm)
        self.Debug(checkRealm, realm, checkName, name)
        if checkRealm == realm and checkName == toonName then
          found = true
          break
        end
      end
      if not found then
        self.Debug("New alt found for " .. fullName .. ": " .. toonName .. " on " .. realm)
        table.insert(self.db.friends[fullName], realm .. "-" .. toonName)
      end
    end
  end
end


function ns:ListRealIDAlts(fullName)
  if #self.db.friends[fullName] > 0 then
    self.Print(fullName .. " : " .. table.concat(self.db.friends[fullName], ", "))
  else
    self.Print(fullName .. " has no known alts.")
  end
end


function ns:CheckFriendsMatches()
  self.Debug("Checking for friend list matches")
  local friend_toons, myRealm = {}, GetRealmName()
  for name, realmsAndNames in pairs(self.db.friends) do
    for i=1, #(realmsAndNames) do
      local realm, toonName = strsplit("-",realmsAndNames[i])
      self.Debug(myRealm, realm, toonName)
      if realm == myRealm then
        friend_toons[toonName] = name
      end
    end
  end

  local numFriends = GetNumFriends()
  for i=1,numFriends do
    local name = GetFriendInfo(i)
    if friend_toons[name] and not self.db.ignored[myRealm .. "-" .. name] then
      self.Debug(name .. " appears to belong to " .. friend_toons[name])
      self:PromptToRemove(name, friend_toons[name])
    end
  end
end


function ns:PromptToRemove(toonName, friendName)
  -- See also: http://www.wowwiki.com/Creating_simple_pop-up_dialog_boxes
  local popup = StaticPopup_Show("REALID_CLEAN_PROMPT", toonName, friendName)
  if (popup) then
    popup.data = toonName
    popup.data2 = friendName
  end
end


StaticPopupDialogs["REALID_CLEAN_PROMPT"] = {
  text = "The character '%s' appears to belong to your RealID friend, '%s'. Would you like to remove this character from your friends list? Click \"Ignore\" to never be prompted about this character again.",
  button1 = "Yes",
  button2 = "No",
  button3 = "Ignore",
  OnAccept = function(self, data, data2)
    ns:RemoveFriend(data, data2) -- toonName, friendName
  end,
  OnAlt = function(self, data, data2)
    ns:AddIgnored(data, GetRealmName()) -- toonName
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  showAlert = true,
}


function ns:RemoveFriend(toonName, friendName)
  self.Debug("Remove friend " .. toonName)
  self.dbpc.removed[toonName] = friendName
  table.insert(self.dbpc.recentlyRemoved, toonName)
  RemoveFriend(toonName)
end


function ns:UndoLastRemoval()
  self:UnregisterEvent("FRIENDLIST_UPDATE")
  local lastRemoved = self.dbpc.recentlyRemoved[1]
  self.Debug("Undo last removal: " .. lastRemoved)
  AddFriend(lastRemoved)
  table.remove(self.dbpc.recentlyRemoved, 1)
  self.dbpc.removed[lastRemoved] = nil
  self:RegisterEvent("FRIENDLIST_UPDATE")
end


function ns:UndoAllRemovals()
  self:UnregisterEvent("FRIENDLIST_UPDATE")
  self.Debug("Undo all removals")
  for name, _ in pairs(self.dbpc.removed) do
    AddFriend(name)
  end
  self.dbpc.removed = {}
  self.dbpc.recentlyRemoved = {}
  self:RegisterEvent("FRIENDLIST_UPDATE")
end


function ns:AddIgnored(toonName, realmName)
  self.Debug("Ignore friend " .. toonName .. " of " .. realmName)
  self.db.ignored[realmName .. "-" .. toonName] = true
end


function ns:RemoveIgnored(toonName, realmName)
  self.Debug("Un-ignore friend " .. toonName)
  self.db.ignored[realmName .. "-" .. toonName] = nil
end


function ns:ClearIgnored()
  self.Debug("Removing all ignored friends")
  self.db.ignored = {}
end


function ns:ReAddRealIDAlts()
  local myRealm = GetRealmName()
  for name, alts in pairs(self.db.friends) do
    for _, realmAndName in ipairs(alts) do
      local realm, name = strsplit("-",realmAndName)
      if realm == myRealm then
        if not self.db.automaticallyAdded[myRealm] then self.db.automaticallyAdded[myRealm] = {} end
        table.insert(self.db.automaticallyAdded[myRealm], name)
        AddFriend(name)
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