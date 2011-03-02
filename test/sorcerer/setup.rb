$: << Dir.pwd

require 'ripper'
require '../../lib/sorcerer'

require '../../lib/sorcerer/pretty_handlers'

@sexp = Ripper::SexpBuilder.new(File.open('camping.rb').read).parse

res = Sorcerer.pretty_source(@sexp)

File.open('camping_clean.rb','w+') { |f| f.write(res) } 
