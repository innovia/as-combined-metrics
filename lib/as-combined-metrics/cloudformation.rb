module AsCombinedMetrics::Cli::CloudFormation
  def describe_stack(logical_resource_id)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    logger.info { set_color  "Getting the full autoscale group name for the resource => #{logical_resource_id}", :white }
    counter = 1
    @autoscale_group_name = nil
    @print_log = true

    until @autoscale_group_name || @spot_fleet_id
      begin
        stack_info = @cfm.describe_stack_resource({
          :stack_name => @stack_name,
          :logical_resource_id => logical_resource_id
        })

        if !stack_info.nil?
          if stack_info.stack_resource_detail.resource_type == "AWS::EC2::SpotFleet"
              @spot_fleet_id = stack_info.stack_resource_detail.physical_resource_id
              if !@spot_fleet_id.nil? && !@spot_fleet_id.empty?
                @config[:spot_fleet_id] ||= []
                @config[:spot_fleet_id] << @spot_fleet_id
                logger.info { set_color  "Spot Fleet ID: #{@autoscale_group_name}", :cyan }
              end
          else # default is good old auto scale group
              @autoscale_group_name = stack_info.stack_resource_detail.physical_resource_id
              if !@autoscale_group_name.nil? && !@autoscale_group_name.empty?
                @config[:autoscale_group_name] ||= []
                @config[:autoscale_group_name] << @autoscale_group_name
                logger.info { set_color  "AutoScale Group Name: #{@autoscale_group_name}", :cyan }
              end
          end
          File.open(options[:config_file], "w") { |f| f.write(@config.to_yaml) }
        end
      rescue Exception => e
        if e.to_s.match (/Stack with name\s\S+\sdoes not exist/)
          logger.fatal { set_color "Stack name was not found", :red }
          exit 1
        end

        if @print_log
          logger.error { set_color  "Unable to find the resource - #{e}, maybe wrong region or wrong AWS account?", :yellow }
          logger.info { "Will retry every 5 seconds up to maximum of #{options[:timeout]} seconds" }
        end

        interval = 5
        if counter < options[:timeout].to_i
          counter += interval
          @print_log = false
          sleep interval
        else
          logger.fatal { set_color  "Timeout Error  - Unable to get the full AutoScale group name for the stack #{@stack_name} for #{options[:timeout]} seconds", :red }
          exit 1
        end
      end
    end
  end
end
