
require("libluaindri") -- C++ wrappers

if not QueryResult then QueryResult = {} end
QueryResult.mt = { __index = QueryResult, classname = "QueryResult" }

function QueryResult.new(qe, qaptr, queryString)
   local self = {}
   setmetatable(self, QueryResult.mt)
   self.qe = qe
   self.qaptr = qaptr
   self.queryString = queryString
   self.position = 1 -- position in the result set
   self.count = indri_qa_result_count(self.qaptr)
   return self
end

function QueryResult:entry(n)
   local entry = indri_qa_get_complete_result_entry(self.qe.qeptr, self.qaptr, n - 1)
   entry.position = n
   return entry
end

function QueryResult:nextRawEntry()
   if self.position > self.count or self.position < 1 then
	  return nil
   end
   local res = self:entry(self.position)
   self.position = self.position + 1
   return res
end

function QueryResult:rawIterator(maxResults)
   return function ()
	  if maxResults > 0 then
		 maxResults = maxResults - 1
		 return self:nextRawEntry()
	  end
   end
end

if not QueryEnvironment then QueryEnvironment = {} end
QueryEnvironment.mt = { __index = QueryEnvironment, classname = "QueryEnvironment" }

function QueryEnvironment.new(...)
   local self = {}
   setmetatable(self, QueryEnvironment.mt)
   self.qeptr = indri_new_query_environment()
   self.indexes = {}
   return self
end

function QueryEnvironment:close()
   indri_delete_query_environment(self.qeptr)
end

function QueryEnvironment:addIndex(indexPath)
   table.insert(self.indexes, indexPath)
   indri_qe_add_index(self.qeptr, indexPath)
end

function QueryEnvironment:query(queryString)
   local qaptr = indri_qe_run_annotated_query(self.qeptr, queryString, 1000)
   local result = QueryResult.new(self, qaptr, queryString)
   return result
end

return QueryEnvironment
