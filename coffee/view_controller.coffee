PortView = require "./port_view.coffee"
FuncView = require "./func_view.coffee"
LinkView = require "./link_view.coffee"
conf = require "./config.coffee"

class ViewController
  constructor: ->
    @view = new createjs.Container()
    @portViews = {}
    @funcViews = {}
    @linkViews = []

  portViewForPort: (port) =>
    if port.funcId?
      v = @funcViews[port.funcId]
      if port.canWrite
        return v.inPortViews[port.index]
      if port.canRead
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

  onFuncCreated: (funcId, func, pos, name) =>
    v = new FuncView func.inPorts, func.outPorts, name
    v.x = pos.x
    v.y = pos.y
    @funcViews[funcId] = v
    @view.addChild v

  onLinkCreated: (fromPort, toPort) =>
    fromPV = @portViewForPort fromPort
    toPV = @portViewForPort toPort
    v = new LinkView fromPV, toPV
    @view.addChild v
    @linkViews.push v

  onLinkRemoved: (fromPort, toPort) =>
    for v in @linkViews
      if v.fromPortView.port.id is fromPort.id and v.toPortView.port.id is toPort.id
        @linkViews = _.reject @linkViews, (l) -> l is v
        @view.removeChild v

module.exports = ViewController
