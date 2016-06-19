module AsCombinedMetrics
  VERSION   = "1.0.6"
  ABOUT     = "as-combined-metrics v#{VERSION} (c) #{Time.now.strftime("2015-%Y")} @innovia"

  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib]))

  autoload :Cli,      'as-combined-metrics/cli'
end