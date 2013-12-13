#include "indri/QueryEnvironment.hpp"
#include "indri/Repository.hpp"
#include "indri/SnippetBuilder.hpp"

extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

#include <assert.h>

using namespace indri::api;
using namespace lemur::api;

extern "C"
int indri_new_query_environment(lua_State *L)
{
  QueryEnvironment *qe = new QueryEnvironment;
  assert(qe);
  lua_pushlightuserdata(L, qe);
  return 1;
}

extern "C"
int indri_delete_query_environment(lua_State *L)
{
  QueryEnvironment *qe = (QueryEnvironment *) lua_touserdata(L, -1);
  delete qe;
  lua_pop(L, 1);
  return 0;
}

extern "C"
int indri_qe_add_index(lua_State *L)
{
  // TODO: don't crash if the index doesn't exist
  QueryEnvironment *qe = (QueryEnvironment *) lua_touserdata(L, -2);
  const char *indexPath = luaL_checkstring(L, 2);
  assert(lua_islightuserdata(L, -2));
  lua_pop(L, 2);
  qe->addIndex(indexPath);
  return 0;
}

extern "C"
int indri_qe_run_annotated_query(lua_State *L)
{
  QueryEnvironment *qe = (QueryEnvironment *) lua_touserdata(L, -3);
  const char *queryString = luaL_checkstring(L, 2);
  int resultsRequested = luaL_checkinteger(L, 3);
  QueryAnnotation *qa;
  assert(lua_islightuserdata(L, -3));
  lua_pop(L, 2);
  qa = qe->runAnnotatedQuery(queryString, resultsRequested);
  assert(qa);
  lua_pushlightuserdata(L, qa);
  return 1;
}

extern "C"
int indri_qa_get_complete_result_entry(lua_State *L)
{
  QueryEnvironment *qe = (QueryEnvironment *) lua_touserdata(L, -3);
  QueryAnnotation *qa = (QueryAnnotation *) lua_touserdata(L, -2);
  int resultNum = luaL_checkinteger(L, 3);
  assert(lua_islightuserdata(L, -2));
  assert(lua_islightuserdata(L, -3));
  lua_pop(L, 3);
  //ScoredExtentResult ser = qa->getResults()[resultNum];
  std::vector<ScoredExtentResult> extents(&qa->getResults()[resultNum],
										  &qa->getResults()[resultNum+1]);
  std::vector<ParsedDocument *> pdocs = qe->documents(extents);
  std::vector<DOCID_T> docIds(1, qa->getResults()[resultNum].document);
  std::vector<DocumentVector *> docVecs = qe->documentVectors(docIds);

  lua_newtable(L);
  lua_pushnumber(L, extents[0].score);
  lua_setfield(L, -2, "relevance");
  SnippetBuilder builder(true);
  lua_pushstring(L, builder.build(extents[0].document, pdocs[0], qa).c_str());
  lua_setfield(L, -2, "snippet");
  // lua_pushstring(L, pdocs[0]->content);
  // lua_setfield(L, -2, "content");
  // // are both content and text relevant?
  // lua_pushstring(L, pdocs[0]->text);
  // lua_setfield(L, -2, "text");

  return 1;
}

/* not sure what is correct/necessary here */
/*LUALIB_API*/ extern "C"
int luaopen_libluaindri(lua_State *L)
{
  lua_register(L, "indri_new_query_environment", indri_new_query_environment);
  lua_register(L, "indri_delete_query_environment", indri_delete_query_environment);
  lua_register(L, "indri_qe_add_index", indri_qe_add_index);
  lua_register(L, "indri_qe_run_annotated_query", indri_qe_run_annotated_query);
  lua_register(L, "indri_qa_get_complete_result_entry", indri_qa_get_complete_result_entry);
  return 0;
}
