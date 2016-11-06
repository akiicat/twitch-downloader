require "optparse"
require "./parser"


ARGV << "-h" if ARGV.empty?

options = {}
options[:download] = Array.new
OptionParser.new do |opts|
  opts.banner = <<-BANNER
    Usage:

      ruby download.rb [options] <url or vod id>

  BANNER

  opts.on("-i", "--info", "download video info") do |v|
    options[:download] << "info"
  end

  opts.on("-v", "--video", "download video file") do |v|
    options[:download] << "video"
  end

  opts.on("-c", "--chat", "download chat") do |v|
    options[:download] << "chat"
  end

  opts.on("-f", "--from [INDEX]", Numeric, "index start at" ) do |v|
    options[:index_from] = v
  end

  opts.on("-t", "--to [INDEX]", Numeric, "index end to" ) do |v|
    options[:index_to] = v
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

options[:download] << "info" << "video" << "chat" if options[:download].empty?

twitch = Parser.new
twitch.video_id   = ARGV[0].split("/")[-1]
twitch.client_id  = "fus5w6wrg143byid3xrjo44dwk6s0f7"
twitch.index_from = options[:index_from] || 0
twitch.index_to   = options[:index_to]   || Float::INFINITY

twitch.parse

puts "timestamps: #{twitch.timestamps}"
puts "total time: #{twitch.total_time} sec"

indexs = twitch.m3u8_list.keys
puts "from #{indexs.min} to #{indexs.max} next #{indexs.max + 1}"

# set path and file name
date = twitch.timestamps.strftime("%Y%m%d")
path = "#{Dir.pwd}/vod/#{date}_#{twitch.video_id}"
name = "#{date}_#{twitch.video_id}"

FileUtils.mkdir_p(path) unless File.exists?(path)

## download info
if options[:download].include?("info")
  File.open("#{path}/#{name}.m3u" , "wb") { |f| f.write(twitch.m3u_file)}
  File.open("#{path}/#{name}.m3u8", "wb") { |f| f.write(twitch.m3u8_file)}
end

## download video
if options[:download].include?("video")
  File.open("#{path}/#{name}.ts", "wb") do |f|
    video = twitch.download_video
    f.write(video.read)
  end
end

## download chat
if options[:download].include?("chat")
  file_text = File.open("#{path}/#{name}.txt", "wb")
  file_json = File.open("#{path}/#{name}.json", "wb")

  twitch.download_chat do |message|
    date    = message.time
    sender  = message.from
    text    = message.message

    # output files
    msg = "%s %s: %s\n" % [date, sender, text]
    file_text.write(msg)
    file_json.write(message.data + "\n")

    # print console
    puts "\033[94m" + date + " \033[92m" + sender + "\033[0m" + ": " + text
  end

  file_text.close
  file_json.close
end
