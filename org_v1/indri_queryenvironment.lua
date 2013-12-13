
require("libluaindri") -- C++ wrappers

if not QueryResult then QueryResult = {} end
QueryResult.mt = { __index = QueryResult, classname = "QueryResult" }

function QueryResult.new(qe, qaptr)
   local self = {}
   setmetatable(self, QueryResult.mt)
   self.qe = qe
   self.qaptr = qaptr
   self.resultPosition = 0
   return self
end

function QueryResult:resultCount()
   return indri_qa_result_count(self.qaptr)
end

function QueryResult:nextRawEntry()
   local res = indri_qa_get_complete_result_entry(self.qe.qeptr,
												  self.qaptr,
												  self.resultPosition)
   res.position = self.resultPosition
   self.resultPosition = self.resultPosition + 1
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
   local result = QueryResult.new(self, qaptr)
   return result
end

return QueryEnvironment
