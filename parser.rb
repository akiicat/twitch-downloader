require 'rest-client'
require 'json'
require 'thread'
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

    # importinfo to PlayList @list
    m3u8_info.each do |part|
      time = /ID3-EQUIV-TDTG:(.+)/.match(part)
      secs = /EXT-X-TWITCH-TOTAL-SECS:([\d.]+)/.match(part)

      @list.time =  DateTime.parse(time[1]).to_time if time
      @list.secs =  secs[1]                         if secs
    end
  end

  def download(start = 0, stop = Float::INFINITY)
    # sequence download each part
    @list.each do |part|
      index = part.split('-')[1].to_i
      next if not index.between?(start, stop)

      # index-0000007049-876T      .ts?start_offset=0&end_offset=61851
      # index-0000007049-876T-muted.ts?start_offset=0&end_offset=61851
      # index-0000004979-plLX      -0.ts
      # index-0000004979-plLX-muted-0.ts
      # rescue if vedio is muted after download
      resp  = nil
      begin
        url  = link + part
        puts 'Downloading part ' + url
        resp = RestClient.get(url)
      rescue
        # 'index-xxxxxxxxxx-xxxx'.size # => 21
        url  = link + part.insert(21, '-muted')
        puts 'Rescueing part ' + url
        resp = RestClient.get(url)
      end

      yield(resp) if block_given?
    end
  end

  def download_thread(thread_num = 4)
    # groups: Hash key index and array each files part
    # keys  : download ordering
    # files : download temp files
    groups = @list.groups
    keys   = groups.keys.sort
    files  = Hash.new

    # mutex: take groups hash keys ordering
    # files: save downloaded files as hash tables
    @mutex = Mutex.new
    @files = Mutex.new

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
          # resp : RestClient response data
          # file : save response data to temp file
          group = groups[key]
          resp  = nil
          file  = Tempfile.new(key)

          # download each group and save as tempfiles
          group.each do |part|
            begin
              resp = RestClient.get(link + part)
            rescue
              resp = RestClient.get(link + part.insert(21, '-muted'))
            end
            file.write(resp)
          end

          # record file index and tempfile
          @files.synchronize { files[key] = file }
        end
      end
    end

    # join each threads
    threads.each { |t| t.join }

    # callblock each groups and unlink tempfile
    files.sort.each do |key, file|
      file.rewind
      yield(file.read) if block_given?
      file.close
      file.unlink
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
    return groups
  end
end
