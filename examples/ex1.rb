require "../ruck"
include Ruck
include UGen

spork("main") do

  wav = WavOut.new("test.wav")
  SinOsc.new(440, 0.3) >> wav
  SinOsc.new(880, 0.3) >> wav

  wav >> blackhole

  play 1.second

  spork("beep") { beep(wav) }

  3.times { play 1.seconds }

end

def beep(wav)
  (s = SawOsc.new(440, 0.3)) >> wav
  10.times do
    play 0.1.seconds
    s.freq *= 1.2
  end
  s << wav
end

run
