Port = require "./port.coffee"
Func = require "./func.coffee"

class ActionRouter
  constructor: (viewController, machine) ->
    @viewController = viewController
    @machine = machine

  addPort: (pos) ->
    p = new Port(true, true)
    portId = @machine.addPort p
    @viewController.onPortCreated portId, p, pos

  addFunc: (pos, func) ->
    func = new Func(f)
    funcId = @machine.addFunc func
    @viewController.onFuncCreated funcId, func, pos

  addLink: (fromPort, toPort) ->
    fromPort.outPorts.push toPort
    @viewController.onLinkCreated fromPort, toPort

module.exports = ActionRouter
