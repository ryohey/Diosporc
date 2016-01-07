PortView = require "./port_view.coffee"
FuncView = require "./func_view.coffee"
MemoryView = require "./memory_view.coffee"
LinkView = require "./link_view.coffee"

class ViewController
  constructor: ->
    @view = new createjs.Container()
    @memoryViews = {}
    @funcViews = {}

  portViewForPort: (port) =>
    if port.memoryId?
      v = @memoryViews[port.memoryId]
      return v.portView
    else if port.funcId?
      v = @funcViews[port.funcId]
      if port.hasInput
        return v.inPortViews[port.index]
      if port.hasOutput
        return v.outPortViews[port.index]
    null

  onPortValueChanged: (e) =>
    port = e.target
    pv = @portViewForPort(port)
    pv.setValue port.getValue()

  onMemoryCreated: (memoryId, port, pos) =>
    v = new MemoryView port
    v.x = pos.x
    v.y = pos.y
    @memoryViews[memoryId] = v
    @view.addChild v

  onFuncCreated: (funcId, func, pos) =>
    v = new FuncView func.func.length, 1
    v.x = pos.x
    v.y = pos.y
    @funcViews[funcId] = v
    @view.addChild v

  onLinkCreated: (fromPort, toPort) =>
    fromPV = @portViewForPort fromPort
    toPV = @portViewForPort toPort
    v = new LinkView fromPV, toPV
    @view.addChild v

module.exports = ViewController
