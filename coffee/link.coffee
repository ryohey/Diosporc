Port = require "./port.coffee"

class Link
  constructor: (ports) ->
    @ports = []
    @addPort port for port in ports

  addPort: (port) =>
    return if _.contains @ports, port
    port.on "change", @onChange
    @ports.push port

  removePort: (port) =>
    return unless _.contains @ports, port
    port.off "change", @onChange
    @ports = _.reject @ports, (p) -> p is port

  onChange: (e) =>
    v = e.target.getValue()
    for port in @ports
      port.setValue v

module.exports = Link
