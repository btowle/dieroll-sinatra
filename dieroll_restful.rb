require 'dieroll'
require 'json'
include Dieroll

get '/dieroll/:dicenotation.json' do |notation|
  content_type :json
  notation.sub!("D","/")
  { :result => Roller.new(notation).roll! }.to_json
end

get '/dieroll/:dicenotation/report.json' do |notation|
  content_type :json
  notation.sub!("D","/")
  roller = Roller.new(notation)
  roller.roll!
  roller.report(false).to_json
end

get '/dieroll/:dicenotation/odds.json' do |notation|
  content_type :json
  notation.sub!("D","/")
  out = Roller.new(notation).odds.table(:all,
                                          [:equal],
                                          true)
  { :headers => out.shift, :rows => out }.to_json
end

get %r{/dieroll/([0-9dDlh\+-]+)/odds/([\w]+)/?([\d]*)\.json} do
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
