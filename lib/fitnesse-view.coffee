{View} = require 'atom'

module.exports =
class FitnesseView extends View
  @content: ->
    @div class: 'fitnesse overlay from-top', =>
      @div "The Fitnesse package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "fitnesse:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "FitnesseView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
