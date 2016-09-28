require './src/vedio'
require './src/chat'

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

# file directory
date     = vedio.list.time.strftime("%Y%m%d")
dir      = "./vedio/#{date}_#{vedio_id}"
FileUtils.mkdir_p(dir) unless File.exists?(dir)

#################
# Download vod  #
#################
# save as ...
filename = "#{date}_#{vedio_id}"
fullpath = "#{dir}/#{filename}"
File.open("#{fullpath}.m3u" , 'wb') { |f| f.write(vedio.m3u) }
File.open("#{fullpath}.m3u8", 'wb') { |f| f.write(vedio.m3u8) }

# filename: xxxxxxxxvxxxxxxxx.ts
file = File.open("#{fullpath}.ts", 'wb')

# download each chunked vedio by sequence
#
# vedio.download do |part|
#   file.write(part)
# end

# dowload vedio by thread and concat each files after threads join
# first arg is thread number by default 4
#
vedio.download_thread(4) do |part|
  file.write(part)
end

file.close

#################
# Download chat #
#################
# parse chatty element
messages = Chat.new(vedio_id)

# save as ...
file     = File.open("#{fullpath}.txt", "wb")
file_all = File.open("#{fullpath}_all.txt", "wb")

messages.each do |message|
  date    = message.time
  sender  = message.from
  text    = message.message

  # output files
  file.write(date + ' ' + sender + ': ' + text + "\n")
  file_all.write(message.data + "\n")

  # print console
  puts "\033[94m" + date + " \033[92m" + sender + "\033[0m" + ": " + text
end

file.close      unless file.nil?
file_all.close  unless file_all.nil?
