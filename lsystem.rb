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
    system['rules'].each do |k, v|
      @rules[k.to_sym] = case v
                         when String           # simple rule
                           LsysParser.parse(v).value
                         when Array            # stocastic rule
                           if v.inject(0) {|sum, n| sum + n[0]} != 100
                             puts "Clause % for #{k} don't add up to 100"
                             nil
                           else
                             v.collect {|clause| [clause[0], LsysParser.parse(clause[1]).value]}
                           end
                         end
    end
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

  def apply_rule(symbol)
    rule = @rules[symbol]
    return symbol unless rule     # take care of syntactic tokens. E.g. +, -
    case rule
    when String                 # simple replacement rule
      return rule
    when Array                  # stocastic rule set
      percentage = rand(100)
      rule.each do |clause|
        if percentage < clause[0]
          return clause[1]
        else
          percentage -= clause[0]
        end
      end
    end
    nil
  end

  def next_generation(state)
      new_state = []
      state.each do |expr|
        if expr.is_a? Symbol
          replacement = apply_rule(expr)
          new_state << replacement if replacement
        else                    # it's a bracketed expression (i.e. an Array)
          new_state << [next_generation(expr)]
        end
      end
      new_state.flatten(1)
  end

end
