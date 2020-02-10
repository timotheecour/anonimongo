import tables, sequtils
import ../core/[bson, types, wire, utils]

proc find*(db: Database, coll: string,query = bson(),
  sort = bsonNull(), selector = bsonNull(), hint = bsonNull(),
  skip = 0, limit = 0, batchSize = 101, singleBatch = false, comment = "",
  maxTimeMS = 0, readConcern = bsonNull(),
  max = bsonNull(), min = bsonNull(), returnKey = false, showRecordId = false,
  tailable = false, awaitData = false, oplogReplay = false,
  noCursorTimeout = false, partial = false,
  collation = bsonNull()): Future[BsonDocument]{.async.} =
  var q = bson({ find: coll, filter: query })
  for field, val in {
    "sort": sort,
    "projection": selector,
    "hint": hint}.toTable:
    q.addOptional(field, val)
  q["skip"] = skip
  q["limit"] = limit
  q["batchSize"] = batchSize
  q.addConditional("singleBatch", singleBatch)
  if comment != "":
    q["comment"] = comment
  if maxTimeMS > 0: q["maxTimeMS"] = maxTimeMS
  for k,v in { "readConcern": readConcern,
    "max": max, "min": min }.toTable:
    q.addOptional(k, v)
  for k,v in {
    "returnKey": returnKey,
    "showRecordId": showRecordId,
    "tailable": tailable,
    "awaitData": awaitData,
    "oplogReplay": oplogReplay,
    "noCursorTimeout": noCursorTimeout,
    "allowPartialResults": partial
  }.toTable:
    q.addConditional(k, v)
  q.addOptional("collation", collation)
  result = await crudops(db, q)

proc getMore*(db: Database, cursorId: int64, collname: string, batchSize: int,
  maxTimeMS = 0): Future[BsonDocument]{.async.} =
  var q = bson({
    getMore: cursorId,
    collection: collname,
    batchSize: batchSize,
    maxTimeMS: maxTimeMS,
   })
  result = await db.crudops(q)

proc insert*(db: Database, coll: string, documents: seq[BsonDocument],
  ordered = true, wt = bsonNull(), bypass = false):
  Future[BsonDocument] {.async.} =
  var q = bson({
    insert: coll,
    documents: documents.map(toBson),
    ordered: ordered,
  })
  q.addWriteConcern(db, wt)
  q.addConditional("bypassDocumentValidation", bypass)
  result = await db.crudops(q)

proc delete*(db: Database, coll: string, deletes: seq[BsonDocument],
  ordered = true, wt = bsonNull()): Future[BsonDocument]{.async.} =
  var q = bson({
    delete: coll,
    deletes: deletes.map toBson,
    ordered: ordered,
  })
  q.addWriteConcern(db, wt)
  result = await db.crudops(q)

proc update*(db: Database, coll: string, updates: seq[BsonDocument],
  ordered = true, wt = bsonNull(), bypass = false):
  Future[BsonDocument]{.async.} =
  var q = bson({
    update: coll,
    updates: updates.map toBson,
    ordered: ordered,
  })
  q.addWriteConcern(db, wt)
  q.addConditional("bypassDocumentValidation", bypass)
  result = await db.crudops(q)

proc findAndModify*(db: Database, coll: string, query = bson(),
  sort = bsonNull(), remove = false, update = bsonNull(),
  `new` = false, fields = bsonNull(), upsert = false, bypass = false,
  wt = bsonNull(), collation = bsonNull(),
  arrayFilters: seq[BsonDocument] = @[]): Future[BsonDocument]{.async.} =
  var q = bson({
    findAndModify: coll,
    query: query,
  })
  let bopts = [("sort", sort), ("update", update), ("fields", fields)]
  let conds = [("remove", remove), ("new", `new`), ("upsert", upsert)]
  for i in 0 .. conds.high:
    let b = bopts[i]
    q.addOptional(b[0], b[1])
    let c = conds[i]
    q.addConditional(c[0], c[1])
  q.addConditional("bypassDocumentValidation", bypass)
  q.addWriteConcern(db, wt)
  q.addOptional("collation", collation)
  if arrayFilters.len > 0:
    q["arrayFilters"] = arrayFilters.map toBson
  result = await db.crudops(q)

when isMainModule:
  import ../tests/crud_test