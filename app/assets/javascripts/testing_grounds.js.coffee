focusNode = (element, key) ->
  focusNone(element)
  d3.select(element).selectAll('g.node').classed('focused', (other) -> other.name is key)

  $('#technologies .row').each (idx, element) ->
    if $(element).data('node') is key
      $(element).addClass('focused')

focusNone = (element, key) ->
  d3.select(element).selectAll('g.node').classed(focused: false)
  $('#technologies .row').removeClass('focused')

formatDate = (date) ->
  monthNames = [
    "January", "February", "March",
    "April", "May", "June", "July",
    "August", "September", "October",
    "November", "December"
  ]

  "#{ date.getDate() } #{ monthNames[date.getMonth()] }"

# Creates the tree diagram. An experimental, top-down version of the diagram
# which lacks pan-and-zoom.
showTopology = (jsonURL, container) ->
  margin = top: 20, right: 20, bottom: 20, left: 20
  width  = 958 - margin.right - margin.left
  height = 800 - margin.top - margin.bottom

  i = 0
  duration = 0
  root = null
  ease = 'cubic-out'

  tree = d3.layout.tree().size([width, height])
  diagonal = d3.svg.diagonal().projection(({x, y}) -> [x, y])

  innerWidth  = width + margin.right + margin.left
  innerHeight = height + margin.top + margin.bottom

  # Draw the diagram area.
  svg = d3.select(container)
    .append('svg')
      .attr('viewBox', "0 0 #{innerWidth} #{innerHeight}")
      .attr('preserveAspectRatio', 'xMidYMid meet')
      .attr('pointer-events', 'all')
    .append('g')
      .attr('transform', "translate(#{margin.left}, #{margin.top})")

  $.getJSON(jsonURL).success (json) ->
    root    = json.graph
    root.x0 = 0
    root.y0 = width / 2

    collapse = (node) ->
      if node.children and node.children.length
        node._children = node.children
        node._children.forEach(collapse)
        node.children = null
      else
        node.children = null

    root.children.forEach(collapse)
    update(root)

    # Initial draw is instant (no transision); future changes should happen
    # smoothly.
    duration = 250

  update = (source) ->
    # Compute the new tree layout.
    nodes = tree.nodes(root).reverse()
    links = tree.links(nodes)

    # Normalize for fixed-depth.
    nodes.forEach (node) ->
      node.y = node.depth * 150

    # Update the nodes...
    node = svg.selectAll('g.node').data(nodes, (node) -> node.id or= i++)

    # Enter any nodes at the parent's previous position.
    nodeEnter = node.enter().append('g')
      .attr('class', 'node')
      .attr('transform', (node) -> "translate(#{source.x0},#{source.y0})")
      .on('click', click)

    nodeEnter.append('circle')
      .attr('r', 1e-6)
      .style('fill', (node) -> if node._children then 'lightsteelblue' else '#fff')

    nodeEnter.append('text')
      .style('fill-opacity', 1e-6)
      .style('font-weight', 'bold')
      .style('fill', '#444')
      .attr('x', -13)
      .attr('dy', '.38em')
      .text((node) -> node.name)
      .attr('text-anchor', (node) -> 'end')

    nodeEnter.append('text')
      .style('fill-opacity', 1e-6)
      .attr('fill', '#888')
      .attr('x', 13)
      .attr('dy', '.43em')
      .attr('text-anchor', (node) -> 'start')
      .text((node) ->
        if node.load?[0] then Math.round(node.load?[0] * 100) / 100 else '')

    # Transition nodes to their new position.
    nodeUpdate = node.transition()
      .duration(duration).ease(ease)
      .attr('transform', (node) -> "translate(#{node.x},#{node.y})")

    nodeUpdate.select('circle')
      .attr('r', 7.5)
      .attr('fill-opacity', 1)
      .attr('stroke-opacity', 1)
      .style('fill', (node) ->
        if node._children then 'lightsteelblue' else '#fff')

    nodeUpdate.selectAll('text').style('fill-opacity', 1)

    # Transition existing nodes to the parent's new position.
    nodeExit = node.exit().transition()
      .duration(duration).ease(ease)
      .attr('transform', (node) -> "translate(#{source.x},#{source.y})")
      .remove()

    nodeExit.select('circle').attr('r', 1e-6)
      .attr('fill-opacity', 1e-6)
      .attr('stroke-opacity', 1e-6)
    nodeExit.selectAll('text').style('fill-opacity', 1e-6)

    # Update the links
    link = svg.selectAll('path.link')
      .data(links, (node) -> node.target.id)

    # Enter any new links at the parent's previous position.
    link.enter().insert('path', 'g')
      .attr('class', 'link')
      .attr('d', ->
        o = x: source.x0, y: source.y0
        diagonal(source: o, target: o)
      )

    # # Transition link to their new position.
    link.transition().duration(duration).ease(ease)
      .attr('d', diagonal).attr('stroke-opacity', 1)

    # # Transition exiting nodes to the parent's new position.
    link.exit().transition()
      .duration(duration).ease(ease)
      .attr('stroke-opacity', 1e-6)
      .attr('d', ->
        o = x: source.x, y: source.y
        diagonal(source: o, target: o)
      )
      .remove()

    # Stash the old positions for transition.
    nodes.forEach (node) ->
      node.x0 = node.x
      node.y0 = node.y

  # Toggle children on click.
  click = (node) ->
    if node.children
      node._children = node.children
      node.children = null
    else
      node.children = node._children
      node._children = null

    update(node)

# Creates a line chart to represent the load of a network component over time.
# Uses nvd3 in order to create a "focus" area so the user may zoom on and view
# the curve in greater detail.
class LoadChart
  constructor: (@data, @label, @capacity) ->
    # pass

  sampledData: (week) ->
    if week
      chunkSize = Math.floor(@data.length / 52)
      zeroWeek  = week - 1

      startAt = zeroWeek * chunkSize
      endAt   = startAt + chunkSize

      window.downsampleCurve(@data.slice(startAt, endAt), chunkSize, startAt)
    else
      window.downsampleCurve(@data, 365)

  render: (intoSelector, week = 0) =>
    @renderChart(intoSelector, week)
    @drawDateSelect(intoSelector)

  renderChart: (intoSelector, week) ->
    self = this

    values = @sampledData(week)
    data   = [{ key: @label, values: values, area: true }]

    $(intoSelector).empty()

    if @capacity
      data.push({
        key: 'Capacity',
        color: 'darkred',
        values: data[0].values.map((sample) => { x: sample.x, y: @capacity })
      })

    # data.forEach (series) ->
    for series in data
      if series.values.length == 1
        for frame in [1..364]
          series.values.push(
            x: series.values[0].x + frame,
            y: series.values[0].y
          )

    for datum in data
      # Add an extra data point to make the "step-after" smoothing fit better
      # (otherwise it appears that the last frame is not present).
      last = datum.values[datum.values.length - 1]
      datum.values.push(x: last.x + 1, y: last.y)

    nv.addGraph =>
      d3.select(intoSelector).datum(data).call(@chart())

  formatDateFromFrame: (frame) =>
    multiplier =
      switch @data.length
        when 35040 then 900000
        when 8760  then 3600000
        else            -1

    if multiplier is -1
      frame
    else
      formatDate(new Date(frame * multiplier))

  drawDateSelect: (intoSelector) ->
    epoch    = new Date(0)
    msInWeek = 604800000

    dateEl = $('<select name="date-select" class="form-control" style="max-width: 300px"></select>')
    dateEl.append($('<option value="0">Whole year</option>'))

    for week in [0...52]
      startWeek = new Date(epoch.getDate() + (msInWeek * week))
      endWeek   = new Date(startWeek.getDate() + (msInWeek * week) + msInWeek - (msInWeek / 7))

      if week is 51
        endWeek = new Date(endWeek.getDate() - 1000)

      optionEl = $("<option value='#{ week + 1 }'></option>")
      optionEl.text("#{ formatDate(startWeek) } - #{ formatDate(endWeek) }")

      dateEl.append(optionEl)

    dateEl.change =>
      value = parseInt(dateEl.val(), 10)
      @renderChart(intoSelector, value)

    $(intoSelector).after(dateEl)

  chart: ->
    chart = nv.models.lineWithFocusChart()

    chart.options({
      duration:           0
      transitionDuration: 0
      interpolate:        'linear'
      forceY:             [0.0]
    })

    chart.useVoronoi(false)
    chart.lines.duration(0)
    chart.lines2.duration(0)
    chart.lines2.forceY([0.0])

    chart.lines.interpolate('step-after')

    chart.xAxis
         .tickFormat(@formatDateFromFrame)

    chart.x2Axis
         .axisLabel("Time")
         .tickFormat(@formatDateFromFrame)

    chart.yAxis
         .axisLabel("kW")
         .axisLabelDistance(35)
         .tickFormat(d3.format(',.3r'))

    chart.y2Axis
         .axisLabel("kW")
         .axisLabelDistance(35)
         .tickFormat(d3.format(',.3r'))

    chart

window.LoadChart = LoadChart

# Public: Given an array of values, downsamples the array to the given
# +outLength+. The array is split into "chunks", and the maximum value of each
# chunk is selected.
#
# For example:
#
#   downsampleCurve([2, 7, 4, 5, 2, 9], 2) # => [7, 9]
downsampleCurve = (curve, outLength, startAt = 0) ->
  curveLength = curve.length
  chunkLength = Math.floor(curveLength / outLength) or 1

  for startIndex in [0...curveLength] by chunkLength
    {
      x: startIndex + startAt
      y: d3.max(curve[startIndex...(startIndex + chunkLength)])
    }

window.downsampleCurve = downsampleCurve

createEditor = (textarea) ->
  id = textarea.attr('id')

  textarea.hide()
  textarea.data('editor', true)

  textarea.after($("""
    <div class="editor-wrap"><pre id='#{ id }_editor'></pre></div>
  """))

  editor = ace.edit("#{ id }_editor")
  editor.getSession().setValue(textarea.text())
  editor.getSession().setMode('ace/mode/yaml')
  editor.setTheme('ace/theme/github')
  editor.setHighlightActiveLine(false)
  editor.setShowPrintMargin(false)

  editor.on 'change', ->
    textarea.text(editor.getSession().getValue())

updateEtScenarioTextField = (object) ->
  parentInput = $(object).parent().find("input");
  parentInput.val($(object).val())

$(document).on "page:change", ->
  $('.testing-ground-view').each (idx, viewEl) ->
    if $('.loading', viewEl).length
      showTree($(viewEl).data('url'), viewEl)

  # Set up the network editors.
  for selector in ['textarea#testing_ground_topology_attributes_graph', 'textarea#testing_ground_technologies', 'textarea#testing_ground_technology_profile']
    textarea = $(selector)

    if textarea.length and ! textarea.data('editor')
      createEditor(textarea)

  $('#js_technologies_as_yaml, #js_technologies_as_csv').click (event) ->
    editor = $('#testing_ground_technologies_editor').parent()

    if $(event.currentTarget).is('#js_technologies_as_yaml')
      $('#testing_ground_technologies_csv').hide()
      editor.show()
    else
      $('#testing_ground_technologies_csv').show()
      editor.hide()

  for selector in ["select#testing_ground_parent_scenario_id", "select#testing_ground_scenario_id"]
    updateEtScenarioTextField(selector)
    $(selector).change (event) ->
      updateEtScenarioTextField(this)
