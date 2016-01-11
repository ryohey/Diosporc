Port = require "./port.coffee"
Func = require "./func.coffee"

class Machine
  constructor: (width, height) ->
    @funcs = []
    @ports = []

  addPort: (p) =>
    @ports.push p
    p.id = @ports.length - 1

  removePort: (id) =>
    delete @ports[id]

  # returns func id
  addFunc: (func) =>
    @funcs.push func
    funcId = @funcs.length - 1
    func.id = funcId
    for p in func.inPorts.concat func.outPorts
      p.funcId = funcId
      @addPort p
    funcId

  removeFunc: (funcId) =>
    f = @funcs[funcId]
    delete @funcs[funcId]
    for p in f.inPorts.concat f.outPorts
      @removePort p.id
    @ports = _.reject @ports, (p) -> p.funcId is funcId

  allPorts: () =>
    funcPorts = _.flatten(@funcs.map (f) -> f.ports) 
    @ports.concat funcPorts

module.exports = Machine
