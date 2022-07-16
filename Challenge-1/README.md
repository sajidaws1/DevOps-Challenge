A template and configuration that reuses modules from the terraform registry to create a three tier application.

The public presentation tier is an apache webserver host serving static content/redirectional/rule/ssl-offloading that passes requests to the private application tier.

The private application tier hosts a EKS container architiecture that persists data in the DB tier.

The db tier hosts an RDS PostgreSQL instance.