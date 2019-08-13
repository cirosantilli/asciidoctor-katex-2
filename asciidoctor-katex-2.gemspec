Gem::Specification.new do |s|
  s.add_runtime_dependency 'asciidoctor', ['= 2.0.10']
  s.add_runtime_dependency 'schmooze', ['0.2.0 ']
  s.authors     = ['Ciro Santilli']
  s.files       = ['lib/asciidoctor-katex-2.rb']
  s.homepage    = 'https://github.com/cirosantilli/asciidoctor-katex-2'
  s.license     = 'MIT'
  s.name        = 'asciidoctor-katex-2'
  s.summary     = "Asciidoctor extension to render Katex Mathematics server side to HTML fast with Schmooze. The Nirvana of Math for the web."
  s.version     = '0.0.1'
end
