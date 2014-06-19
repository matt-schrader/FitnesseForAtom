FitnesseView = require './fitnesse-view'
WikiFormatter = require './wiki-formatter.coffee'

module.exports =
  fitnesseView: null

  activate: (state) ->
    @fitnesseView = new FitnesseView(state.fitnesseViewState)
    atom.workspaceView.command "fitnesse:format", => @format()

  deactivate: ->
    @fitnesseView.destroy()

  serialize: ->
    fitnesseViewState: @fitnesseView.serialize()

  format: ->
    editor = atom.workspace.activePaneItem

    formatter = new WikiFormatter()
    text = editor.getText()
    console.log("formatting text: " + text.length)
    formattedText = formatter.format(text)
    editor.setText(formattedText)
