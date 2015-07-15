require 'spec_helper'

describe PCG do
  it 'has a version number' do
    expect(PCG::VERSION).not_to be nil
  end

  describe PCG do
    NUM_VALUES = 6
    before(:context) { @pcg = PCG::PCG.new }
    it 'seeds itself automagically' do
      @pcg.random
      expect(@pcg.seeded).to be true
    end

    it 'generates different values for different seeds' do
      times = 1000
      steps = 100
      seeds = times.times.map { rand(2**64-1) }.uniq
      sequences = seeds.map do |seed|
        @pcg.srandom(seed, seed)
        steps.times.map { @pcg.random }
      end
      sequences.each_cons(2) do |seq1, seq2|
        expect(seq1).not_to eq seq2
      end
    end

    it 'generates 32bit integers' do
      100_000.times do
        r = @pcg.random
        expect(r).to be >= 0
        expect(r).to be < 2**32-1
      end
    end

    it 'can be rewound' do
      times = 1000
      steps = 100
      times.times do
        seq = steps.times.map { @pcg.random }
        @pcg.advance(-steps)
        seq2 = steps.times.map { @pcg.random }
        expect(seq2).to eq seq
      end
    end

    it 'does something useful' do
      5.times do |round|
        puts "Round #{round + 1}:"

        printf "  32bit:"
        NUM_VALUES.times { printf " 0x%08x", @pcg.random }
        puts

        printf "  Again:"
        @pcg.advance(-NUM_VALUES)
        NUM_VALUES.times { printf " 0x%08x", @pcg.random }
        puts

        printf "  Coins: "
        65.times { printf "%c", @pcg.random(2) == 0 ? 'H' : 'T' }
        puts

        printf "  Rolls:"
        33.times { printf " %d", @pcg.random(6)+1 }
        puts
        puts
      end
      expect(true).not_to be false
    end
  end
end
