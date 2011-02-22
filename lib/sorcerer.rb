module Sorcerer
  # Generate the source code for teh given Ripper S-Expression.
  def self.source(sexp, debug=false)
    Sorcerer::Resource.new(sexp, debug).source
  end

  def self.pretty_source(sexp, debug=false)
    Sorcerer::Resource.new(sexp,debug).pretty_source
  end

  # Generate a list of interesting subexpressions for sexp.
  def self.subexpressions(sexp)
    Sorcerer::Subexpression.new(sexp).subexpressions
  end
end

require_relative 'sorcerer/resource'
require_relative 'sorcerer/subexpression'

