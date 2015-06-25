define [ 'UI/Sidebar' ], (Button) ->

 	buttons = [
 		name: 'Geometric lines', file: 'Geometriclines', icon: 'static/images/icons/inverted/links.png', favorite: true, category: 'Paths'
 	]

 	for button in buttons
 		b = new Button(button)

	return