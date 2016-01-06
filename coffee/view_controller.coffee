PortView = require "./port_view.coffee"
FuncView = require "./func_view.coffee"
MemoryView = require "./memory_view.coffee"

class ViewController
  constructor: ->
    @view = new createjs.Container()
    @memoryViews = {}
    @funcViews = {}

  onPortValueChanged: (port) ->
    if port.memoryId?
      v = @memoryViews[port.memoryId]
      pv = v.portView
    else if port.funcId?
      v = @funcViews[port.funcId]
      if port.hasInput
        pv = v.inPortViews[port.index]
      if port.hasOutput
        pv = v.outPortViews[port.index]
    pv.setValue port.getValue()

  onMemoryCreated: (memoryId, pos) ->
    v = new MemoryView()
    v.x = pos.x
    v.y = pos.y
    @memoryViews[memoryId] = v
    @view.addChild v

  onFuncCreated: (funcId, inNum, pos) ->
    v = new FuncView(inNum, 1)
    v.x = pos.x
    v.y = pos.y
    @funcViews[funcId] = v
    @view.addChild v

module.exports = ViewController
