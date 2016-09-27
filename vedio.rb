require './parser'

if ARGV.length != 1
  puts "ruby vedio.rb <url>"
  exit
end

# vedio need arg
vedio_id  = ARGV[0].split("/")[-1]
client_id = 'fus5w6wrg143byid3xrjo44dwk6s0f7'

# parse vedio
vedio = Vedio.new(vedio_id, client_id)
vedio.parse

# vedio info
date     = vedio.list.time.strftime("%Y%m%dT")
dir      = 'vedio'
tmp      = 'tmp'
filename = "#{dir}/#{date}v#{vedio_id}"

Dir.mkdir(dir) unless File.exists?(dir)
Dir.mkdir(tmp) unless File.exists?(tmp)
File.open("#{filename}.m3u" , 'wb') { |f| f.write(vedio.m3u) }
File.open("#{filename}.m3u8", 'wb') { |f| f.write(vedio.m3u8) }

# xxxxxxxxvxxxxxxxx.ts
file = File.open("#{filename}.ts", 'wb')

# download each chunked vedio by sequence
#
# vedio.download do |part|
#   file.write(part)
# end

# dowload vedio by thread and concat each files after join
# first arg is thread number by default 4
# vedio.download_thread(4) { |part| ... }
#
vedio.download_thread(4) do |part|
  file.write(part)
end

file.close
