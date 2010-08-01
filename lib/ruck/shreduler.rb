
module Ruck
  class Shreduler
    attr_reader :clock
    attr_reader :event_clock
    
    def initialize
      @clock = Clock.new
      @event_clock = EventClock.new
      @clock.add_child_clock(@event_clock)
    end
    
    def now
      @clock.now
    end
    
    def shredule(shred, time = nil, clock = nil)
      (clock || @clock).schedule(shred, time)
      shred
    end
    
    def unshredule(shred)
      @clock.unschedule(shred)
    end
    
    def raise_all(event)
      event_clock.raise_all(event)
    end
    
    def run_one
      shred, relative_time = @clock.unschedule_next
      return nil unless shred
      
      fast_forward(relative_time) if relative_time > 0
      
      begin
        @current_shred = shred
        shred.call
      ensure
        @current_shred = nil
      end
      
      shred
    end
    
    def run
      loop { return unless run_one }
    end
    
    def run_until(target_time)
      return if target_time < now
      
      loop do
        shred, relative_time = next_shred
        break unless shred
        break unless now + relative_time <= target_time
        run_one
      end
      
      # I hope rounding errors are okay
      fast_forward(target_time - now)
    end
    
    # makes this the global shreduler, adding convenience methods to
    # Object and Shred to make it easier to use
    def make_convenient
      $shreduler = self
      
      Shred.module_eval { include ShredConvenienceMethods }
      Object.module_eval { include ObjectConvenienceMethods }
    end
    
    protected
      
      def fast_forward(dt)
        @clock.fast_forward(dt)
      end
      
      def next_shred
        clock.next
      end
  end
  
  module ShredConvenienceMethods
    def yield(dt, clock = nil)
      $shreduler.shredule(self, $shreduler.now + dt, clock)
      pause
    end
    
    def wait_on(event)
      $shreduler.shredule(self, event, $shreduler.event_clock)
      pause
    end
  end
  
  module ObjectConvenienceMethods
    def spork(&block)
      $shreduler.shredule(Shred.new(&block))
    end
    
    def spork_loop(&block)
      $shreduler.shredule(Ruck::Shred.new { |shred| loop { block.call(shred) } })
    end
    
    def raise_event(event)
      $shreduler.event_clock.raise_all(event)
    end
  end
end
