module AsCombinedMetrics::Cli::Utils
  def combined_metrics_name(mode)
    # combined the metrics name for each mode with underscores
    "#{mode}_#{@config[mode].map { |m| m[:metric_name].gsub(/\.|-/, '_')}.join('_')}"
  end
end
