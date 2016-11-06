require "rest-client"
require "json"
require "thread"

class Parser
  attr_accessor :video_id
  attr_accessor :client_id
  attr_accessor :index_from
  attr_accessor :index_to

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

    @m3u8_list.keys.sort

  end

private

  def get_token(vid, cid)
    begin
      p url = "https://api.twitch.tv/api/vods/#{vid}/access_token?client_id=#{cid}"
      token = RestClient.get(url)
    rescue => e
      p e
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
    m3u.split("\n").select{|l| l.start_with? 'http'}[0].split('/')
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
    m3u8.split("\n").reject{ |a| a.empty? or a[0] == '#' }.each do |part|
      key = part.split("-")[1].to_i
      next unless (from..to).include?(key)
      hash[key] = Array.new unless hash[key]
      hash[key].push(part)
    end
    return hash
  end
end

twitch = Parser.new
twitch.video_id = "91843682"
twitch.client_id = "fus5w6wrg143byid3xrjo44dwk6s0f7"
twitch.index_from = 0
twitch.index_to = 200
twitch.parse

__END__



def download_thread(thread_num = 4, start = 0, stop = 9999999999)


  # @mutex: take groups hash keys ordering and print console
  # @files: save downloaded files as hash tables
  @mutex = Mutex.new
  @files = Mutex.new

  # setting temp file directory
  tmpdir = "./tmp/#{@video_id}"
  FileUtils.mkdir_p(tmpdir) unless File.exists?(tmpdir)

  # download by thread default 4
  threads = []
  thread_num.times do |thread_id|

    # create and save each thread and join later
    threads[thread_id] = Thread.new do
      while(true) do
        key = nil

        # take groups hash keys ordering and print console
        @mutex.synchronize { puts "Downloading part #{key}" if key = keys.shift }

        # break if end of keys array
        break if not key

        # group: take files group from groups
        # file : save response data to temp file
        # rty  : retry fetch ts files times
        group   = groups[key]
        file    = Tempfile.new([key, '.ts'], tmpdir)
        rty     = 0

        # download each group and save as tempfiles
        group.each do |ts|
          # part : duplicate a new one
          # resp : RestClient response data
          part  = ts
          resp  = nil

          # download and retry 3 times
          url   = link + part
          resp  = download_part(url) if not resp

          # toggle muted
          url   = toggle_muted(url)
          resp  = download_part(url) if not resp

          # error handling
          if not resp and (rty += 1) < 3
            @mutex.synchronize { puts '[ERROR]: ' + "#{resp} " + url }
            redo
          end
          rty = 0
          @mutex.synchronize { puts '[ERROR]: ' + url } if not resp
          raise 'resp no rsp' if not resp

          file.write(resp)
        end

        # record file index and tempfile
        @files.synchronize { files[key] = file }

        # close tempfile and concat later
        file.close
      end
    end
  end

  # join each threads
  threads.each { |t| t.join }

  # callblock each groups and unlink tempfile
  files.sort.each do |key, file|
    file.open
    yield(file.read) if block_given?
    file.close
    file.unlink
  end
end
