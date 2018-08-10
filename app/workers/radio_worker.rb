require 'shout'
require 'open-uri'

class RadioWorker
  include Sidekiq::Worker

  def perform(*_args)
    prev_song = nil
    s = Shout.new # ruby-shout instance
    s.mount = "/stream" # our mountpoint
    s.charset = "UTF-8"
    s.port = 35689 # the port we've specified earlier on /usr/local/etc/icecast.xml file
    s.host = 'localhost'  # hostname
    s.user = ENV['ICECAST_USER'] # credentials
    s.pass = ENV['ICECAST_PASSWORD']
    s.format = Shout::MP3 # format is MP3
    s.description = 'Geek Radio' # an arbitrary name
    s.connect


   loop do # endless loop to peform streaming

     Song.where(current: true).each do |song| # make sure all songs are not `current`
         song.toggle! :current
     end

     Song.order('created_at DESC').each do |song|
       prev_song.toggle!(:current) if prev_song # if there was a previously played song, set `current` to `false`
       song.toggle! :current # a new song is playing so it is `current` now

       open(song.track.url(public: true)) do |file| # open the public URL
          m = ShoutMetadata.new # add metadata
          m.add 'filename', song.track.original_filename # the method provided by Shrine (it stored the original filename internally)
          m.add 'title', song.title # model's attributes
          m.add 'artist', song.singer # model's attributes
          s.metadata = m

          while data = file.read(16384) # read the portions of the file
            s.send data # send portion of the file to Icecast
            s.sync
          end
        end
        prev_song = song # the song has finished playing
     end
   end # end of the endless loop

   s.disconnect # disconnect from the server
  end
end
