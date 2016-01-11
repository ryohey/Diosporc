Port = require "./port.coffee"
Func = require "./func.coffee"
Link = require "./link.coffee"

class Machine
  constructor: (width, height) ->
    @funcs = []
    @ports = []
    @links = []

  addPort: (p) =>
    @ports.push p
    p.id = @ports.length - 1

  removePort: (id) =>
    delete @ports[id]

  # returns func id
  addFunc: (func) =>
    @funcs.push func
    funcId = @funcs.length - 1
    func.id = funcId
    for p in func.inPorts.concat func.outPorts
      p.funcId = funcId
      @addPort p
    funcId

  removeFunc: (funcId) =>
    f = @funcs[funcId]
    delete @funcs[funcId]
    for p in f.inPorts.concat f.outPorts
      @removePort p.id
    @ports = _.reject @ports, (p) -> p?.funcId? and p.funcId is funcId

  findLinkByIds: (ids) =>
    _.find @links, (link) -> 
      _.intersection(link.ports.map((p) -> p.id), ids).length > 0

  addLink: (portIds) =>
    ports = portIds.map (id) => @ports[id]
    link = @findLinkByIds portIds
    if link?
      link.addPort(p) for p in ports
      console.log link.ports.map((p) -> p.id)
    else
      link = new Link ports
      @links.push link

  removeLink: (portIds) =>
    link = @findLinkByIds portIds
    return unless link?
    ports = portIds.map (id) => @ports[id]
    link.removePort(p) for p in ports

  allPorts: () =>
    funcPorts = _.flatten(@funcs.map (f) -> f.ports) 
    @ports.concat funcPorts

module.exports = Machine
