module AsCombinedMetrics::Cli::Poller
  def poll(interval)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"
   
    if options[:scalein_only]
      modes = [:ScaleIn]
    elsif  options[:scaleout_only]
      modes = [:ScaleOut]
    else
      modes = [:ScaleIn, :ScaleOut]
    end

    loop do
      @combined_metrics = {}
      modes.each do |mode|
        @config[:autoscale_group_name].each do |autoscale_group|
        logger.info "Polling metrics for #{autoscale_group} AutoScale Group on #{mode}"

          @config[mode].each do |metric|
            logger.debug "Getting stats for #{autoscale_group} AutoScale Group on metric #{metric}"
            @combined_metrics[metric[:metric_name]] ||= {}

            if metric.has_key?(:aggregate_as_group)
              logger.debug "Aggregating autoscale group metrics"
              @combined_metrics[metric[:metric_name]][:measure] = aggregate_instances_per_as_group(metric)
            else
              metric[:dimensions] = [{ name: "AutoScalingGroupName", value: autoscale_group}]
              @combined_metrics[metric[:metric_name]][:measure] = fetch_metric(metric) unless @combined_metrics[metric[:metric_name]].has_key?(:measure)
            end

            @combined_metrics[metric[:metric_name]][:threshold] = metric[:threshold]
            @combined_metrics[metric[:metric_name]][:comparison_operator] = metric[:comparison_operator]
          end

          logger.info { set_color  "Combined metrics attributes for #{autoscale_group} AutoScale Group on #{mode}: #{@combined_metrics}", :cyan }
          combined_metric_value = check_combined_metrics(mode)

          logger.info { set_color "Combined metrics value for #{autoscale_group} AutoScale Group: #{combined_metric_value} => [0 = Do Not #{mode}, 1 = OK To #{mode}]", :yellow, :bold }

          publish_metric(mode, autoscale_group, combined_metric_value)
        end
      end

        if options[:once]
          logger.info { set_color "Ran Once - Exiting now..." }
          exit 0
        else
          logger.info { set_color "Next metrics check in #{interval} seconds..." }
          sleep interval
        end
     end
  end
end