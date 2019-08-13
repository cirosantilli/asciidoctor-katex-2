#!/usr/bin/env ruby

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'schmooze'

class KatexSchmoozer < Schmooze::Base
  dependencies katex: 'katex'

  # We need this because Schmooze cannot serialize macros
  # due to circular reference at: macros['key'].token[0].loc
  # which is a complex class.
  #
  # Also keeping it in the JavaScript is the most efficient thing we can do.
  #
  # Setting a property of katex because I don't know how to create globals from
  # a function in Node: but we already have this katex global lying around.
  method :init, <<-'EOS'
function() {
  katex.cirosantilli_macros = {
    "\\cirosantilliApiMacro": "cirosantilli \\ #1 \\ api \\ #2 \\ macro",
  };
}
EOS
  method :renderToString, <<-'EOS'
function(latex) {
  return katex.renderToString(
    latex,
    {
      macros: katex.cirosantilli_macros,
      throwOnError: true
    }
  )
}
EOS
end
$katex = KatexSchmoozer.new('.')
$katex.init

class KatexBlockProcessor < Asciidoctor::Extensions::BlockProcessor
  use_dsl
  named :katex
  on_context :literal
  parse_content_as :raw
  def process parent, reader, attrs
    html = $katex.renderToString(reader.lines.join("\n"))
    create_paragraph parent, html, attrs, subs: nil
  end
end

class KatexBlockMacroProcessor < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl
  named :katex
  def process parent, target, attrs
    html = $katex.renderToString(attrs[1])
    create_paragraph parent, html, attrs, subs: nil
  end
end

class KatexLatexmathBlockMacroProcessor < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl
  named :latexmath
  def process parent, target, attrs
    html = $katex.renderToString(attrs[1])
    create_paragraph parent, html, attrs, subs: nil
  end
end

class KatexInlineMacroProcessor < Asciidoctor::Extensions::InlineMacroProcessor
  use_dsl
  named :katex
  using_format :short
  def process parent, target, attrs
    html = $katex.renderToString(attrs[1])
    create_inline parent, :quoted, html
  end
end

class KatexDocinfoProcessor < Asciidoctor::Extensions::DocinfoProcessor
  use_dsl
  def process doc
    %{<link
  rel="stylesheet"
  href="https://cdn.jsdelivr.net/npm/katex@#{doc.attributes.fetch('katex-version', '0.10.2')}/dist/katex.min.css"
  crossorigin="anonymous"
>
<style>
.katex { font-size: #{doc.attributes.fetch('katex-font-size', '1.5em')}; }
</style>
}
  end
end

class KatexTreeprocessor < Asciidoctor::Extensions::Treeprocessor
  def process document
    unless (stem_blocks = document.find_by context: :stem).nil_or_empty?
      stem_blocks.each do |block|
        if block.style == 'latexmath'
          parent = block.parent
          image = Asciidoctor::Block.new parent, :pass, source: '<div>' + $katex.renderToString(block.content) + '</div>'
          parent.blocks[parent.blocks.index(block)] = image
        end
      end
    end
    document
  end
end

Asciidoctor::Extensions.register do
  block KatexBlockProcessor
  block_macro KatexBlockMacroProcessor
  block_macro KatexLatexmathBlockMacroProcessor
  docinfo_processor KatexDocinfoProcessor
  inline_macro KatexInlineMacroProcessor
  treeprocessor KatexTreeprocessor
end
