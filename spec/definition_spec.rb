require 'rspec'
require_relative '../lsystem'

RSpec.describe LSystem do
  before(:all) do
    @system = LSystem.new('{"name": "Test", "axiom": "a", "rules": {"a": "ab", "b": "ca", "c": "a"}, "angle": 90}')
  end

  it 'extracts the name' do
    expect(@system.name).to eq('Test')
  end

  it 'extracts the axiom' do
    expect(@system.axiom).to eq([:a])
  end

  it 'extracts the angle' do
    expect(@system.angle).to eq(90)
  end

  it 'extracts the correct number of rules' do
    expect(@system.rules.count).to eq(3)
  end

  it 'extracts rules' do
    expect(@system.rules[:a]).to eq([:a, :b])
    expect(@system.rules[:b]).to eq([:c, :a])
    expect(@system.rules[:c]).to eq([:a])
  end


  it 'can fetch specific rules' do
    expect(@system.rule(:a)).to eq([:a, :b])
    expect(@system.rule(:b)).to eq([:c, :a])
    expect(@system.rule(:c)).to eq([:a])
  end
end
