Port = require "./port.coffee"
Func = require "./func.coffee"

class Machine
  constructor: (width, height) ->
    @memoryPorts = []
    @funcs = []
    @ports = []

  # returns memory id
  addMemory: (p) ->
    @memoryPorts.push p
    p.memoryId = @memoryPorts.length - 1
    @addPort p
    p.memoryId

  addPort: (p) ->
    @ports.push p
    p.id = @ports.length - 1

  # returns func id
  addFunc: (func) =>
    @funcs.push func
    funcId = @funcs.length - 1
    for p in func.ports
      p.funcId = funcId
      @addPort p
    funcId

  allPorts: () ->
    funcPorts = _.flatten(@funcs.map (f) -> f.ports) 
    @memoryPorts.concat funcPorts

module.exports = Machine
