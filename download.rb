require 'src/vedio'

if ARGV.length != 1
  puts "ruby download.rb <url>"
  exit
end

# vedio need arg
vedio_id  = ARGV[0].split("/")[-1]
client_id = ''

# parse vedio
vedio = TwitchVedio.new(vedio_id, client_id)
vedio.parse

# vedio info
date     = vedio.list.time.strftime("%Y%m%d")
dir      = "./vedio/#{date}_#{vedio_id}"

filename = "#{dir}/#{date}_#{vedio_id}"

# create files or directories if not exists
FileUtils.mkdir_p(dir) unless File.exists?(dir)
File.open("#{filename}.m3u" , 'wb') { |f| f.write(vedio.m3u) }
File.open("#{filename}.m3u8", 'wb') { |f| f.write(vedio.m3u8) }

# filename: xxxxxxxxvxxxxxxxx.ts
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
