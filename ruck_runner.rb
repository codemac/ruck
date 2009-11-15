
require "ruck"

# stuff accessible in a shred
module ShredLocal

  def blackhole
    BLACKHOLE
  end
  
  def now
    SHREDULER.now
  end

  def spork(name = "unnamed", &shred)
    SHREDULER.spork(name, &shred)
  end

  def play(samples)
    SHREDULER.current_shred.yield(samples)
  end

  def finish
    shred = SHREDULER.current_shred
    SHREDULER.remove_shred shred
    shred.finish
  end

end


SAMPLE_RATE = 22050
SHREDULER = Ruck::RealTimeShreduler.new
BLACKHOLE = Ruck::InChannel.new

filenames = ARGV
filenames.each do |filename|
  unless File.readable?(filename)
    LOG.fatal "Cannot read file #{filename}"
    exit
  end
end

filenames.each do |filename|
  SHREDULER.spork(filename) do
    include ShredLocal
    include Ruck::Generators
    require filename
  end
end
SHREDULER.run