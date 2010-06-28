
local myname, ns = ...


_G["SLASH_".. myname:upper().."1"] = GetAddOnMetadata(myname, "X-LoadOn-Slash")
SlashCmdList[myname:upper()] = function(msg)
  -- Do crap here
  if msg == "" then
    ns.Print("Usage: /ric <command>")
    ns.Print("Valid commands are: ")
    ns.Print("scan clear clearignored undo undoall alts auto")
  elseif msg == "scan" then
    ns:CheckFriendsMatches()
  elseif msg == "clear" then
    ns.db.friends = {}
    ns.Print("Data on your Real ID friends' alts has been cleared.")
  elseif msg == "clearignored" then
    ns.Print("Ignored characters cleared.")
    ns.db.ignored = {}
  elseif msg == "undo" then
    ns:UndoLastRemoval()
  elseif msg == "undoall" then
    ns:UndoAllRemovals()
  elseif msg == "alts" then
	ns:ListRealIDAlts()
  elseif msg == "auto" then
    ns.db.auto = not ns.db.auto
    if ns.db.auto then
      ns.Print("Now automatically scanning your friends list on login.")
    else
      ns.Print("No longer automatically scanning your friends list on login.")
    end
  end
end


function ns:ListRealIDAlts()
  for fullName,realms in pairs(self.db.friends) do
    for realm, alts in pairs(realms) do
      print(fullName .. " : " .. realm .. " - " .. table.concat(alts, ", "))
    end
  end
end