# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
	width = 1000;
	height = 1000;
	color = d3.scale.category20();

	svg = d3.select("#graph")
		.append("svg")
		.attr({
			"width": "100%",
			"height": "100%"
		})
		.attr("viewbox", "0 0 " + width + " " + height)
		.attr("preserveAspectRatio", "xMidYMid meet")
		.call(d3.behavior.zoom().on("zoom", redraw))

	redraw = () ->
		svg.attr("transform", 
			"translate(" + d3.event.translate + ")" + 
			"scale(" + d3.event.scale + ")")

	d3.json("/calendars.json", (error, graph) ->
		if (error)
			return

		nodes = []
		links = []
		labelAnchors = []
		labelAnchorsLinks = []

		graph.nodes.forEach((node) -> 
			nodes.push(node)
			labelAnchors.push({node: node})
			labelAnchors.push({node: node})
		)

		nodes.forEach((node, i) ->
			labelAnchorsLinks.push({
				source: i * 2,
				target: i * 2 + 1,
				weight: 1
			})
		)

		graph.links.forEach((link) ->
			l = {
				source: link.source,
				target: link.target,
				weight: 1,
				type: link.type
			}
			links.push(l)
		)

		force = d3.layout.force()
			.charge(-3000)
			.linkDistance(50)
			.size([width, height])
			.nodes(nodes)
			.links(links)
			.gravity(.8)
			.linkStrength((d) -> (d.weight * 10))
		force.start()

		labelForce = d3.layout.force()
			.nodes(labelAnchors)
			.links(labelAnchorsLinks)
			.gravity(0)
			.linkDistance(0)
			.linkStrength(8)
			.charge(-100)
			.size([width, height])

		link = svg.selectAll(".link")
			.data(links)
			.enter()
			.append("line")
			.attr("class", "link")
			.style("stroke-width", (d) -> (Math.sqrt(d.value)))
		node = svg.selectAll(".node")
			.data(nodes)
			.enter()
			.append("circle")
			.attr("class", (d) -> (d.model))
			.attr("r", 5)
			.style("fill", (d) -> (color(d.model)))
			.call(force.drag);
		node.append("title")
			.text((d) -> (d.name))

		anchorLink = svg.selectAll(".anchorLink")
			.data(labelAnchorsLinks)

		anchorNode = svg.selectAll(".anchorNode")
			.data(labelAnchors)
			.enter()
			.append("g")
			.attr("class", ".anchorNode")
		anchorNode.append("circle")
			.attr("r", 0)
			.style("fill", "#fff")
		anchorNode.append("text").text((d, i) -> 
				if (i % 2 == 0)
					return ""
				return d.node.name
			)
			.style("fill", "#555")
			.style("font-family", "Arial")
			.style("font-size", "12px")

		updateLink = () -> 
			this.attr("x1", (d) -> (d.source.x))
			this.attr("x2", (d) -> (d.target.x))
			this.attr("y1", (d) -> (d.source.y))
			this.attr("y2", (d) -> (d.target.y))
		updateNode = () ->
			this.attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")


		force.on("tick", () ->
			labelForce.start()
		
			node.call(updateNode)
			anchorNode.each((d, i) -> 
				if (i % 2 == 0)
					d.x = d.node.x
					d.y = d.node.y
				else
					b = this.childNodes[1].getBBox()

					diffX = d.x - d.node.x
					diffY = d.y - d.node.y

					dist = Math.sqrt(diffX * diffX + diffY * diffY)

					shiftX = b.width * (diffX - dist) / (dist * 2)
					shiftX = Math.max(-b.width, Math.min(0, shiftX))
					shiftY = 5

					this.childNodes[0].setAttribute("transform", "translate(" + shiftX + "," + shiftY + ")")
			)
			anchorNode.call(updateNode)
			link.call(updateLink)
			anchorLink.call(updateLink)
		)
		resize = () ->
			width = window.innerWidth;
			height = window.innerHeight;
			svg.attr("width", width).attr("height", height)
			force.size([width, height]).resume()
			labelForce.size([width, height]).resume();
		window.addEventListener('resize', resize)
		resize()
	)