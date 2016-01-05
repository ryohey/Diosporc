Memory = require "./memory.coffee"
Func = require "./func.coffee"

class Machine
  constructor: (width, height) ->
    @memory = new Memory(width, height)
    @memory.onOutputChanged = @onMemoryOutputChanged
    @funcs = []

  allPorts: () ->
    a = _.flatten(@funcs.map (f) -> f.ports) 
    b = @memory.ports
    a.concat b

  portContainsPoint: (point) ->
    _.find @allPorts(), (p) -> p.getFrame().contains point

  addFunc: (func) =>
    func.onOutputChanged = @onFuncOutputChanged
    @funcs.push func

module.exports = Machine
