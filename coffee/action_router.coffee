Port = require "./port.coffee"
Func = require "./func.coffee"

class ActionRouter
  constructor: (viewController, machine) ->
    @viewController = viewController
    @machine = machine

  addPort: (pos) ->
    p = new Port true, true
    portId = @machine.addPort p
    @viewController.onPortCreated portId, p, pos

  addFunc: (pos, func, outNum = 1, name = null) ->
    f = new Func func, outNum
    funcId = @machine.addFunc f
    @viewController.onFuncCreated funcId, f, pos, name

  addLink: (fromPort, toPort) ->
    fromPort.outPorts.push toPort
    @viewController.onLinkCreated fromPort, toPort

module.exports = ActionRouter
