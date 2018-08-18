Port = require "./port.coffee"
Func = require "./func.coffee"
PointerFunc = require "./pointer_func.coffee"
AllocFunc = require "./alloc_func.coffee"
MemoryFunc = require "./memory_func.coffee"
conf = require "./config.coffee"

# ユーザーが行う抽象的な動作 (addPortなど) の具体的な処理を行う
# viewController, machine に振り分けるのがメイン
class ActionRouter
  @instance = null

  constructor: (viewController, machine) ->
    @viewController = viewController
    @machine = machine

  addPort: (pos) ->
    p = new Port true, true
    portId = @machine.addPort p
    @viewController.onPortCreated portId, p, pos
    p

  removePort: (id) ->
    @machine.removePort id
    @viewController.onPortRemoved id

  addFunc_: (func, pos, name) ->
    funcId = @machine.addFunc func
    @viewController.onFuncCreated funcId, func, pos, name
    func

  removeFunc: (id) ->
    @machine.removeFunc id
    @viewController.onFuncRemoved id

  addFunc: (pos, func, outNum = 1, name = null) ->
    f = new Func func, outNum
    @addFunc_ f, pos, name

  addPointerFunc: (pos) ->
    f = new PointerFunc @machine, @
    @addFunc_ f, pos, "pointer"

  addAllocFunc: (pos) ->
    f = new AllocFunc @machine, @
    @addFunc_ f, pos, "alloc"

  addLinks: (ids) =>
    prev = null
    for id in ids
      if prev?
        @addLink prev, id
      prev = id

  addLink: (fromPortId, toPortId) ->
    fromPort = @machine.ports[fromPortId]
    toPort = @machine.ports[toPortId]
    toPort.setValue fromPort.getValue()
    @machine.addLink [fromPortId, toPortId]
    @viewController.onLinkCreated fromPort, toPort

  removeLink: (fromPortId, toPortId) ->
    @machine.removeLink [fromPortId, toPortId]
    @viewController.onLinkRemoved fromPortId, toPortId

  ## for debug

  # 文字列をメモリに読み込む
  # [配列の先頭のアドレス、サイズ、配列...]
  addPortFromString: (pos, string) =>
    values = [0, string.length]
    values = values.concat (c.charCodeAt(0) for c in string)

    ports = (for i, v of values
      p = @addPort
        x: pos.x
        y: pos.y + parseInt(i) * conf.gridSize
      p.setValue v
      p
    )

    ports[0].setValue ports[2].id

module.exports = ActionRouter
