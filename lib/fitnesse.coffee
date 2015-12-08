FitnesseView = require './fitnesse-view'
WikiFormatter = require './wiki-formatter.coffee'
{CompositeDisposable} = require 'atom'

module.exports =
  fitnesseView: null
  subscriptions: null
  needsFormatting: true

  activate: (state) ->
    @fitnesseView = new FitnesseView(state.fitnesseViewState)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'fitnesse:format': => @format()
    @subscriptions.add atom.workspace.observeTextEditors((editor) => @_editorGiven(editor))

  deactivate: ->
    @fitnesseView.destroy()
    @subscriptions.dispose()

  serialize: ->
    fitnesseViewState: @fitnesseView.serialize()

  _editorGiven: (editor) ->
    @subscriptions.add editor.onDidSave =>
      if @needsFormatting
          @format()
          editor.save()

    @subscriptions.add editor.onDidStopChanging =>
        @needsFormatting = true

  format: ->
    editor = atom.workspace.paneContainer.activePane.getActiveItem()

    formatter = new WikiFormatter()
    text = editor.getText()
    console.log("formatting text: " + text.length)
    formattedText = formatter.format(text)
    editor.setText(formattedText)
    @needsFormatting = false
