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

    # put ASG and SpotFleet ID into one array we can iterate over
    groups = []
    groups += @config[:autoscale_group_name].collect do |asg| { type: 'AutoScalingGroupName', name: asg } end if @config[:autoscale_group_name].respond_to?('collect')
    groups += @config[:spot_fleet_id].collect do |sfid| { type: 'FleetRequestId', name: sfid } end if @config[:spot_fleet_id].respond_to?('collect')

    loop do
      @combined_metrics = {}
              
      modes.each do |mode|
        groups.each do |group|
          logger.info "Polling metrics for #{group[:name]} #{group[:type]} on #{mode}"

          @config[mode].each do |metric|
            logger.debug "Getting stats for #{group[:name]} #{group[:type]} on metric #{metric}"
            @combined_metrics[metric[:metric_name]] ||= {}

            if metric.has_key?(:aggregate_as_group)
              logger.debug "Aggregating autoscale group metrics"
              @combined_metrics[metric[:metric_name]][:measure] = aggregate_instances_per_as_group(metric)
            else
              metric[:dimensions] = [{ name: group[:type], value: group[:name]}]
              @combined_metrics[metric[:metric_name]][:measure] = fetch_metric(metric) unless @combined_metrics[metric[:metric_name]].has_key?(:measure)
            end

            @combined_metrics[metric[:metric_name]][:threshold] = metric[:threshold]
            @combined_metrics[metric[:metric_name]][:comparison_operator] = metric[:comparison_operator]
          end

          logger.info { set_color  "Combined metrics attributes for #{group[:name]} #{group[:type]} on #{mode}: #{@combined_metrics}", :cyan }
          combined_metric_value = check_combined_metrics(mode)

          logger.info { set_color "Combined metrics value for #{group[:name]} #{group[:type]}: #{combined_metric_value} => [0 = Do Not #{mode}, 1 = OK To #{mode}]", :yellow, :bold }

          publish_metric(mode, group[:name], combined_metric_value)
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