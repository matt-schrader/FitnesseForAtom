FitnesseView = require './fitnesse-view'
WikiFormatter = require './wiki-formatter.coffee'
{CompositeDisposable} = require 'atom'

module.exports =
  config:
    formatOnSave:
      description: 'Automatically format the file on save.'
      type: 'boolean'
      default: true

  fitnesseView: null
  subscriptions: null
  needsFormatting: true

  activate: (state) ->
    @fitnesseView = new FitnesseView(state.fitnesseViewState)
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', 'fitnesse:format': => @format()
    @subscriptions.add atom.workspace.observeTextEditors((editor) => @handleEvents(editor))

  deactivate: ->
    @fitnesseView.destroy()
    @subscriptions.dispose()

  serialize: ->
    fitnesseViewState: @fitnesseView.serialize()

  handleEvents: (editor) ->
    @subscriptions.add editor.onDidSave => @onSave(editor)
    @subscriptions.add editor.onDidStopChanging => @needsFormatting =  true

  # This should prevent attempting to format non text files if the plugin
  # is enabled and the user is editing a non-fitnesse file.
  isFormattableGrammar: (grammar) ->
      return grammar.scopeName == 'text.plain'

  onSave: (editor) ->
      # Only auto-format if configured
      if !atom.config.get('fitnesse.formatOnSave')
          return

      # Don't try to format non text files
      if !@isFormattableGrammar(editor.getGrammar())
          @needsFormatting = false
          return

      # Only format if there are changes
      # This also prevents an infinite loop from the save call
      if @needsFormatting
          @format(editor)
          @needsFormatting = false
          editor.save()

  # Formats the file
  format: (editor) ->
    formatter = new WikiFormatter()
    text = editor.getText()
    #console.log("formatting text: " + text.length)
    formattedText = formatter.format(text)
    editor.setText(formattedText)
