# S3 Static Site - Terraform Modules

There are 2 separate modules:

* **certificate** - this module will create and verify SSL certificate via DNS record verification method

* **site** - this module will create two S3 buckets (www and non-www version) and CloudFront distributions

The modules assume that the domain has been registered with Route 53 and the NS and SOA records exist (they are created automatically when a domain is registered via Route 53).

## How to use

1. First create certificate by running the `./modules/certificate` module. It will output certificate ARN which needs to be passed to the `./modules/site` module
2. Run the `./modules/site` module


## Why 2 separate modules?

Ideally both certificate and site creation would be inside the same module but hosting a site from S3 with CloudFront requires the certificate to be issued in the **us-east-1** region. That would limit hosting the site in the same region because there is no easy way to create resources in different regions within the same module.