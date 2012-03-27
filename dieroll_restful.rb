require 'dieroll'
require 'json'
include Dieroll

def google_vis_script(title, cols, rows)

  col_first = cols.shift
  cols_string = "{id: '#{col_first}', label: '#{col_first}', type: 'string'}"
  cols.each do |col|
    cols_string += ",{id: '#{col}', label: '#{col}', type: 'number'}"
  end

  row_first = rows.shift
  rows_string = "{c:[{v: " + row_first.join("}, {v:") + "}]}"
  rows.each do |row|
    rows_string += ",{c:[{v: " + row.join("}, {v:") + "}]}"
  end

  script = ":plain
  <script type='text/javascript' src='https://www.google.com/jsapi'></script>
  <script type='text/javascript'>

  // Load the Visualization API and the piechart package.
  google.load('visualization', '1.0', {'packages':['corechart']});

  // Set a callback to run when the Google Visualization API is loaded.
  google.setOnLoadCallback(drawChart);

  // Callback that creates and populates a data table,
  // instantiates the pie chart, passes in the data and
  // draws it.
  function drawChart() {

  // Create the data table.
  var data = new google.visualization.DataTable({
  cols: [#{cols_string}],
  rows: [#{rows_string}]
  });

  // Set chart options
  var options = {'title':'#{title}',
  'width':400,
  'height':300,
  'isStacked':true};

  // Instantiate and draw our chart, passing in some options.
  var chart = new google.visualization.ColumnChart(document.getElementById('chart_div'));
  chart.draw(data, options);
  }
  </script>
%div{ :id => 'chart_div' }"
end

get '/dieroll/:dicenotation' do |notation|
  content_type :json
  notation.sub!("D","/")
  { :result => Roller.new(notation).roll! }.to_json
end

get '/dieroll/:dicenotation/report' do |notation|
  content_type :json
  notation.sub!("D","/")
  roller = Roller.new(notation)
  roller.roll!
  roller.report(false).to_json
end

get '/dieroll/:dicenotation/odds' do |notation|
  content_type :json
  notation.sub!("D","/")
  out = Roller.new(notation).odds.table(:all,
                                          [:equal],
                                          true)
  { :headers => out.shift, :rows => out }.to_json
end

get '/dieroll/:dicenotation/odds/chart' do |notation|
  notation.sub!("D","/")
  table = Roller.new(notation).odds.table(:all,[:less_than,:greater_than_or_equal],true)

  headers = table.shift

  haml  google_vis_script(notation, headers, table)
end

get %r{/dieroll/([0-9dDlh\+-]+)/odds/([\w]+)/?([\d]*)} do
  content_type :json

  notation = params[:captures].shift
  comparison_string = params[:captures].shift
  value = params[:captures].shift
  if value == ""
    value = :all
  else
    value = value.to_i
  end

  comparison_array = []
  comparison_string_array = comparison_string.scan(/../)
  comparison_string_array.each do |element|
    comparison_array << :less_than  if element == "lt"
    comparison_array << :less_than_or_equal  if element == "le"
    comparison_array << :equal  if element == "eq"
    comparison_array << :greater_than  if element == "gt"
    comparison_array << :greater_than_or_equal  if element == "ge"
    comparison_array << :not_equal  if element == "ne"
  end

  out =  Roller.new(notation).odds.table(value, comparison_array, true)
  headers = out.shift
  { :headers => headers, :rows => out }.to_json
end
