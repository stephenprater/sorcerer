require_relative 'sorcerer/subexpression'
require_relative 'sorcerer/resource'
    
module Sorcerer
  # Generate a list of interesting subexpressions for sexp.
  def self.subexpressions(sexp)
    Sorcerer::Subexpression.new(sexp).subexpressions
  end
end
