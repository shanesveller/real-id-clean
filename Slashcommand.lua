
local myname, ns = ...


_G["SLASH_".. myname:upper().."1"] = GetAddOnMetadata(myname, "X-LoadOn-Slash")
SlashCmdList[myname:upper()] = function(msg)
	-- Do crap here
	if msg == "scan" then
  	ns:CheckFriendsMatches()
  elseif msg == "clear"
    ns.db.friends = {}
  elseif msg == "undo"
    ns:UndoLastRemoval()
  elseif msg == "undoall"
    ns:UndoAllRemovals()
  elseif msg == "auto"
    ns.db.auto = not ns.db.auto
  end
end
