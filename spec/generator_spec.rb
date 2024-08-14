$LOAD_PATH.unshift File.dirname(__FILE__)+"/.."

require 'rspec'
require 'lsystem'

RSpec.describe LSystem do
  context 'with simple rules' do

    before(:example) do
      @system = LSystem.new('{"name": "Test", "tokens": "abc", "axiom": "a", "rules": {"a": "ab", "b": "ca", "c": "a"}}')
    end

    it 'returns the axiom when asked for generation 0' do
      expect(@system.generation(0)).to eq(@system.axiom)
    end

    it 'returns the correct sequence when asked for generation 1' do
      expect(@system.generation(1)).to eq([:a, :b])
    end

    it 'returns the correct sequence when asked for generation 2' do
      expect(@system.generation(2)).to eq([:a, :b, :c, :a])
    end

    it 'returns the correct sequence when asked for generation 3' do
      expect(@system.generation(3)).to eq([:a, :b, :c, :a, :a, :a, :b])
    end
  end

  context 'with bracketed rules' do

    before(:example) do
      @system = LSystem.new('{"name": "Test", "axiom": "a", "rules": {"a": "ab", "b": "[ca]", "c": "a"}}')
    end

    it 'returns the axiom when asked for generation 0' do
      expect(@system.generation(0)).to eq(@system.axiom)
    end

    it 'returns the correct sequence when asked for generation 1' do
      expect(@system.generation(1)).to eq([:a, :b])
    end

    it 'returns the correct sequence when asked for generation 2' do
      expect(@system.generation(2)).to eq([:a, :b, [:c, :a]])
    end

    it 'returns the correct sequence when asked for generation 3' do
      expect(@system.generation(3)).to eq([:a, :b, [:c, :a], [:a, :a, :b]])
    end

    it 'returns the correct sequence when asked for generation 4' do
      expect(@system.generation(4)).to eq([:a, :b, [:c, :a], [:a, :a, :b], [:a, :b, :a, :b, [:c, :a]]])
    end

  end

end
