$: << Dir.pwd

require 'ripper'
require '../../lib/sorcerer'

require '../../lib/sorcerer/pretty_handlers'

src = 1.upto(500).to_a.to_s
@sexp = Ripper::SexpBuilder.new(src).parse

