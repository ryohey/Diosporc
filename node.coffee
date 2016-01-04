class Node
  @Type =
    Memory: 0 
    Frame: 1
    Func: 2

  constructor: (type, indexes) ->
    @type = type
    @indexes = indexes

  @fromString: (str) ->
    s = str.split("-").map (s) -> parseInt s
    new Node s[0], _.rest(s)

  toString: ->
    "#{@type}-#{@indexes.join "-"}"

module.exports = Node