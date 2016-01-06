Port = require "./port.coffee"
Func = require "./func.coffee"

class Machine
  constructor: (width, height) ->
    @memoryPorts = []
    @funcs = []
    @ports = []
    @onPortValueChanged = () -> null

  # returns memory id
  addMemory: ->
    p = new Port(true, true)
    @memoryPorts.push p
    p.on "change", @onChange
    p.memoryId = @memoryPorts.length - 1
    @addPort p

  addPort: (p) ->
    @ports.push p
    p.id = @ports.length - 1

  # returns func id
  addFunc: (f) =>
    func = new Func(f)
    @funcs.push func
    funcId = @funcs.length - 1
    for p in func.ports
      p.funcId = funcId
      p.on "change", @onChange
      @addPort p
    funcId

  onChange: (e) =>
    console.log e
    @onPortValueChanged e

  allPorts: () ->
    funcPorts = _.flatten(@funcs.map (f) -> f.ports) 
    @memoryPorts.concat funcPorts

module.exports = Machine
