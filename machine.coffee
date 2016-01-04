arrayRemove = (arr) ->
  arr.splice arr.indexOf(item), 1

class Machine
  constructor: (size) ->
    @memory = new Uint8Array(size)
    @links = {}
    @onMemoryUpdated = -> true

  addLink: (from, to) ->
    @links[from] ?= []
    @links[from].push to

  removeLink: (from, to) ->
    @links[from] = arrayRemove @links[from], to

  setMemory: (index, value) ->
    @memory[index] = value
    @onMemoryUpdated index, value
    if @links[index]?
      for dest in @links[index]
        setMemory dest, value

  getMemory: (index) -> 
    @memory[index]

module.exports = Machine
