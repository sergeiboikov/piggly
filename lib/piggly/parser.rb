module Piggly

  #
  # Pl/pgSQL Parser, returns a tree of NodeClass values (see nodes.rb)
  #
  module Parser

    autoload :Nodes,      "piggly/parser/nodes"
    autoload :Traversal,  "piggly/parser/traversal"

    class Failure < RuntimeError; end

    class << self
      # Returns lazy parse tree (only parsed when the value is needed)
      def parse(string)
        Util::Thunk.new do
          p = parser

          begin
            # Ensure input is UTF-8 encoded
            input = string.dup.force_encoding('UTF-8')
            # Downcase input for case-insensitive parsing
            input = input.downcase
            tree = p.parse(input)
            tree or raise Failure, "#{p.failure_reason}"
          ensure
            # Restore the original string after parsing
            input.replace(string)
          end
        end
      end

      def parser_path;  "#{File.dirname(__FILE__)}/parser/parser.rb"  end
      def grammar_path; "#{File.dirname(__FILE__)}/parser/grammar.tt" end
      def nodes_path;   "#{File.dirname(__FILE__)}/parser/nodes.rb"   end

      # Returns treetop parser (recompiled as needed)
      def parser
        return @parser if @parser
        
        load_support

        # @todo: Compare with the version of treetop
        if Util::File.stale?(parser_path, grammar_path)
          # Regenerate the parser when the grammar is updated
          Treetop::Compiler::GrammarCompiler.new.compile(grammar_path, parser_path)
          # Remove existing constant before loading to avoid warnings
          Object.send(:remove_const, :PigglyParser) if Object.const_defined?(:PigglyParser)
          Object.send(:remove_const, :PigglyParserParser) if Object.const_defined?(:PigglyParserParser)
          load parser_path
          @parser = nil  # Clear cache when regenerating
        else
          require parser_path unless defined?(::PigglyParser::Parser)
        end

        @parser ||= ::PigglyParser::Parser.new
      end
    
    private

      def load_support
        require "treetop"
        require "piggly/parser/treetop_ruby19_patch"
        require "piggly/parser/nodes"
      end
    end

  end
end
