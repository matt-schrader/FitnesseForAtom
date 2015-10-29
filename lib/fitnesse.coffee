FitnesseView = require './fitnesse-view'
WikiFormatter = require './wiki-formatter.coffee'
{CompositeDisposable} = require 'atom'

module.exports =
  fitnesseView: null
  subscriptions: null

  activate: (state) ->
    @fitnesseView = new FitnesseView(state.fitnesseViewState)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'fitnesse:format': => @format()

  deactivate: ->
    @fitnesseView.destroy()
    @subscriptions.dispose()

  serialize: ->
    fitnesseViewState: @fitnesseView.serialize()

  format: ->
    editor = atom.workspace.paneContainer.activePane.getActiveItem()

    formatter = new WikiFormatter()
    text = editor.getText()
    console.log("formatting text: " + text.length)
    formattedText = formatter.format(text)
    editor.setText(formattedText)
