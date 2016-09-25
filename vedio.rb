require 'rest-client'
require 'json'

if ARGV.length != 1
  puts "ruby vedio.rb <url>"
  exit
end

id = ARGV[0].split("/")[-1]


url = "https://api.twitch.tv/api/vods/#{id}/access_token?client_id=fus5w6wrg143byid3xrjo44dwk6s0f7"
token = JSON.parse(RestClient.get(url))

# m3u
url = "https://usher.ttvnw.net/vod/#{id}?nauthsig=#{token["sig"]}&nauth=#{token["token"]}"
list = RestClient.get(url)

# url split to array
url         = list.split("\n").select{|l| l.start_with? "http"}[0].split("/")
link, m3u8  = 'http://' + url[2..-3].join("/") + '/chunked/', url[-1]

list = RestClient.get(link + m3u8).split("\n")

file = open("#{id}.ts", "wb")

list.each do |part|
  if part[0] != "#" && part != ""
    next if not (part.split('-')[1].to_i >= 7049)

    url = link + part
    puts 'Downloading part ' + url
    begin
      resp = RestClient.get(url)
    rescue
      url = link  + part.split('-').insert(3,'muted').join('-')

      puts 'rescueing part ' + url
      resp = RestClient.get(url)
    end
  end
end

file.close until file.nil?
