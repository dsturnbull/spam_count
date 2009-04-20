require 'rubygems'
require 'gruff'
require 'net/imap'
require 'enumerator'

DB_FILE = "#{ENV['HOME']}/.spam_count.db"

class Fixnum
  def days
    self * 86400
  end
end

class Array
  def to_labels
    c = -1
    Hash[*self.collect { |v|
      c += 1
      [c, v]
    }.flatten].reject { |k, v| v.nil? }
  end
end

class SpamCounter
  def initialize
    login
    load_data
    get_new_data
    disconnect
    graph!
    save_data
  end

  def graph!
    #@data = [*(1..55)].map { |i| i * 1000 }
    g = Gruff::Line.new
    g.title = "Spam, #{beginning.strftime("%Y-%m-%d")} - #{Time.now.strftime("%Y-%m-%d")}"
    g.data 'Spam', @data

    g.labels = @data.to_enum(:each_with_index).collect do |d, i|
      if i % (@data.length / 4) == 0
        (beginning + i.days).strftime("%Y/%b/%d")
      else
        nil
      end
    end.to_labels

    g.write('spam.png')
    print "wrote spam.png\n"
  end

private
  def login
    @imap = Net::IMAP.new('imap.gmail.com', 993, true)
    @imap.login('dsturnbull', 'eatshit')
  end

  def disconnect
    @imap.disconnect
  end

  def get_new_data
    @imap.select('[Gmail]/All Mail')
    @data << @imap.responses['EXISTS'][0]
  end

  def load_data
    begin
      @data = Marshal.load(File.open(DB_FILE, 'r').read)
    rescue
      @data = []
    end
  end

  def save_data
    File.open(DB_FILE, 'w') { |f| f << Marshal.dump(@data) }
  end

  def beginning
    File.ctime(DB_FILE) - @data.length.days
  end
end

sc = SpamCounter.new
