require 'digest'
require 'httparty'

module Srt
  class Downloader
    include HTTParty

    base_uri 'www.shooter.cn'

    def initialize(filename)
      @filename = filename
      @res
    end

    def download
      get_result
      write_file
    end

    def get_result
      @post_response = post
      latest_result = @post_response[-1] # latest one
      latest_result_link = latest_result["Files"][0]["Link"]

      @get_response = HTTParty.get(latest_result_link)

      # http://stackoverflow.com/questions/13393725/ruby-how-to-get-the-name-of-a-file-with-open-uri
      @download_file_name = @get_response.headers["content-disposition"].match(/filename=(\"?)(.+)\1/)[2]
    end

    def write_file
      File.open(@download_file_name, "wb") do |f| 
        f.write @get_response.parsed_response
        puts "Download : #{@download_file_name} complete!"
      end
    end

    def post
      options = { :body => {'filehash' => vhash , 'pathinfo' => @filename , 'format' => 'json', 'lang' => 'Chn'}  }
      @results = self.class.post('/api/subapi.php', options)
    end

    def vhash
      file_size = File.size?(@filename)
      offset = []

      offset[0] = 4096
      offset[1] = file_size / 3 * 2
      offset[2] = file_size / 3
      offset[3] = file_size - 8192

      arr = []
      
      offset.each do |position|
        
        vblock = IO.binread(@filename, 4096, position)  # length , offset
        md5 = Digest::MD5.hexdigest(vblock)
        arr << md5
      end


      hash = arr.join(";")

      return hash
    end
  end
end

