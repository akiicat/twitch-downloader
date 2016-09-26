require 'rest-client'
require 'json'
require 'byebug'
require 'awesome_print'

class Vedio
  attr_accessor :vedio_id
  attr_accessor :client_id
  attr_accessor :token
  attr_accessor :m3u
  attr_accessor :m3u8
  attr_accessor :link
  attr_accessor :list

  def initialize(vedio_id = nil, client_id = nil)
    @vedio_id = vedio_id
    @client_id = client_id
    @list = PlayList.new
  end

  def parse
    # get token
    url    = "https://api.twitch.tv/api/vods/#{@vedio_id}/access_token?client_id=#{@client_id}"
    @token = JSON.parse(RestClient.get(url))

    # m3u
    url    = "https://usher.ttvnw.net/vod/#{@vedio_id}?nauthsig=#{@token['sig']}&nauth=#{@token['token']}"
    @m3u   = RestClient.get(url)

    # url split to array
    url    = @m3u.split("\n").select{|l| l.start_with? 'http'}[0].split('/')
    @link  = 'http://' + url[2..-3].join('/') + '/chunked/'
    @m3u8  = RestClient.get(@link + url[-1])

    # create play list array
    m3u8_list     = @m3u8.split("\n")
    m3u8_info     = m3u8_list.first(8)
    @list[0..-1]  = m3u8_list.reject{ |a| a.empty? or a[0] == '#' }

    # import play list info
    m3u8_info.each do |part|
      time = /ID3-EQUIV-TDTG:(.+)/.match(part)
      secs = /EXT-X-TWITCH-TOTAL-SECS:([\d.]+)/.match(part)

      @list.time =  DateTime.parse(time[1]).to_time if time
      @list.secs =  secs[1]                         if secs
    end
  end

  def groups
    @list.groups
  end

  def download(start = 0, stop = Float::INFINITY)
    @list.each do |part|
      index = part.split('-')[1].to_i
      next if not index.between?(start, stop)

      # index-0000007049-876T      .ts?start_offset=0&end_offset=61851
      # index-0000007049-876T-muted.ts?start_offset=0&end_offset=61851
      # index-0000004979-plLX      -0.ts
      # index-0000004979-plLX-muted-0.ts
      resp = nil

      begin
        url = link + part
        puts 'Downloading part ' + url
        resp = RestClient.get(url)
      rescue
        # 'index-xxxxxxxxxx-xxxx'.size # => 21
        url = link + part.insert(21, '-muted')
        puts 'Rescueing part ' + url
        resp = RestClient.get(url)
      end

      yield(resp)       if block_given?
    end
  end

  def download_thread(thread_num = 4)
    @list.groups.sort_by{|k,v| k}

    threads = []

    thread_num.time do |thread_id|
      puts "Create thread id: #{thread_id}"
      threads << Thread.new {

      }
    end

    threads.each { |t| t.join }
    puts "Join threads"



    hash.keys.sort.each do |part|
      if part[0] != '#' && part != ''
        next if not (part.split('-')[1].to_i >= start)

        begin
          url = link + part
          puts 'Downloading part ' + url
          resp = RestClient.get(url)
        rescue
          # 'index-0000007049-876T'.size # => 21
          # index-0000007049-876T      .ts?start_offset=0&end_offset=61851
          # index-0000007049-876T-muted.ts?start_offset=0&end_offset=61851
          # index-0000004979-plLX      -0.ts
          # index-0000004979-plLX-muted-0.ts
          url = link + part.insert(21, '-muted')
          puts 'Rescueing part ' + url
          resp = RestClient.get(url)
        end
      end
    end
  end
end


class PlayList < Array
  attr_accessor :time
  attr_accessor :secs

  def groups
    groups = Hash.new
    self.each do |part|
      key = part[0..20]
      groups[key] = Array.new unless groups[key]
      groups[key].push(part)
    end
  end
end
