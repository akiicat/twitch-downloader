require "rest-client"
require "json"
require "thread"
require "./message"
require "benchmark"

class Parser
  attr_accessor :video_id
  attr_accessor :client_id
  attr_accessor :index_from
  attr_accessor :index_to
  attr_accessor :thread_num

  attr_reader :token
  attr_reader :base_url
  attr_reader :m3u_file
  attr_reader :m3u8_file
  attr_reader :m3u8_list
  attr_reader :timestamps
  attr_reader :total_time

  def initialize
    @index_from = 0
    @index_to = Float::INFINITY
    @thread_num = 8
  end

  def parse
    # twitch api access token
    @token = get_token(@video_id, @client_id)

    # m3u is video quality list
    @m3u_file = get_m3u(@video_id, @token)

    # m3u8 is video playlist
    # you can download each part from base_url + m3u8
    url = parse_m3u(@m3u_file)
    @base_url = "http://#{url[2..-3].join('/')}/chunked/"
    @m3u8_file = RestClient.get(@base_url + url[-1])
    @m3u8_list = get_m3u8_list(@m3u8_file, @index_from, @index_to)

    # video infomation
    @timestamps = get_timestamps(@m3u8_file)
    @total_time = get_total_time(@m3u8_file)

    @chat_from, @chat_to = parse_chat(@video_id)
  end

  def download_video
    @mutex = Mutex.new
    @chunk = Mutex.new

    tempfile_path = "./tmp/#{@video_id}"
    FileUtils.mkdir_p(tempfile_path) unless File.exists?(tempfile_path)

    chunkes = Hash.new
    threads = []
    list = @m3u8_list.keys
    @thread_num.times do |thread_id|
      threads[thread_id] = Thread.new do
        while(true) do
          index = nil
          @mutex.synchronize { puts "Downloading part #{index}" if index = list.shift }

          # end of list
          break unless index

          file = Tempfile.new([index.to_s, ".ts"], tempfile_path)
          download_chunkes(@base_url, @m3u8_list[index]) do |r|
            file.write(r)
          end
          @chunk.synchronize { chunkes[index] = file }
        end
      end
    end

    # join each threads
    threads.each { |t| t.join }

    # concat each part
    video = Tempfile.new([@video_id, ".ts"], tempfile_path)
    chunkes.sort.each do |k, f|
      f.open
      video.write(f.read)
      f.close
      f.unlink
    end
    video.rewind
    return video
  end

  def download_chat
    puts "from #{Time.at(@chat_from/1000)} to #{Time.at(@chat_to)}"
    message_ids = Array.new
    timestamp   = @chat_from
    while (timestamp <= @chat_to)
      # return Message Array
      messages = get_messages(timestamp)

      # prevent infinity loop
      timestamp += 1

      # check each timestamp messages data
      messages.each do |message|
        # Check the unique message ID to make sure it's not already saved.
        if not message_ids.include?(message.id)
          # If this is a new message, save the unique ID to prevent duplication later.
          message_ids.push(message.id)

          yield(message) if block_given?

          timestamp = (message.timestamp / 1000) + 10
        end
      end
    end
  end

private

  def get_token(vid, cid)
    begin
      url = "https://api.twitch.tv/api/vods/#{vid}/access_token?client_id=#{cid}"
      token = RestClient.get(url)
    rescue
      puts "FALIED please check your video id and client id:"
      puts "  Video id: #{vid}"
      puts "  Client id: #{cid}"
      exit
    end
    return token
  end

  def get_m3u(vid, tkn)
    token = JSON.parse(tkn)
    url = "https://usher.ttvnw.net/vod/#{vid}?nauthsig=#{token["sig"]}&nauth=#{token["token"]}"
    RestClient.get(url)
  end

  def parse_m3u(m3u)
    m3u.split("\n").select{|l| l.start_with? "http"}[0].split("/")
  end

  def get_timestamps(m3u8)
    time = /ID3-EQUIV-TDTG:(.+)/.match(m3u8)[1]
    DateTime.parse(time).to_time
  end

  def get_total_time(m3u8)
    /EXT-X-TWITCH-TOTAL-SECS:([\d.]+)/.match(m3u8)[1]
  end

  def get_m3u8_list(m3u8, from, to)
    hash = Hash.new
    m3u8.split("\n").reject{ |a| a.empty? or a[0] == "#" }.each do |part|
      key = part.split("-")[1].to_i
      next unless (from..to).include?(key)
      hash[key] = Array.new unless hash[key]
      hash[key].push(part)
    end
    return hash
  end

  def download_chunkes(base_url, m3u8)
    m3u8.each do |part|
      url = base_url + part
      resp = download_part(url)
      raise "[ERROR]: #{url} no response" if not resp
      yield(resp)
    end
  end

  def download_part(url)
    rty = 0
    resp = nil
    begin
      resp ||= RestClient.get(url)
    rescue
      url = toggle_muted(url) if rty == 10
      retry if (rty += 1) < 20 and sleep 1
    end
    return resp
  end

  def toggle_muted(url)
    if /-muted/ =~ (url)
      url.gsub!("-muted", "")
    else
      m = /index-\d+-\w+/.match(url)
      url.insert( m.end(0), "-muted" )
    end
    return url
  end

  def parse_chat(vid)
    url = 'https://rechat.twitch.tv/rechat-messages?start=0&video_id=v' + vid
    detail = RestClient.get(url) { |response| JSON.parse(response) }["errors"].first["detail"]
    # The response will look something like this
    # {"errors": [{
    #     "status": 400,
    #     "detail": "-18 is not between 1469624292 and 1469642422"
    # }]}
    return /between (\d+) and (\d+)/.match(detail)[1..2].map{ |i| i.to_i }
  end

  def get_messages(timestamp)
    url = "https://rechat.twitch.tv/rechat-messages?start=#{timestamp}&video_id=v#{@video_id}"

    data = RestClient.get(url) { |response| JSON.parse(response)["data"] }

    data.map!{ |d| Message.new(d) }
  end
end
