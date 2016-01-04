{Memory, Func} = require "./io.coffee"

class Machine
  constructor: (size) ->
    @memory = new Memory(size)
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
