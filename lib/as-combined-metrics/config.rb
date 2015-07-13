require 'digest/sha1'

class ConfigError < StandardError
end

module AsCombinedMetrics::Cli::Config
  def load_config
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"
    
    sha1_config = Digest::SHA1.hexdigest(File.read(options[:config_file]))
    sha1_config_bkp = Digest::SHA1.hexdigest(File.read("#{options[:config_file]}.bkp"))

    if sha1_config != sha1_config_bkp
      logger.info { set_color  "Backing up original config file to #{options[:config_file]}.bkp", :white }
      FileUtils.cp(options[:config_file], "#{options[:config_file]}.bkp")  
    else
      logger.info {set_color "Skipping backup because the backup is identical to the config file", :white }
    end

    begin
      logger.info { set_color "Loading config file (#{options[:config_file]})", :white }
      @config = YAML.load_file(options[:config_file])

      # Symbolize keys recursively for config
      @config.deep_symbolize_keys!
      logger.debug "config: #{@config}"
      
      if options[:scalein_only] && !@config.has_key?(:ScaleIn)
        raise ConfigError, "Could not find the proper mode for ScaleIn in the config file"
      elsif options[:scaleout_only] && !@config.has_key?(:ScaleOut)
        raise ConfigError, "Could not find the proper mode for ScaleOut in the config file"
      elsif !@config.has_key?(:ScaleIn) || !@config.has_key?(:ScaleOut)
        raise ConfigError, "Could not find the proper mode for ScaleIn or ScaleOut in the config file"
      end

    rescue Exception, ConfigError => e
      logger.fatal {set_color "Error reading config file: #{e}", :red}
      puts e.backtrace
      exit 1
    end
    process
  end

  def process
    logger.progname = "#{Module.nesting.first.to_s} #{__method__}"

    if @config.has_key?(:autoscale_group_name)
      validate_as_group(@config[:autoscale_group_name])
    elsif @config[:cloudformation][:enabled]
      verify_stack_name

      @config[:cloudformation][:logical_resource_ids].each do | resource |
        logger.debug "logical_resource_id: #{resource}"
        describe_stack(resource)
      end
    end
  end
end