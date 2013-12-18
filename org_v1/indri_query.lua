-- TODO allow refining results (indri can query a given document set, the results)
-- TODO fix rendering of spots with long "strong" strings, #od(new driver)

local curses = require("curses") -- from lua posix
local QueryEnvironment = require("indri_queryenvironment")

curses.initscr()
curses.cbreak()
curses.nl(0)
curses.echo(0)
curses.start_color()
curses.use_default_colors()
-- highlighted word in snippet
curses.init_pair(1, curses.COLOR_WHITE, -1)
-- default colors
curses.init_pair(2, -1, -1)
-- selected title
curses.init_pair(3, curses.COLOR_BLACK, curses.COLOR_GREEN)

local stdscr = curses.stdscr() -- global
stdscr:keypad(true)
local maxy, maxx = stdscr:getmaxyx() -- global

local indexes = {"../email_v1_index"} -- global

io.output("/tmp/indri_query_debug.txt")

function cleanupString(str)
   if type(str) ~= "string" or not str then
	  return str
   end
   str = str:gsub("<strong>...</strong>", "...")
   str = str:gsub("&lt;", "<")
   str = str:gsub("&gt;", ">")
   str = str:gsub("&amp;", "&")
   return str
end

function printWithBold(scr, snippet, maxChars)
   while maxChars > 0 do
	  io.write(string.format("1: maxChars = %d\n", maxChars))
	  io.write(string.format("1: snippet = %20s\n", snippet))
	  local strongPos = snippet:find("<strong>")
	  -- just print it if it's out of our range
	  if not strongPos or strongPos >= maxChars then
		 scr:addstr(snippet, maxChars)
		 snippet = snippet:sub(maxChars + 1)
		 maxChars = 0
		 break
	  end

	  -- first print the non-bold section
	  scr:addstr(snippet:sub(1, strongPos - 1), maxChars)
	  maxChars = maxChars - (strongPos - 1)

	  -- handle different possibilities of highlighted strings
	  local strongString = snippet:sub(strongPos + #"<strong>")
	  strongString = strongString:sub(1, strongString:find("</strong>") - 1)

	  if #strongString <= maxChars then
		 -- case #1 snippet including highlighted string will fit
		 scr:attron(curses.A_BOLD)
		 scr:attron(curses.color_pair(1))
		 scr:addstr(strongString)
		 scr:attron(curses.color_pair(2))
		 scr:attroff(curses.A_BOLD)

		 maxChars = maxChars - #strongString
		 snippet = snippet:sub(snippet:find("</strong>") + #"</strong>")
	  elseif #strongString > 10 then
		 -- case #2 highlight spans lines (display this part of it non-boldly)
		 -- we only split highlighted strings greater than 10 chars
		 scr:attron(curses.color_pair(1))
		 scr:addstr(strongString:sub(1, maxChars))
		 scr:attron(curses.color_pair(2))

		 snippet = string.format("<strong>%s%s",
								 strongString:sub(maxChars + 1),
								 snippet:sub(snippet:find("</strong>")))
		 maxChars = 0
	  elseif strongPos == 1 then
		 -- case #3 highlighted part is at the very beginning and won't fit
		 break
	  else
		 -- case #4 only snippet without highlight fits
		 snippet = snippet:sub(strongPos)
	  end
   end
   return snippet, maxChars
end

function showPage(pageNum, pageMinIndex, qr, selectedItem)
   local nextLine

   clear_screen()
   if pageMinIndex[pageNum] == nil then
	  -- first time we see this page, it's going forward
	  pageMinIndex[pageNum] = qr.position
   else
	  -- re-visting a page
	  qr.position = pageMinIndex[pageNum]
   end

   for i = 3, maxy - 4 do
	  stdscr:move(i, 0)
	  if nextLine then
		 printWithBold(stdscr, nextLine, maxx - 2)
		 nextLine = nil
	  else
		 local entry = qr:nextRawEntry()
		 if entry == nil then
			break
		 end
		 local snippet = cleanupString(entry.snippet)
		 local totalChars = maxx -- chars we have left (rename this var)
		 if entry.position == selectedItem then
			stdscr:attron(curses.color_pair(3))
		 end
		 stdscr:addstr(string.format("%4d ", entry.position))
		 totalChars = totalChars - 5
		 local titleChars = math.floor(maxx * 0.3)
		 stdscr:addstr(entry.title, titleChars)
		 stdscr:attron(curses.color_pair(2))
		 totalChars = totalChars - titleChars
		 stdscr:move(i, maxx - totalChars)

		 stdscr:addstr("| ")
		 totalChars = totalChars - 2
		 snippet = printWithBold(stdscr, snippet, totalChars - 2)

		 if #snippet > 10 then
			nextLine = string.rep(" ", maxx - totalChars) .. snippet
		 end
	  end
   end

   local status = string.format("query: %s    results: %d-%d (of %d)    page: %d",
								qr.queryString,
								pageMinIndex[pageNum],
								qr.position - 1,
								qr.count,
								pageNum)
   stdscr:mvaddstr(1, 0, status)

   stdscr:refresh()
end

function showEntry(entry)
   local linesInEntryWin = maxy - 6
   local entryWin = curses.newwin(linesInEntryWin, maxx - 40, 3, 20)
   entryWin:box("|", "-")
   local line = 1
   local maxCharsPerValue = maxx - (40 + 4 + 10 + 2)
   local skipKeys = {snippet = true, content = true, text = true}
   for k, v in pairs(entry) do
	  if not skipKeys[k] then
		 entryWin:mvaddstr(line, 2,
						   string.format("%10s: %s", k, cleanupString(v)),
						   maxCharsPerValue)
		 line = line + 1
	  end
   end
   entryWin:mvaddstr(line, 2, string.format("%10s: ", "snippet"))
   local snippet = cleanupString(entry.snippet)
   while line <= linesInEntryWin and snippet ~= "" do
	  entryWin:move(line, 14)
	  snippet = printWithBold(entryWin, snippet, maxCharsPerValue)
	  line = line + 1
   end

   entryWin:mvaddstr(line, 2, string.format("%10s: ", "text"))
   snippet = cleanupString(entry.text)
   entryWin:mvaddstr(line, 14, snippet)

   entryWin:refresh()
   entryWin:getch()
   entryWin:clear()
   entryWin:refresh()
   entryWin:close()
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
   local stat, res = pcall(qe.query, qe, queryString)
   if not stat then
	  stdscr:mvaddstr(4, 0, string.format("Error during query: %s", res))
	  stdscr:mvaddstr(5, 0, "Press any key to continue")
	  stdscr:refresh()
	  stdscr:getch()
	  return
   end
   qr = res

   -- mapping of page->minResultIndex
   local pageMinIndex = {1}
   local currentPage = 1
   local selectedItem = 1

   local nextPage = function ()
	  if qr.position < qr.count then
		 currentPage = currentPage + 1
		 selectedItem = qr.position
		 showPage(currentPage, pageMinIndex, qr, selectedItem)
	  end
   end

   local prevPage = function ()
	  if currentPage > 1 then
		 selectedItem = pageMinIndex[currentPage] - 1
		 currentPage = currentPage - 1
		 showPage(currentPage, pageMinIndex, qr, selectedItem)
	  end
   end

   -- show first page
   showPage(currentPage, pageMinIndex, qr, selectedItem)

   -- process commands
   while true do
	  local k = stdscr:getch()
	  local keyname = curses.keyname(k)
	  -- debug the keyname
	  --stdscr:mvaddstr(0, 0, string.format("< %s >", keyname))
	  if keyname == "q" then
		 break
	  elseif keyname == "KEY_NPAGE" then
		 nextPage()
	  elseif keyname == "KEY_PPAGE" then
		 prevPage()
	  elseif keyname == "KEY_DOWN" then
		 if selectedItem + 1 < qr.position then
			selectedItem = selectedItem + 1
			-- redisplaying the whole page, maybe not the most efficient
			showPage(currentPage, pageMinIndex, qr, selectedItem)
		 else
			nextPage()
		 end
	  elseif keyname == "KEY_UP" then
		 if selectedItem > pageMinIndex[currentPage] then
			selectedItem = selectedItem - 1
			showPage(currentPage, pageMinIndex, qr, selectedItem)
		 else
			prevPage()
		 end
	  elseif keyname == "^J" then
		 stdscr:clear()
		 stdscr:refresh()
		 showEntry(qr:entry(selectedItem))
		 -- refresh page
		 showPage(currentPage, pageMinIndex, qr, selectedItem)
	  end
   end

   qe:close()
end

function clear_screen()
   local title = "Indri Query"
   stdscr:clear()
   stdscr:move(0, 0)
   local dashCount = ((maxx - 2) - #title) / 2
   for i = 1, dashCount do
	  stdscr:addch("-")
   end
   stdscr:addstr(" " .. title .. " ")
   for i = 1, dashCount do
	  stdscr:addch("-")
   end
   stdscr:mvaddstr(maxy - 1, 0, "q: query   x: exit                    ")

   stdscr:mvaddstr(2, 0, ("-"):rep(maxx - 1))

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
