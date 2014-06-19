{WorkspaceView} = require 'atom'
Fitnesse = require '../lib/fitnesse'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Fitnesse", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('fitnesse')

  describe "when the fitnesse:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.fitnesse')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'fitnesse:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.fitnesse')).toExist()
        atom.workspaceView.trigger 'fitnesse:toggle'
        expect(atom.workspaceView.find('.fitnesse')).not.toExist()
