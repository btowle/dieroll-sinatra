require 'dieroll'
require 'json'
require 'gchart'
include Dieroll

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
  table = Roller.new(notation).odds.table(:all,[:equal],true)

  headers = table.shift

  possibilities = []
  probabilities = []

  min = 100.00
  max = 0.00

  table.each do |row|
    possibilities << row.shift
    probability = (row.shift*100).round(2)
    max = probability  if probability > max
    min = probability  if probability < min
    probabilities << probability
  end

  num_possibilties = possibilities.last - possibilities.first
  chart = Gchart.bar(:size => '200x400',
                      :title => notation,
                      :data => probabilities.reverse,
                      :axis_with_labels => 'x,y',
                      :axis_labels => [[0,
                                        max/4,
                                        max/2,
                                        (max*3/4).round(2),
                                        max], possibilities],
                      :bar_width_and_spacing =>
                        [200/num_possibilties],
                      :max_value => max,
                      :orientation => 'horizontal'
                      )
  "<img src=#{chart}>"
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
