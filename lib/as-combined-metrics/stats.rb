module AsCombinedMetrics::Cli::Stats
  def check_combined_metrics(mode)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    logger.info { set_color "Checking combined metrics for #{mode}:", :white }
    
    # prepare an array to hold a true / false result for each metric
    results_array = []
    
    # checking each metric by its comparison operator for true / flase
    @combined_metrics.each do |name, values|
      # The line below checks => measure comparison operator value (a <= b) without the use of eval! (it turn the string into evalutation)
      # measure.method(b['comparison_operator']).(threshold)
      if values[:measure] == -1
        evaluation = false
      else
        evaluation = values[:measure].method(values[:comparison_operator]).(values[:threshold])
      end
      results_array << evaluation
      logger.info { set_color "Results for combined metrics for #{name} with #{values}: #{results_array.last}", :magenta }
    end

    # a short hand if statement =>  if all array elements true set combined_metric_value to 1 else to 0
    case mode 
    when :ScaleIn then
      results_array.all? ?  combined_metric_value = 1 :  combined_metric_value  = 0
    when :ScaleOut then
      results_array.any? ?  combined_metric_value = 1 :  combined_metric_value  = 0
    else
      logger.fatal { set_color "Could not find mode #{mode} - check the config file, exiting now...", :red }
      exit
    end
      
    logger.info { set_color "Combined results of #{results_array} for #{mode} is: #{combined_metric_value}", :magenta }

    return combined_metric_value
  end

  def aggregate_instances_per_as_group(metric)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"
    logger.info { set_color "Aggregating metrics accross instances for autoscale group: #{@config[:autoscale_group_name]}" , :white}
    begin

      instances = []
      instances +=  @as.describe_auto_scaling_groups({auto_scaling_group_names: [@config[:autoscale_group_name]], max_records: 1}).auto_scaling_groups.first.instances.collect {|i| i[:instance_id]} if @config.has_key?(:autoscale_group_name)
      instances += @ec2.describe_spot_fleet_instances({spot_fleet_request_id: @config[:spot_fleet_id][0]}).active_instances.collect{|i| i[:instance_id]} if @config.has_key?(:spot_fleet_id)

      logger.info { set_color "Found #{instances.size} Instances for autoscale group: #{@config['autoscale_group_name']}", :magenta }
      
      instances_aggregated_data = []
      
      metric[:dimensions] = [{name: "InstanceId"}]

      instances.each do |instance_id|
        metric[:dimensions][0][:value] = instance_id

        logger.info {"aggregated metric: #{metric}"}
        metric_result = fetch_metric(metric)

        logger.info { set_color "Metric result: #{metric_result}", :bold }

        if metric_result == -1
          instances_aggregated_data << metric_result
          break
          return # check removal of break
        else
          instances_aggregated_data << metric_result
        end
      end

      logger.info { "Instances_aggregated_data: #{instances_aggregated_data}"  }
      
      if !instances_aggregated_data.empty?
        case metric[:statistics][0].downcase
        when 'maximum'
          logger.info { set_color "Instances_aggregated_data [Maximum]: #{instances_aggregated_data.max}", :yellow }
          instances_aggregated_data.max
        when 'minimum'
          logger.info { set_color "Instances_aggregated_data [Minimum]: #{instances_aggregated_data.min}", :yellow }
          instances_aggregated_data.min
        else
          avg_array(instances_aggregated_data)
        end
      else
        # Do not scale down - we don't have all the metric data to scale down
      end
    rescue Exception => e
      logger.info { set_color "Error aggregating metrics #{e.message}", :red }
    end
  end

  def avg_array(data)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    avg = (data.inject {|sum, i| sum + i }) / data.size
    self.logger.info { set_color "Instances_aggregated_data [Average]: #{avg.round}", :white }
    avg.round 
  end

end