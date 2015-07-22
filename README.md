AWS Autoscale Combined Metrics
==============================

AWS currently (July 2015) does not evalute other policies during a cooldown peroid

meanning if CPU policy was triggered and scaling acitivty happened the other policies for Network / Memory etc.. would not be evaluated until the cooldown period for the first policy passed

this gem will push a custom metric to cloudwatch:

it will combine the metrics you want to check and only if all of them are out of the treshold you provided 

scale in if *all* metrics are in range send a 1 (ok to scale in)
scale out if *any* metrics are in range send a 1 (ok to scale out)

How it works
------------

There's a yml config file in which you specify either a cloudformation stack name and resource (i.e AppServerGroup)
in this config you specify the metrics tresholds and comparison operator to evalute (kind of alrams in CloudWatch)

you can specify sectaions for ScaleOut and ScaleIn and their related metrics in the config file

````yml
ScaleOut:
- metric_name: CPUUtilization
  namespace: AWS/EC2
  statistics:
  - Maximum
  unit: Percent
  threshold: 20
  comparison_operator: <=
  aggregate_as_group: true
````

you can specify aggregate_as_group: true in the config and it will aggregate based on the statistics you passed across ec2 instances

Note:
AWS is already agregating the instances metrics on the AutoScaleGroupName dimension for you (so if you are pushing a custom metrics you shold be pushing it to the autoscale group diemension)


if the autoscale group needs to be extracted from the stack name you specify (useful for discovery uisng cloudformation)
````yml
cloudformation:
  enabled: true
  stack_name: STACK_NAME_X
  logical_resource_ids: 
  - CloudFormation_RESOURCE_ID_1 
  - CloudFormation_RESOURCE_ID_2 
````
you can pass multiple autoscale groups given you would like to use the same metrics and tresholds for their combined metrics
 
The app will combined the results of all metrics into a true / flase array
for ScaleOut events it will check if any element in the array is true and will publish a custom metric (i.e ScaleOut_CPUUtilization_NetworkIn ) under the combined_metrics custom name space in CloudWatch on the AutoScale Group dimension you have specified in the config

you can then set a single alarm and a single policy to perform your scale activity if itsthe value is 1 (O.K to scale in/out)


you run the file through the as-combined-metrics app (a backup of the config will be created)

````bash
as-combined-metrics -f path_to/combinedMetrics.yml
````

options:
--------
````bash
  r, [--region=REGION]                 # AWS Region
                                       # Default: us-east-1
  l, [--log-level=LOG_LEVEL]           # Log level
                                       # Default: INFO
  f, [--config-file=CONFIG_FILE]       # Metrics config file location
      [--scalein-only=SCALEIN_ONLY]    # gather combined metrics for scale in only
      [--scaleout-only=SCALEOUT_ONLY]  # gather combined metrics for scale out only
  p, [--period=N]                      # Metric datapoint last x minutes
                                       # Default: 300
  t, [--timeout=N]                     # Timeout (seconds) for fetching autoscale group name
                                       # Default: 120
  o, [--once], [--no-once]             # no loop - run once
  d, [--dryrun], [--no-dryrun]         # do not submit metric to CloudWatch
  i, [--interval=N]                    # interval to check metrics
                                       # Default: 30
````
 
you may pass ---scalein-only or --scaleout-only to have this publish only scalein / scale out metric

if you choose --dryrun it will NOT publish to cloudwatch

Required privileges
-------------------

* cloudwatch:GetMetricStatistics
* cloudwatch:PutMetricData
* autoscaling:DescribeAutoScalingGroups
* cloudformation:DescribeStackResources
* cloudformation:DescribeStacks

policy sample
````json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1436799375000",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1436799403000",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1436799495000",
            "Effect": "Allow",
            "Action": [
                "cloudformation:DescribeStackResources",
                "cloudformation:DescribeStacks"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
````

Credentials are loaded automatically from the following locations (AWS-SDK handled):

* ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
* Aws.config[:credentials]
* Shared credentials file, ~/.aws/credentials
* EC2 Instance profile


Contributing
-------------
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

License
-------
aws-cobined-metrics is released under [MIT License](http://www.opensource.org/licenses/MIT)
