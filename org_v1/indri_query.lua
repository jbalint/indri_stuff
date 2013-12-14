local curses = require("curses") -- from lua posix
local QueryEnvironment = require("indri_queryenvironment")
curses.initscr()
curses.cbreak()
curses.nl(0)
curses.echo(0)
local stdscr = curses.stdscr()
stdscr:keypad(true)
local maxy, maxx = stdscr:getmaxyx()

local indexes = {"../email_v1_index"}

function printWithBold(snippet, maxChars)
   while true do
	  local strongPos = snippet:find("<strong>")
	  -- just print it if it's out of our range
	  if not strongPos or strongPos >= maxChars then
		 stdscr:addstr(snippet, maxChars)
		 snippet = snippet:sub(maxChars)
		 maxChars = 0
		 break
	  end
	  local strongString = snippet:sub(strongPos + #"<strong>")
	  strongString = strongString:sub(1, strongString:find("</strong>") - 1)
	  local charsTilStrongEnd = strongPos + #strongString - 1
	  if charsTilStrongEnd < maxChars then
		 -- case #1 snippet include bold will fit
		 stdscr:addstr(snippet:sub(1, strongPos - 1))
		 stdscr:attron(curses.A_BOLD)
		 stdscr:addstr(strongString)
		 stdscr:attroff(curses.A_BOLD)
		 maxChars = maxChars - charsTilStrongEnd
		 snippet = snippet:sub(snippet:find("</strong>") + #"</strong>")
	  elseif strongPos < maxChars then
		 -- case #2 only snippet without bold will fit
		 stdscr:addstr(snippet:sub(1, strongPos - 1))
		 maxChars = maxChars - strongPos
		 snippet = snippet:sub(strongPos)
	  end
   end
   return snippet, maxChars
end

function doQuery()
   -- create query input window
   local qInput = curses.newwin(3, 40, maxy / 2, (maxx / 2) - 20)
   qInput:box("|", "-")
   qInput:mvaddstr(1, 3, "Query: ")
   qInput:refresh()

   -- accept query input
   curses.cbreak(0)
   curses.echo(1)
   local queryString = qInput:getstr()
   curses.cbreak()
   curses.echo(0)

   -- remove query input window
   qInput:clear()
   qInput:refresh()
   qInput:close()

   -- cancel if no input entered
   if queryString == "" then
	  return
   end

   -- begin indri query
   local qe = QueryEnvironment.new()
   qe:addIndex(indexes[1])
   local qr = qe:query(queryString)

   -- display first page of results
   stdscr:mvaddstr(1, 0, string.format("query: %s    results: %d",
									   queryString,
									   qr:resultCount()))
   stdscr:move(2, 0)
   for i = 1, maxx do stdscr:addch("-") end
   local nextLine
   for i = 3, maxy - 4 do
	  stdscr:move(i, 0)
	  if nextLine then
		 printWithBold(nextLine, maxx - 2)
		 nextLine = nil
	  else
		 local entry = qr:nextRawEntry()
		 if entry == nil then
			break
		 end
		 local snippet = entry.snippet
		 snippet = snippet:gsub("<strong>...</strong>", "...")
		 snippet = snippet:gsub("&lt;", "<")
		 snippet = snippet:gsub("&gt;", ">")
		 snippet = snippet:gsub("&amp;", "&")
		 local totalChars = maxx - 1 -- chars we have left (rename this var)
		 stdscr:addstr(string.format("%4d ", entry.position))
		 totalChars = totalChars - 5
		 local titleChars = math.floor(maxx * 0.3)
		 stdscr:addstr(entry.title, titleChars)
		 totalChars = totalChars - titleChars
		 stdscr:move(i, maxx - totalChars)

		 stdscr:addstr("| ")
		 totalChars = totalChars - 2
		 snippet = printWithBold(snippet, totalChars)

		 if #snippet > 10 then
			nextLine = string.rep(" ", maxx - totalChars) .. snippet
		 end
	  end
   end
   stdscr:refresh()

   -- process commands
   while true do
	  local k = stdscr:getch()
	  stdscr:mvaddstr(0, 0, string.format("%d ", k))
	  stdscr:refresh()
	  if k == curses.KEY_DOWN then
		 stdscr:mvaddstr(0, 0, "DOWN")
		 stdscr:refresh()
	  elseif k < 256 then
		 k = string.char(k)
		 if k == "q" then
			break
		 end
	  end
   end

   qe:close()
end

function clear_screen()
   local title = "Indri Query"
   stdscr:clear()
   --stdscr:move(0, 0)
   local dashCount = ((maxx - 2) - #title) / 2
   for i = 1, dashCount do
	  stdscr:addch("-")
   end
   stdscr:addstr(" " .. title .. " ")
   for i = 1, dashCount do
	  stdscr:addch("-")
   end
   stdscr:mvaddstr(maxy - 1, 0, "q: query   x: exit                    ")
   stdscr:refresh()
end

function main()
   while true do
	  clear_screen()
	  local k = string.char(stdscr:getch())
	  if k == "x" then
		 curses.endwin()
		 print("Done!")
		 return
	  elseif k == "q" then
		 doQuery()
	  end
   end
end

local status, err = pcall(main)
curses.endwin()
if err then
   print(err)
end
