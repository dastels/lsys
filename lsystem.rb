require 'json'
require 'citrus'

Citrus.require 'lsys_parser'

class LSystem

  def initialize(fname_or_data)
    data = fname_or_data.end_with?('.json') ? File.read(fname_or_data) : fname_or_data
    system = JSON.parse(data)
    @name = system['name']
    @axiom = system['axiom'].split('').collect {|a| a.to_sym}
    @rules = {}
    system['rules'].each {|k, v| @rules[k.to_sym] = LsysParser.parse(v).value}
    @angle = system['angle']
  end

  def name
    @name
  end

  def axiom
    @axiom
  end

  def angle
    @angle
  end

  def rules
    @rules
  end

  def rule(token)
    @rules[token]
  end

  def generation(generation_count)
    state = @axiom
    generation_count.times do |i|
      state = next_generation(state)
    end
    state
  end

  private

  def next_generation(state)
      new_state = []
      state.each do |expr|
        if expr.is_a? Symbol
          new_state << (@rules[expr] || expr)
        else
          new_state << [next_generation(expr)]
        end
      end
      new_state.flatten(1)
  end

end
