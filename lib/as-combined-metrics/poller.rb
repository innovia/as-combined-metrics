module AsCombinedMetrics::Cli::Poller
  def poll(interval)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"
    @combined_metrics = {}
    
    if options[:scalein_only]
      modes = [:ScaleIn]
    elsif  options[:scaleout_only]
      modes = [:ScaleOut]
    else
      modes = [:ScaleIn, :ScaleOut]
    end

    loop do
      modes.each do |mode|
        logger.info "Polling metrics for #{mode}"
        
        @config[mode].each do |metric|
          logger.debug "Getting stats for metric #{metric}"
          @combined_metrics[metric[:metric_name]] ||= {}
          
          if metric.has_key?(:aggregate_as_group)
            logger.debug "Aggregating autoscale group metrics"
            @combined_metrics[metric[:metric_name]][:measure] = aggregate_instances_per_as_group(metric)
          else
            metric[:dimensions] = [{ name: "AutoScalingGroupName", value: @config[:autoscale_group_name]}]
            @combined_metrics[metric[:metric_name]][:measure] = fetch_metric(metric) unless @combined_metrics[metric[:metric_name]].has_key?(:measure)
          end
        
          @combined_metrics[metric[:metric_name]][:threshold] = metric[:threshold]
          @combined_metrics[metric[:metric_name]][:comparison_operator] = metric[:comparison_operator]
        end
      
        logger.info { set_color  "Combined metrics attributes for #{mode}: #{@combined_metrics}", :cyan }
        combined_metric_value = check_combined_metrics(mode)
        
        logger.info { set_color "Combined metrics value: #{combined_metric_value} => [0 = Do Not #{mode}, 1 = OK To #{mode}]" }

        publish_metric(mode, combined_metric_value)  unless options[:dryrun]
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