local pp = require("pl.pretty").dump

local QueryEnvironment = require("indri_queryenvironment")

local qe = QueryEnvironment.new()
qe:addIndex("../email_v1_index")
local qr = qe:query("tonci")

for rawEntry in qr:rawIterator(2) do
   print("Entry:")
   pp(rawEntry)
end
qe:close()
