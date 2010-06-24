
local myname, ns = ...


_G["SLASH_".. myname:upper().."1"] = GetAddOnMetadata(myname, "X-LoadOn-Slash")
SlashCmdList[myname:upper()] = function(msg)
	-- Do crap here
	if msg == "scan" then
  	ns:CheckFriendsMatches()
  elseif msg == "clear"
    ns.db.friends = {}
    ns:Print("Data on your Real ID friends' alts has been cleared.")
  elseif msg == "undo"
    ns:UndoLastRemoval()
  elseif msg == "undoall"
    ns:UndoAllRemovals()
  elseif msg == "auto"
    ns.db.auto = not ns.db.auto
    if ns.db.auto then
      ns:Print("Now automatically scanning your friends list on login.")
    else
      ns:Print("No longer automatically scanning your friends list on login.")
    end
  end
end
