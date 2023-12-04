sum = 0

def sub_words(str)
  str.gsub(/one/, '1').gsub(/two/, '2').gsub(/three/, '3').gsub(/four/, '4').gsub(/five/, '5').gsub(/six/, '6').gsub(/seven/, '7').gsub(/eight/, '8').gsub(/nine/, '9')
end

lines = File.read('input/day1').split
lines.each do |line|
  sum += (line.match(/^[^\d]*(\d).*$/).captures.first + line.match(/^.*(\d).*$/).captures.first).to_i
end

puts "part 1: #{sum}"

sum = 0
lines.each do |line|
  sum += (sub_words(line.match(/(\d|one|two|three|four|five|six|seven|eight|nine).*$/).captures.first) +
          sub_words(line.match(/.*(\d|one|two|three|four|five|six|seven|eight|nine).*$/).captures.first)).to_i
end

puts "part 2: #{sum}"
