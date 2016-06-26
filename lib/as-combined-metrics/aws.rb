module AsCombinedMetrics::Cli::Aws
	def init_aws_sdk
		logger.progname = "#{Module.nesting.first.to_s} init_aws_sdk"
    logger.info { set_color  "Initializing AWS SDK", :white }

    Aws.config.update({region: @region})

    # add max retries
    @cw  = Aws::CloudWatch::Client.new()
    @cfm = Aws::CloudFormation::Client.new()
    @as  = Aws::AutoScaling::Client.new()
  end

  def validate_as_group(autoscale_group_name)
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"
    logger.info { set_color "Validating #{autoscale_group_name} exists...", :white }

    response =  @as.describe_auto_scaling_groups({auto_scaling_group_names: [autoscale_group_name], max_records: 1})

    if response.auto_scaling_groups.empty? || autoscale_group_name != response.auto_scaling_groups[0].auto_scaling_group_name
      logger.fatal { set_color "Can't find AutoScale group #{autoscale_group_name} on ec2 - exiting now", :red }
      exit 1
    else
      logger.info { set_color "O.K", :green }
    end
  end

  def verify_stack_name
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    if ENV['STACK_NAME']
      logger.info { set_color "STACK_NAME Env variable was found [ #{ENV['STACK_NAME']} ]", :cyan }
      @stack_name = ENV['STACK_NAME']
    elsif @config[:cloudformation][:stack_name]
      logger.info { set_color "STACK_NAME was found in the config file #{@config[:cloudformation][:stack_name]}", :cyan }
      @stack_name = @config[:cloudformation][:stack_name]
    else
      logger.fatal { set_color "verify_stack_name_env Can't find Env variable STACK_NAME or a setting (stack_name: STACK_NAME_X) in the config file , exiting now...", :red }
      exit 1
    end
  end
end