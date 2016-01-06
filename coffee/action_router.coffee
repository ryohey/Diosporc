class ActionRouter
  constructor: (viewController, machine) ->
    @viewController = viewController
    @machine = machine

  addMemory: (pos) ->
    memoryId = @machine.addMemory()
    @viewController.onMemoryCreated memoryId, pos

  addFunc: (pos, func) ->
    funcId = @machine.addFunc(func)
    @viewController.onFuncCreated memoryId, func.func.length, pos

module.exports = ActionRouter
