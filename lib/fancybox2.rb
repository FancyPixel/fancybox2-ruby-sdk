require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
core_ext = "#{__dir__}/fancybox2/core_ext/"
loader.ignore core_ext
loader.setup

require "#{core_ext}/hash"
require "#{core_ext}/array"

module Fancybox2
end
