
module Ruck

  class Shred
    attr_accessor :now
    attr_accessor :finished

    def initialize(shreduler, now, name, &block)
      @shreduler = shreduler
      @now = now
      @name = name
      @block = block
      @finished = false
    end

    def go(resume)
      @resume = resume
      begin
        @block.call self
      rescue => e
        LOG.error "#{self} exited uncleanly:\n#{e}\n#{e.backtrace}"
      end
      @finished = true
    end

    def yield(samples)
      LOG.debug "shred #{self} yielding #{samples}"
      samples = samples
      @now += samples
      callcc do |cont|
        @block = cont # save where we are
        @resume.call # jump back to shreduler
      end
      samples
    end

    def finish
      @resume.call # last save point
    end

    # shreds sort in order of position in time
    def <=>(shred)
      @now <=> shred.now
    end

    def to_s
      "<Shred: #{@name}>"
    end
  end

  class Shreduler
    attr_reader :running
    attr_reader :current_shred
    attr_reader :shreds
    attr_reader :now

    def initialize
      @shreds = []
      @now = 0
      @running = false
    end

    def spork(name = "", &shred)
      LOG.debug "Adding shred \"#{name}\" at #{@now}"
      @shreds << Shred.new(self, @now, name, &shred)
      @shred
    end

    def remove_shred(shred)
      LOG.debug "Removing shred \"#{name}\" at #{@now}"
      @shreds.delete shred
    end
    
    def next_shred
      @shreds.min # furthest behind (Shred#<=> uses Shred's current time)
    end

    # called when shreds allow time to pass
    # a convnient method to override
    def sim_to(new_now)
      @now = new_now
    end
    
    # invokes the next shred, simulates to the new VM time, then returns
    def run_one
      @current_shred = next_shred
      
      sim_to(@current_shred.now)
      
      # execute shred, saving this as the resume point
      LOG.debug "resuming shred #{@current_shred} at #{now}"
      callcc { |cont| @current_shred.go(cont) }
      LOG.debug "back to run loop"

      if @current_shred.finished
        LOG.debug "#{@current_shred} finished"
        @shreds.delete(@current_shred)
      end
    end

    # ruck main loop
    # executes all shreds and synthesizes audio
    #   until all shreds exit
    def run
      LOG.debug "shreduler starting"
      @running = true

      while @shreds.length > 0
        run_one
      end

      @running = false
    end
  end
  
  class UGenShreduler < Shreduler
    def run
      require File.join(File.dirname(__FILE__), "misc", "pcm_time_helpers")
      super
    end
    
    def sim_to(new_now)
      while @now < new_now.to_i
        BLACKHOLE.next @now
        @now += 1
      end
    end
  end
  
  class RealTimeShreduler < Shreduler
    def run
      @start_time = Time.now
      super
    end
    
    def sim_to(new_now)
      actual_now = Time.now
      simulated_now = @start_time + (new_now.to_f / SAMPLE_RATE)
      if simulated_now > actual_now
        sleep(simulated_now - actual_now)
      end
      
      @now = new_now
    end
  end

end