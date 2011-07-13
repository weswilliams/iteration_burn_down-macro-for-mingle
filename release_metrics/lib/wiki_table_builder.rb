module CustomMacro

  class WikiTableBuilder
    def self.table
      return WikiTableBuilder.new
    end

    def initialize
      @rows = []
    end

    def row
      @rows << WikiRowBuilder.new(self)
      @rows.last
    end

    def done
      to_s
    end

    def to_s
      @rows.join "\n"
    end
  end

  class WikiRowBuilder
    def initialize(table_builder)
      @cols = []
      @table_builder = table_builder
    end

    def col(text)
      @cols << text
      self
    end

    def done
      @table_builder
    end

    def to_s
      "| " + @cols.join(" | ") + " |"
    end
  end

end
