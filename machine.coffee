Node = require "./node.coffee"
{Memory, Func} = require "./io.coffee"

arrayRemove = (arr) ->
  arr.splice arr.indexOf(item), 1

class Machine
  constructor: (size) ->
    @memory = new Memory(size)
    @memory.onOutputChanged = @onMemoryOutputChanged
    @links = {}
    @funcs = []
    @onMemoryUpdated = -> true

  allPorts: () ->
    a = _.flatten(@funcs.map (f) -> f.ports) 
    b = @memory.ports
    a.concat b

  portContainsPoint: (point) ->
    _.find @allPorts(), (p) -> p.getFrame().contains point

  addFunc: (func) =>
    func.onOutputChanged = @onFuncOutputChanged
    @funcs.push func

  onMemoryOutputChanged: (memory, index, value) =>
    @onMemoryUpdated index, value
    node = new Node(Node.Type.Memory, [index])
    @setNodeInput node, value

  onFuncOutputChanged: (func, index, value) =>
    node = new Node(Node.Type.Func, [@funcs.indexOf(func), index])
    @setNodeInput node, value

  setNodeInput: (node, value) ->
    key = node.toString()
    return unless @links[key]?
    for dest in @links[key]
      switch dest.type 
        when Node.Type.Memory
          @memory.setInput dest.indexes[0], value
        when Node.Type.Func
          @funcs[dest.indexes[0]].setInput dest.indexes[1], value

  addLink: (fromNode, toNode) ->
    key = fromNode.toString()
    @links[key] ?= []
    @links[key].push toNode

  removeLink: (fromNode, toNode) ->
    key = fromNode.toString()
    @links[key] = arrayRemove @links[key], toNode

module.exports = Machine
