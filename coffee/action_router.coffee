Port = require "./port.coffee"
Func = require "./func.coffee"

class ActionRouter
  constructor: (viewController, machine) ->
    @viewController = viewController
    @machine = machine

  addMemory: (pos) ->
    p = new Port(true, true)
    memoryId = @machine.addMemory p
    @viewController.onMemoryCreated memoryId, p, pos

  addFunc: (pos, func) ->
    func = new Func(f)
    funcId = @machine.addFunc func
    @viewController.onFuncCreated funcId, func, pos

  addLink: (fromPort, toPort) ->
    fromPort.outPorts.push toPort
    @viewController.onLinkCreated fromPort, toPort

module.exports = ActionRouter
