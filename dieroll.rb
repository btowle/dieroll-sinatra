require 'json'

get '/dieroll/:dicenotation' do |notation|
  status, headers, body = call env.merge("PATH_INFO" =>
                                          "/dieroll/#{notation}.json")
  roll = JSON.parse(body[0])
  haml roll["result"].to_s
end

get '/dieroll/:dicenotation/report' do |notation|
  status, headers, body = call env.merge("PATH_INFO" =>
                                          "/dieroll/#{notation}/report.json")
  roll = JSON.parse(body[0])

  br = "\n%br\n"
  output = "Roll: " + roll["string"] + br
  output += "Total: " + roll["total"].to_s + br + br
  output += "Sets:" + br
  roll["sets"].each do |set|
    output += set + br
  end
  output += br + "Mods: "
  roll["mods"].each do |mod|
    output += "+"  if mod >= 0
    output += mod.to_s + " "
  end
  haml output
end

get '/dieroll/:dicenotation/odds' do |notation|
  status, headers, body = call env.merge("PATH_INFO" =>
                                          "/dieroll/#{notation}/odds.json")
  roll = JSON.parse(body[0])
  
  output = make_table(notation, roll["headers"], roll["rows"])

  haml output
end

get '/dieroll/:dicenotation/odds/chart' do |notation|
  status, headers, body = call env.merge("PATH_INFO" =>
                                          "/dieroll/#{notation}/odds.json")
  roll = JSON.parse(body[0])

  haml google_vis_script(notation, roll["headers"], roll["rows"])
end

get %r{/dieroll/([0-9dDlh\+-]+)/odds/([\w]+)/?([\d]*)/chart} do |notation,
                                                            compare,
                                                            value|
  status, headers, body = call env.merge("PATH_INFO" =>
                                          "/dieroll/#{notation}/odds/#{compare}/#{value}.json/")
  roll = JSON.parse(body[0])

  haml google_vis_script(notation, roll["headers"], roll["rows"])
end

get %r{/dieroll/([0-9dDlh\+-]+)/odds/([\w]+)/?([\d]*)} do |notation,
                                                            compare,
                                                            value|
  status, headers, body = call env.merge("PATH_INFO" =>
                                          "/dieroll/#{notation}/odds/#{compare}/#{value}.json/")
  roll = JSON.parse(body[0])

  output = make_table(notation, roll["headers"], roll["rows"])

  haml output
end

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

def make_table(title, cols, rows)

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
  
  google.load('visualization', '1', {packages: ['table']});
  google.setOnLoadCallback(drawChart);

  function drawChart() {
  var data = new google.visualization.DataTable({
  cols: [#{cols_string}],
  rows: [#{rows_string}]
  });

  var options = {'title':'#{title}',
  'width':400,
  'height':300,
  'alternatingRowStyle':true
  };

  var chart = new google.visualization.Table(document.getElementById('chart_div'));
  chart.draw(data, options);
  }
  </script>
%div{ :id => 'chart_div' }"
end
