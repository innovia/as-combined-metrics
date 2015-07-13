## AWS-Combined-Metrics

AWS currently (July 2015) does not evalute policies during a cooldown peroid

this gem will push a custom metric to cloudwatch:

it will combine the metrics you want to check and only if all of them are out of the treshold you provided 

scale in if *all* metrics are in range send a 1 (ok to scale in)
scale out if *any* metrics are in range send a 1 (ok to scale out)


you will need to grant access to cloudwatch for publishing a custom metric

Credentials are loaded automatically from the following locations:

ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
Aws.config[:credentials]
Shared credentials file, ~/.aws/credentials
EC2 Instance profile


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
aws-cobined-metrics is released under [MIT License](http://www.opensource.org/licenses/MIT)
