require './parser'

if ARGV.length != 1
  puts "ruby vedio.rb <url>"
  exit
end

vedio_id = ARGV[0].split("/")[-1]
client_id = ARGV[1]

vedio = Vedio.new
vedio.vedio_id = vedio_id
vedio.client_id = client_id
vedio.parse
p vedio.m3u
p vedio.m3u8
