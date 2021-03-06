
module Ruck
  class Shreduler
    attr_reader :clock
    attr_reader :event_clock
    
    def initialize
      @clock = Clock.new
      @event_clock = EventClock.new
      @clock.add_child_clock(@event_clock)
    end
    
    # this Shreduler's idea of the current time
    def now
      @clock.now
    end
    
    # schedules the given Shred at the given time, on the given Clock.
    # if no time is given, it is scheduled for immediate execution.
    # if no Clock is given, it is scheduled on the default Clock.
    def shredule(shred, time = nil, clock = nil)
      (clock || @clock).schedule(shred, time)
      shred
    end
    
    # unschedules the provided Shred
    def unshredule(shred)
      @clock.unschedule(shred)
    end
    
    # unshredules every Shred
    def clear
      @clock.clear
    end
    
    # wakes up all Shreds waiting on the given event
    def raise_all(event)
      event_clock.raise_all(event)
    end
    
    # runs the next scheduled Shred, if one exists, returning that Shred
    def run_one
      shred, relative_time = @clock.unschedule_next
      return nil unless shred
      
      fast_forward(relative_time) if relative_time > 0
      invoke_shred(shred)
    end
    
    # runs until all Shreds have died, or are all waiting on events
    def run
      loop { return unless run_one }
    end
    
    # runs shreds until the given target time, then fast-forwards to
    # that time
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
      
      Shred.module_eval do
        class << self
          include ShredConvenienceMethods
        end
      end
      Object.module_eval { include ObjectConvenienceMethods }
    end
    
    protected
      
      def invoke_shred(shred)
        begin
          shred.call
        rescue Exception => e
          puts e.inspect
          puts e.backtrace
        end
        shred
      end
      
      # if you override this method, you should probably call super
      def fast_forward(dt)
        @clock.fast_forward(dt)
      end
      
      def next_shred
        clock.next
      end
  end
  
  module ShredConvenienceMethods
    # yields the given amount of time on the global Shreduler, using the
    # provided Clock if given
    def yield(dt, clock = nil)
      clock ||= $shreduler.clock
      $shreduler.shredule(Shred.current, clock.now + dt, clock)
      Shred.current.pause
    end
    
    # sleeps, waiting on the given event on the default EventClock of
    # the global Shreduler
    def wait_on(event)
      $shreduler.shredule(Shred.current, event, $shreduler.event_clock)
      Shred.current.pause
    end
  end
  
  module ObjectConvenienceMethods
    # creates a new Shred with the given block on the global Shreduler
    def spork(&block)
      $shreduler.shredule(Shred.new(&block))
    end
    
    # creates a new Shred with the given block on the global Shreduler,
    # automatically surrounded by loop { }. If the delay_or_event parameter
    # is given, a Shred.yield(delay) or Shred.wait_on(event) is inserted
    # before the call to your block.
    def spork_loop(delay_or_event = nil, clock = nil, &block)
      shred = Shred.new do
        while Shred.current.running?
          if delay_or_event
            if delay_or_event.is_a?(Numeric)
              Shred.yield(delay_or_event, clock)
            else
              Shred.wait_on(delay_or_event)
            end
          end
          
          block.call
        end
      end
      $shreduler.shredule(shred)
    end
    
    # raises an event on the default EventClock of the global Shreduler.
    def raise_event(event)
      $shreduler.event_clock.raise_all(event)
    end
  end
end
