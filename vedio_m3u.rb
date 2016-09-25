require 'rest-client'
require 'json'
require 'byebug'

if ARGV.length != 1
  puts "Usage: download.rb <url>"
  exit
end

m3u_url  = ARGV[0]
video_id = /(\d+).m3u8/.match(m3u_url)[1]

puts "Downloading #{video_id}"

# get video_id.m3u and parse chunked url
play_list  = RestClient.get(m3u_url)
m3u8_url   = playlist.split("\n").select{|l| l.start_with? "http"}[0]

# get index-muted-5H5YM0QAEP.m3u8
vedio_list = RestClient.get(m3u8_url).split("\n")

file = File.open("#{video_id}.ts", "wb")

# http://vod064-ttvnw.akamaized.net/5fc20ba5d1_ym78305_22532383248_491181180/chunked
link = 'http://' + url.split("/")[2..-2].join("/")

vedio_list.each do |part|
  if part[0] != "#" and part != ""
    byebug
    next if not (part.split('-')[1].to_i >= 0000007049)

    url = link + '/' + part
    puts 'Downloading part ' + url
    begin
      resp = RestClient.get(url)
    rescue
      url = link + '/' + part.split('-').insert(3,'muted').join('-')

      puts 'rescueing part ' + url
      resp = RestClient.get(url)
    end

    file.write(resp.body)
  end
end

file.close until file.nil?
