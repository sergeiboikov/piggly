module Piggly
  module VERSION
    MAJOR = 2
    MINOR = 3
    TINY  = 4

    RELEASE_DATE = "2026-02-12"
  end

  class << VERSION
    def to_s
      [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY].join(".")
    end
  end
end
