# encoding: utf-8
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'thor'
require 'aws-sdk'
require 'yaml'
require 'pp'
require 'time'

class AsCombinedMetrics::Cli < Thor
  autoload :Logging,        'as-combined-metrics/logger'
  autoload :Config,         'as-combined-metrics/config'
  autoload :Poller,         'as-combined-metrics/poller'
  autoload :Aws,            'as-combined-metrics/aws'
  autoload :Utils,          'as-combined-metrics/utils'
  autoload :Stats,          'as-combined-metrics/stats'
  autoload :CloudWatch,     'as-combined-metrics/cloudwatch'
  autoload :CloudFormation, 'as-combined-metrics/cloudformation'

  default_task  :start

  class_option  :region,              :desc => 'AWS Region',                                          :default => 'us-east-1',      :aliases => 'r', :type => :string
  class_option  :log_level,           :desc => 'Log level',                                           :default => 'INFO',           :aliases => 'l', :type => :string
  class_option  :config_file,         :desc => 'Metrics config file location',                                                      :aliases => 'f', :type => :string
  class_option  :scalein_only,        :desc => 'gather combined metrics for scale in only',           :default => false
  class_option  :scaleout_only,       :desc => 'gather combined metrics for scale out only',          :default => false
  class_option  :period,              :desc => 'Metric datapoint last x minutes',                     :default => 300,              :aliases => 'p', :type => :numeric
  class_option  :timeout,             :desc => 'Timeout (seconds) for fetching autoscale group name', :default => 300,              :aliases => 't', :type => :numeric
  class_option  :once,                :desc => "no loop - run once",                                  :default => false,            :aliases => 'o', :type => :boolean
  class_option  :dryrun,              :desc => "do not submit metric to CloudWatch",                  :default => false,            :aliases => 'd', :type => :boolean
  class_option  :interval,            :desc => 'interval to check metrics',                           :default => 30,               :aliases => 'i', :type => :numeric
  desc "start", "combine metrics"
  def start
    %w(INT TERM USR1 USR2 TTIN).each do |sig|
      trap sig do
        puts "Got Singnal #{sig} Exiting..."
        exit 0
      end
    end

    raise Thor::RequiredArgumentMissingError, 'missing config file location [-f / --config-file]' if options[:config_file].nil?

    extend Logging
    extend Utils
    extend Config
    extend Stats
    extend Aws
    extend CloudFormation
    extend CloudWatch
    extend Poller

    logger.info { set_color "Dry Run - will not published metrics to CloudWatch", :yellow } if options[:dryrun]
    logger.info "Starting Combined Metrics on #{options[:region]} region"
    @region = options[:region]
    init_aws_sdk
    load_config
    poll(options[:interval])
    <<-INFO
        1) in this loop (poll) we overwrite a hash of combined metrics as follow:

           for every metric in the config file use fetch_metric(metric) to get it's current reading

           if metric has a key of aggregate_as_group,
              get all instances of the AutoScale group and for each instance fetch metric
              then push the result to an array, from that array get the average result and push it to the combined_metrics hash

           if one of the metrics fails to get datapoints (result => empty datapoints set) then set the result to -1
           the check_combined_metrics will see that the value is -1 and automatically false the result


        Combined metrics:
        { "CPUUtilization" => {"measure"=>7.08, "threshold"=>30, "comparison_operator"=>">="},
          "NetworkIn" => {"measure"=>43765341.0, "threshold"=>943718400, "comparison_operator"=>">="},
          "memory_usage.heapUsed.average"=>{"measure"=> 67844551, "threshold"=>600000, "comparison_operator"=>">="}
        }

        2) we then call check_combined_metrics to check if the measure is under or above the threshold and the result (true/false) to array

        3) if all elements of that array are true we set the value of self.combined_metric_value to 1 (Scale OK) else we set it to 0 (Do not Scale)

        4) last step -> publish that value to CloudWatch
    INFO
  end

  map ["-v", "--version"] => :version
  desc "version", "version"
  def version
    say AsCombinedMetrics::ABOUT, color = :green
  end
end