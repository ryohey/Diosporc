PortView = require "./port_view.coffee"
FuncView = require "./func_view.coffee"
LinkView = require "./link_view.coffee"
conf = require "./config.coffee"

class ViewController
  constructor: ->
    @view = new createjs.Container()
    @portViews = {}
    @funcViews = {}

  portViewForPort: (port) =>
    if port.funcId?
      v = @funcViews[port.funcId]
      if port.hasInput
        return v.inPortViews[port.index]
      if port.hasOutput
        return v.outPortViews[port.index]
    else
      return @portViews[port.id]

  onPortValueChanged: (e) =>
    port = e.target
    pv = @portViewForPort(port)
    pv.setValue port.getValue()

  onPortCreated: (portId, port, pos) =>
    frame = 
      x: pos.x
      y: pos.y
      width: conf.gridSize
      height: conf.gridSize
    v = new PortView frame, port
    @portViews[portId] = v
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
