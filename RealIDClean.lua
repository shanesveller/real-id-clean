
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

    self:RegisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE","BN_FRIEND_LIST_SIZE_CHANGED","FRIENDLIST_UPDATE")
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
  self:UnregisterEvents("BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE","BN_FRIEND_LIST_SIZE_CHANGED","FRIENDLIST_UPDATE")
end


-- Re-activate after combat
function ns:PLAYER_LEAVE_COMBAT()
  self:RegisterEvents("BN_FRIEND_LIST_SIZE_CHANGED","FRIENDLIST_UPDATE","BN_FRIEND_TOON_ONLINE","BN_FRIEND_ACCOUNT_ONLINE")
end


function ns:FRIENDLIST_UPDATE()
  if self.db.auto then self:CheckFriendsMatches() end
end


function ns:CheckFriendsMatches()
  self.Debug("Checking for friend list matches")
  local friend_toons, myRealm = {}, GetRealmName()

  -- Collect all alts on the realm you're currently logged into
  for fullName, realms in pairs(self.db.friends) do
    for realm, alts in pairs(realms) do
      if realm == myRealm then
        for _,toonName in ipairs(alts) do
          friend_toons[toonName] = fullName
        end
      end
    end
  end

  local numFriends = GetNumFriends()
  for i=1,numFriends do
    local name = GetFriendInfo(i)
    if friend_toons[name] and not self.db.ignored[myRealm][name] then
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


function ns:AddFriend(toonName)
  self:UnregisterEvent("FRIENDLIST_UPDATE")
  AddFriend(toonName)
  self:RegisterEvent("FRIENDLIST_UPDATE")
end


function ns:RemoveFriend(toonName, friendName)
  self.Debug("Remove friend " .. toonName)
  self.dbpc.removed[toonName] = friendName
  table.insert(self.dbpc.recentlyRemoved, toonName)
  RemoveFriend(toonName)
end


function ns:UndoLastRemoval()
  local lastRemoved = self.dbpc.recentlyRemoved[1]
  self.Debug("Undo last removal: " .. lastRemoved)
  self:AddFriend(lastRemoved)
  table.remove(self.dbpc.recentlyRemoved, 1)
  self.dbpc.removed[lastRemoved] = nil
end


function ns:UndoAllRemovals()
  self.Debug("Undo all removals")
  self:UnregisterEvent("FRIENDLIST_UPDATE")
  for name, _ in pairs(self.dbpc.removed) do
    AddFriend(name)
  end
  self.dbpc.removed = {}
  self.dbpc.recentlyRemoved = {}
  self:RegisterEvent("FRIENDLIST_UPDATE")
end


function ns:AddIgnored(toonName, realmName)
  self.Debug("Ignore friend " .. toonName .. " of " .. realmName)
  self.db.ignored[realmName][toonName] = true
end


function ns:RemoveIgnored(toonName, realmName)
  self.Debug("Un-ignore friend " .. toonName)
  self.db.ignored[realmName][toonName] = nil
end


function ns:ClearIgnored()
  self.Debug("Removing all ignored friends")
  wipe(self.db.ignored)
end
