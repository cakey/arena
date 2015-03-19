class UIElement
    # Constuctor takes @name so that other unimplemented functions
    # can give meaningful messages. Elements should super this.
    constructor: (@name) ->

    # Render function required, should receive the canvas.
    render: ->
        console.log "Drawing " + @name

    # Clear function required, should receive the canvas.
    clear: ->
        console.log "Clearing " + @name

    # Update function for updating the elements logical status.
    update: ->
        console.log "Updating " + @name

module.exports = UIElement
