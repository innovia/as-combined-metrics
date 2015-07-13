AWS Autoscale Combined Metrics
==============================

Beta - Not Production Ready!

AWS currently (July 2015) does not evalute other policies during a cooldown peroid

meanning if CPU policy was triggered and scaling acitivty happened the other policies for Network / Memory etc.. would not be evaluated until the cooldown period for the first policy passed

this gem will push a custom metric to cloudwatch:

it will combine the metrics you want to check and only if all of them are out of the treshold you provided 

scale in if *all* metrics are in range send a 1 (ok to scale in)
scale out if *any* metrics are in range send a 1 (ok to scale out)


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

Credentials are loaded automatically from the following locations:

ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
Aws.config[:credentials]
Shared credentials file, ~/.aws/credentials
EC2 Instance profile


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
