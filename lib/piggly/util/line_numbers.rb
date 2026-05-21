module Piggly
  module Util

    module LineNumbers
      module_function

      def count(source)
        return 0 if source.nil? || source.empty?

        source.lines.count
      end

      # 1-based line number for a byte offset, clamped to [1, count(source)].
      def at_offset(source, offset)
        return 1 if source.nil? || source.empty?

        offset = [[offset, 0].max, source.length].min
        line = source[0...offset].count("\n") + 1
        max_line = count(source)
        [[line, 1].max, max_line].min
      end
    end

  end
end
