module AsCombinedMetrics::Cli::CloudWatch
  
  def set_default_options(hash, member)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"
    if hash[member] && !hash[member].nil?
      default = hash[member]
    else
      default =  self.config["default_options"][member.to_s.gsub("_", "-")] if !self.config["default_options"][member.to_s.gsub("_", "-")].nil?
    end
  end

  def fetch_metric(metric)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    # Read from CloudWatch  
    data = {
        :start_time => (Time.now.utc - options[:period]).iso8601,
        :end_time   => (Time.now.utc).iso8601,
        :period     => options[:period]
    }

    # # removing the keys that are not used in fetch metric 
    metric = metric.merge(data).reject { |k,v| [:comparison_operator, :threshold, :aggregate_as_group].include? k }
    
    logger.info { set_color "Polling data for metric: #{metric[:metric_name]}", :white }
    logger.info { "Metric info: #{metric}" }
    
    begin
      result = @cw.get_metric_statistics(metric).to_hash
    rescue Exception => e
      logger.error { set_color "An error occured #{e}, SDK will retry", :red }
    end

    if result[:datapoints].empty?
      logger.info { set_color "No datapoints found for #{metric[:metric_name]} - Will publish a value of 0 (Don't DownScale) to CloudWatch", :red }
      logger.info { "Result: #{result}" }
      return -1
    else
      datapoint = result[:datapoints][0][metric[:statistics][0].downcase.to_sym]
      logger.info { set_color "Result: #{datapoint} #{result[:datapoints][0][:unit]}", :white }
      datapoint
    end
  end

  def publish_metric(mode, combined_metric_value)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    cw_options = {
      namespace: 'combined_metrics',
      metric_data: [
        metric_name: combined_metrics_name(mode),
         dimensions: [{
          name: 'AutoScalingGroupName',
          value: @config[:autoscale_group_name]
        }],
        value: combined_metric_value,
        unit: 'None'
      ]
    }
    logger.info { set_color "Options to be sent to cloudwatch: #{cw_options}", :white }
    
    begin
      logger.info { set_color "Publishing Combined Metrics to CloudWatch...", :white }
      @cw.put_metric_data(cw_options)      
    rescue Exception => e
      logger.error { set_color "An error occured #{e}, SDK will retry up to 3 times", :red }
    end
  end

end