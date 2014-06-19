module.exports =
class WikiFormatter

  #
  #   * This is the entry point, it takes a chunk of text, splits it into lines, loops
  #   * through the lines collecting consecutive lines that are part of a table, and returns
  #   * a chunk of text with those tables it collected formatted.
  #
  format: (wikiText) ->
    @wikificationPrevention = false
    formatted = ""
    currentTable = []
    lines = wikiText.split("\n")
    line = null
    i = 0
    j = lines.length

    while i < j
      line = lines[i]
      if @isTableRow(line)
        currentTable.push line
      else
        formatted += @formatTable(currentTable)
        currentTable = []
        formatted += line + "\n"
      i++
    formatted += @formatTable(currentTable)
    formatted.slice 0, formatted.length - 1


  #
  #   * This function receives an array of strings(rows), it splits each of those strings
  #   * into an array of strings(columns), calls off to calculate what the widths
  #   * of each of those columns should be and then returns a string with each column
  #   * right/space padded based on the calculated widths.
  #
  formatTable: (table) ->
    formatted = ""
    splitRowsResult = @splitRows(table)
    rows = splitRowsResult.rows
    suffixes = splitRowsResult.suffixes
    widths = @calculateColumnWidths(rows)
    row = null
    rowIndex = 0
    numberOfRows = rows.length

    while rowIndex < numberOfRows
      row = rows[rowIndex]
      formatted += "|"
      columnIndex = 0
      numberOfColumns = row.length

      while columnIndex < numberOfColumns
        formatted += @rightPad(row[columnIndex], widths[rowIndex][columnIndex]) + "|"
        columnIndex++
      formatted += suffixes[rowIndex] + "\n"
      rowIndex++
    if @wikificationPrevention
      formatted = "!|" + formatted.substr(2)
      @wikificationPrevention = false
    formatted


  #
  #   * This is where the nastiness starts due to trying to emulate
  #   * the html rendering of colspans.
  #   *   - make a row/column matrix that contains data lengths
  #   *   - find the max widths of those columns that don't have colspans
  #   *   - update the matrix to set each non colspan column to those max widths
  #   *   - find the max widths of the colspan columns
  #   *   - increase the non colspan columns if the colspan columns lengths are greater
  #   *   - adjust colspan columns to pad out to the max length of the row
  #   *
  #   * Feel free to refator as necessary for clarity
  #
  calculateColumnWidths: (rows) ->
    widths = @getRealColumnWidths(rows)
    totalNumberOfColumns = @getNumberOfColumns(rows)
    maxWidths = @getMaxWidths(widths, totalNumberOfColumns)
    @setMaxWidthsOnNonColspanColumns widths, maxWidths
    colspanWidths = @getColspanWidth(widths, totalNumberOfColumns)
    @adjustWidthsForColspans widths, maxWidths, colspanWidths
    @adjustColspansForWidths widths, maxWidths
    widths

  isTableRow: (line) ->
    line.match /^!?\|/

  splitRows: (rows) ->
    splitRows = []
    rowSuffixes = []
    @each rows, ((row) ->
      columns = @splitRow(row)
      rowSuffixes.push columns[columns.length - 1]
      splitRows.push columns.slice(0, columns.length - 1)
      return
    ), this
    rows: splitRows
    suffixes: rowSuffixes

  splitRow: (row) ->
    columns = @trim(row).split("|")
    if not @wikificationPrevention and columns[0] is "!"
      @wikificationPrevention = true
      columns[1] = "!" + columns[1] #leave a placeholder
    columns = columns.slice(1, columns.length)
    @each columns, ((column, i) ->
      columns[i] = @trim(column)
      return
    ), this
    columns

  getRealColumnWidths: (rows) ->
    widths = []
    @each rows, ((row, rowIndex) ->
      widths.push []
      @each row, ((column, columnIndex) ->
        widths[rowIndex][columnIndex] = column.length
        return
      ), this
      return
    ), this
    widths

  getMaxWidths: (widths, totalNumberOfColumns) ->
    maxWidths = []
    row = null
    @each widths, ((row, rowIndex) ->
      @each row, ((columnWidth, columnIndex) ->
        return false  if columnIndex is (row.length - 1) and row.length < totalNumberOfColumns
        if columnIndex >= maxWidths.length
          maxWidths.push columnWidth
        else maxWidths[columnIndex] = columnWidth  if columnWidth > maxWidths[columnIndex]
        return
      ), this
      return
    ), this
    maxWidths

  getNumberOfColumns: (rows) ->
    numberOfColumns = 0
    @each rows, (row) ->
      numberOfColumns = row.length  if row.length > numberOfColumns
      return

    numberOfColumns

  getColspanWidth: (widths, totalNumberOfColumns) ->
    colspanWidths = []
    colspan = null
    colspanWidth = null
    @each widths, (row, rowIndex) ->
      if row.length < totalNumberOfColumns
        colspan = totalNumberOfColumns - row.length
        colspanWidth = row[row.length - 1]
        if colspan >= colspanWidths.length
          colspanWidths[colspan] = colspanWidth
        else colspanWidths[colspan] = colspanWidth  if not colspanWidths[colspan] or colspanWidth > colspanWidths[colspan]
      return

    colspanWidths

  setMaxWidthsOnNonColspanColumns: (widths, maxWidths) ->
    @each widths, ((row, rowIndex) ->
      @each row, ((columnWidth, columnIndex) ->
        return false  if columnIndex is (row.length - 1) and row.length < maxWidths.length
        row[columnIndex] = maxWidths[columnIndex]
        return
      ), this
      return
    ), this
    return

  getWidthOfLastNumberOfColumns: (maxWidths, numberOfColumns) ->
    width = 0
    i = 1

    while i <= numberOfColumns
      width += maxWidths[maxWidths.length - i]
      i++
    width + numberOfColumns - 1 #add in length of separators

  spreadOutExcessOverLastNumberOfColumns: (maxWidths, excess, numberOfColumns) ->
    columnToApplyExcessTo = maxWidths.length - numberOfColumns
    i = 0

    while i < excess
      maxWidths[columnToApplyExcessTo++] += 1
      columnToApplyExcessTo = maxWidths.length - numberOfColumns  if columnToApplyExcessTo is maxWidths.length
      i++
    return

  adjustWidthsForColspans: (widths, maxWidths, colspanWidths) ->
    lastNumberOfColumnsWidth = null
    excess = null
    @each colspanWidths, ((colspanWidth, index) ->
      lastNumberOfColumnsWidth = @getWidthOfLastNumberOfColumns(maxWidths, index + 1)
      if colspanWidth and colspanWidth > lastNumberOfColumnsWidth
        excess = colspanWidth - lastNumberOfColumnsWidth
        @spreadOutExcessOverLastNumberOfColumns maxWidths, excess, index + 1
        @setMaxWidthsOnNonColspanColumns widths, maxWidths
      return
    ), this
    return

  adjustColspansForWidths: (widths, maxWidths) ->
    colspan = null
    lastNumberOfColumnsWidth = null
    @each widths, ((row, rowIndex) ->
      colspan = maxWidths.length - row.length + 1
      row[row.length - 1] = @getWidthOfLastNumberOfColumns(maxWidths, colspan)  if colspan > 1
      return
    ), this
    return


  #
  #   * Utility functions
  #
  trim: (text) ->
    (text or "").replace /^\s+|\s+$/g, ""

  each: (array, callback, context) ->
    index = 0
    length = array.length
    index++  while index < length and callback.call(context, array[index], index) isnt false
    return

  rightPad: (value, length) ->
    padded = value
    i = 0
    j = length - value.length

    while i < j
      padded += " "
      i++

    return padded
