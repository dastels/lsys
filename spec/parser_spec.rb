require 'rspec'
require 'citrus'

Citrus.require '../lsys_parser'

describe LsysParser do

  it 'parses a single identifier' do
    match = LsysParser.parse('a')
    expect(match.value).to eq([:a])
  end

  it 'parses a sequence of identifiers' do
    match = LsysParser.parse('ab')
    expect(match.value).to eq([:a, :b])
  end

  it 'parses an integer' do
    match = LsysParser.parse('123')
    expect(match.value).to eq([123])
  end

  it 'doesnt need whitespace' do
    match = LsysParser.parse('ab23c')
    expect(match.value).to eq([:a, :b, 23, :c])
  end

  it 'ignores whitespace' do
    match = LsysParser.parse('a b 23 c')
    expect(match.value).to eq([:a, :b, 23, :c])
  end

  it 'supports +' do
    match = LsysParser.parse('a+b')
    expect(match.value).to eq([:a, :+, :b])
  end

  it 'supports -' do
    match = LsysParser.parse('a-b')
    expect(match.value).to eq([:a, :-, :b])
  end

  it 'supports bracketed terms' do
    match = LsysParser.parse('[a]')
    expect(match.value).to eq([[:a]])
  end

  it 'ignores spaces inside brackets' do
    match = LsysParser.parse('[ a ]')
    expect(match.value).to eq([[:a]])
  end

  it 'supports extensive bracketed terms' do
    match = LsysParser.parse('a[b+c]d')
    expect(match.value).to eq([:a, [:b, :+, :c], :d])
  end

end
