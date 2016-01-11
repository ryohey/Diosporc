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

  addLink: (fromPort, toPort) ->
    fromPort.outPorts.push toPort
    @viewController.onLinkCreated fromPort, toPort

  removeLink: (fromPort, toPort) ->
    fromPort.outPorts = _.reject fromPort.outPorts, (out) -> out.id is toPort.id
    @viewController.onLinkRemoved fromPort.id, toPort.id

  ## for debug

  # 文字列をメモリに読み込む
  addPortFromString: (pos, string) =>
    f = @addFunc_ new MemoryFunc(v)
    , pos
    , "memory pointer"

    memories = (for i, char of string
      v = char.charCodeAt(0)
      @addFunc_ new MemoryFunc(v)
      ,
        x: pos.x
        y: pos.y + (parseInt(i) + 1) * conf.gridSize * 3
      , "memory #{v}"
    )

    f.inPorts[1].setValue f.outPorts[0].id

   # @addFunc pos, ((_) -> id), 1, "const"


module.exports = ActionRouter
