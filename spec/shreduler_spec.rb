
require "ruck"

include Ruck

class MockShred
  def self.next_name
    @@next_name ||= "a"
    name = @@next_name
    @@next_name = @@next_name.succ
    name
  end
  
  def initialize(runs_until_finished = 1, shreduler = nil)
    @name = MockShred.next_name
    @finished = false
    @runs_until_finished = runs_until_finished
    @shreduler = shreduler
  end
  
  def inspect
    "MockShred<#{@name}>"
  end
  
  def call
    $runs << self
    @runs_until_finished -= 1
    @finished = (@runs_until_finished == 0)
    @shreduler.shredule(self) unless @finished || @shreduler == nil
  end
  
  def finished?
    @finished
  end
end

describe Shreduler do
  before(:each) do
    @shreduler = Shreduler.new
    $runs = []
  end
  
  context "when calling run" do
    # this is internal behavior, but should be tested as run_one is an important override point
    it "should run the shred with run_one" do
      @shreduler.should_receive(:run_one)
      @shreduler.run
    end
    
    context "with one shred" do
      it "should run it" do
        @shred = MockShred.new
        @shreduler.shredule(@shred)
        @shreduler.run
        $runs.should == [@shred]
      end
      
      it "should end up at the shred's shreduled time" do
        @shred = MockShred.new
        @shreduler.shredule(@shred, 3)
        @shreduler.run
        @shreduler.now.should == 3
      end
    end
    
    context "with multiple shreds" do
      it "should run them in order if shreduled in order" do
        @shreds = [MockShred.new, MockShred.new]
        @shreduler.shredule(@shreds[0], 0)
        @shreduler.shredule(@shreds[1], 1)
        @shreduler.run
        
        $runs.should == [@shreds[0], @shreds[1]]
      end
      
      it "should run them in order if shreduled out of order" do
        @shreds = [MockShred.new, MockShred.new]
        @shreduler.shredule(@shreds[1], 1)
        @shreduler.shredule(@shreds[0], 0)
        @shreduler.run
        
        $runs.should == [@shreds[0], @shreds[1]]
      end
      
      it "should run them until they are finished" do
        @shred = MockShred.new(5, @shreduler)
        @shreduler.shredule(@shred, 0)
        @shreduler.run
        
        $runs.should == (1..5).map { @shred }
      end
    end
  end
  
  context "when calling run_one" do
    it "should only run one shred" do
      @shreds = [MockShred.new, MockShred.new]
      @shreduler.shredule(@shreds[1], 1)
      @shreduler.shredule(@shreds[0], 0)
      @shreduler.run_one
      
      $runs.should == [@shreds[0]]
    end
    
    # fast_forward is protected, but a crucial override point, so should be tested
    it "should call fast_forward before executing the shred" do
      $runs_when_fast_forward_triggered = nil
      
      @shreds = [MockShred.new]
      @shreduler.shredule(@shreds[0], 1)
      @shreduler.should_receive(:fast_forward).with(1).and_return { $runs_when_fast_forward_triggered = $runs.dup; nil }
      @shreduler.run_one
      
      $runs_when_fast_forward_triggered.should == []
    end
  end
  
  context "when unshreduling" do
    it "should work" do
      @shred = MockShred.new
      @shreduler.shredule(@shred)
      @shreduler.unshredule(@shred)
      @shreduler.run
      $runs.should == []
    end
  end
  
  context "when convenient" do
    before(:each) do
      @shreduler = Shreduler.new
      @shreduler.make_convenient
    end
    
    context "when scheduling with spork" do
      it "should let you schedule with spork" do
        $ran = false
        spork { $ran = true }
        @shreduler.run
        $ran.should be_true
      end
    end
    
    context "when scheduling with spork_loop" do
      it "should let you schedule a looping shred with spork_loop" do
        $ran = 0
        spork_loop do
          $ran += 1
          if $ran == 3
            Shred.current.kill
          else
            Shred.yield(1)
          end
        end
        
        @shreduler.run
        $ran.should == 3
      end
      
      it "should let you specify an amount to automatically yield after before run" do
        $ran = 0
        spork_loop(1) do
          $ran += 1
          Shred.current.kill if $ran == 3
        end
        
        @shreduler.run
        $ran.should == 3
        @shreduler.now.should == 3
      end
    end
    
    context "when waiting on events" do
      it "should let you wait with Shred.wait_on" do
        $ran = false
        spork do
          Shred.wait_on(:booger)
          $ran = true
        end
        @shreduler.run
        $ran.should be_false
        @shreduler.raise_all(:booger)
        @shreduler.run
        $ran.should be_true
      end
      
      it "should let you raise an event with raise_event" do
        $ran = false
        spork do
          Shred.wait_on(:booger)
          $ran = true
        end
        @shreduler.run
        $ran.should be_false
        raise_event(:booger)
        @shreduler.run
        $ran.should be_true
      end
    end
  end
end
