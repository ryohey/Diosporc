Port = require "./port.coffee"
Func = require "./func.coffee"
PointerFunc = require "./pointer_func.coffee"
AllocFunc = require "./alloc_func.coffee"
conf = require "./config.coffee"

# ユーザーが行う抽象的な動作 (addPortなど) の具体的な処理を行う
# viewController, machine に振り分けるのがメイン
class ActionRouter
  constructor: (viewController, machine) ->
    @viewController = viewController
    @machine = machine

  addPort: (pos) ->
    p = new Port true, true
    portId = @machine.addPort p
    @viewController.onPortCreated portId, p, pos
    p

  addFunc: (pos, func, outNum = 1, name = null) ->
    f = new Func func, outNum
    funcId = @machine.addFunc f
    @viewController.onFuncCreated funcId, f, pos, name
    f

  addPointerFunc: (pos) ->
    f = new PointerFunc @machine, @
    funcId = @machine.addFunc f
    @viewController.onFuncCreated funcId, f, pos, "pointer"
    f

  addAllocFunc: (pos) ->
    f = new AllocFunc @machine, @
    funcId = @machine.addFunc f
    @viewController.onFuncCreated funcId, f, pos, "alloc"
    f

  addLink: (fromPort, toPort) ->
    fromPort.outPorts.push toPort
    @viewController.onLinkCreated fromPort, toPort

  removeLink: (fromPort, toPort) ->
    fromPort.outPorts = _.reject fromPort.outPorts, (out) -> out.id is toPort.id
    @viewController.onLinkRemoved fromPort, toPort

  ## for debug

  # 文字列をメモリに読み込む
  addPortFromString: (pos, string) =>
    ports = (for i, char of string
      p = @addPort
        x: pos.x
        y: pos.y + (parseInt(i) + 1) * (conf.gridSize)
      p.setValue char.charCodeAt(0)
      p
    )

    id = ports[0].id

    @addFunc pos, ((_) -> id), 1, "const"


module.exports = ActionRouter
