# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruck}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tom Lieber"]
  s.date = %q{2010-08-15}
  s.description = %q{      Ruck uses continuations and a simple scheduler to ensure "shreds"
      (Ruck threads) are woken at precisely the right time according
      to its virtual clock. Schedulers can map virtual time to samples
      in a WAV file, real time, time in a MIDI file, or anything else
      by overriding "sim_to" in the Shreduler class.
      
      A small library of useful unit generators and plenty of examples
      are provided. See the README or the web page for details.
}
  s.email = %q{tom@alltom.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "examples/ex01.rb",
     "examples/ex02.rb",
     "examples/ex03.rb",
     "examples/ex04.rb",
     "examples/ex05.rb",
     "examples/ex06.rb",
     "examples/space/media/Beep.wav",
     "examples/space/media/Space.png",
     "examples/space/media/Star.png",
     "examples/space/media/Starfighter.bmp",
     "examples/space/space.rb",
     "lib/ruck.rb",
     "lib/ruck/clock.rb",
     "lib/ruck/event_clock.rb",
     "lib/ruck/shred.rb",
     "lib/ruck/shreduler.rb",
     "ruck.gemspec",
     "spec/clock_spec.rb",
     "spec/shred_spec.rb",
     "spec/shreduler_spec.rb"
  ]
  s.homepage = %q{http://github.com/alltom/ruck}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{strong timing for Ruby: cooperative threads on a virtual clock}
  s.test_files = [
    "spec/clock_spec.rb",
     "spec/shred_spec.rb",
     "spec/shreduler_spec.rb",
     "examples/ex01.rb",
     "examples/ex02.rb",
     "examples/ex03.rb",
     "examples/ex04.rb",
     "examples/ex05.rb",
     "examples/ex06.rb",
     "examples/space/space.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<PriorityQueue>, [">= 0"])
    else
      s.add_dependency(%q<PriorityQueue>, [">= 0"])
    end
  else
    s.add_dependency(%q<PriorityQueue>, [">= 0"])
  end
end

