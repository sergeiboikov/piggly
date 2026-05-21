module Piggly
  module VERSION
    MAJOR = 2
    MINOR = 3
    TINY  = 5

    RELEASE_DATE = "2026-04-15"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
