Port = require "./port.coffee"
Func = require "./func.coffee"
PointerFunc = require "./pointer_func.coffee"

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

  addPointerFunc: (pos) ->
    f = new PointerFunc @machine, @
    funcId = @machine.addFunc f
    @viewController.onFuncCreated funcId, f, pos, "pointer"

  addLink: (fromPort, toPort) ->
    fromPort.outPorts.push toPort
    @viewController.onLinkCreated fromPort, toPort

  removeLink: (fromPort, toPort) ->
    fromPort.outPorts = _.reject fromPort.outPorts, (out) -> out.id is toPort.id
    @viewController.onLinkRemoved fromPort, toPort

module.exports = ActionRouter
