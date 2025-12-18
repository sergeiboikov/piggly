# UTF-8 encoding support for Treetop parser
# This patch ensures that Treetop parsers properly handle UTF-8 encoded strings

require 'treetop/runtime'

module Treetop
  module Runtime
    # Patch CompiledParser to handle UTF-8 strings properly
    class CompiledParser
      alias_method :original_prepare_to_parse, :prepare_to_parse
      
      def prepare_to_parse(input)
        # Ensure input is treated as UTF-8
        if input.respond_to?(:force_encoding) && input.encoding != Encoding::UTF_8
          input = input.dup.force_encoding('UTF-8')
        end
        original_prepare_to_parse(input)
      end
    end
  end
end
