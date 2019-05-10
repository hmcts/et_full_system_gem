# EtFullSystem

This gem is used to boot up all of the components of the Employment Tribunals system ready for testing or other purposes.

It can be used in the root directory of the 'et full system' repository (https://github.com/ministryofjustice/et-full-system) to run
the server side to allow automated testing.

But, in general - it can be used anywhere - as long as a certain file structure exists for the 5 services.  This structure is

systems/et1 (https://github.com/ministryofjustice/atet)
systems/et3 (https://github.com/ministryofjustice/et3)
systems/admin (https://github.com/ministryofjustice/et-admin)
systems/atos (https://github.com/ministryofjustice/et_atos_file_transfer)
systems/api (https://github.com/ministryofjustice/et_api)

The system works by placing a reverse proxy (traefik https://github.com/containous/traefik) in front of the 5 services
so that all services can be accessed using a standard subdomain based url system which looks like this

* et1.et.127.0.0.1.nip.io:3100 For ET1
* et3.et.127.0.0.1.nip.io:3100 For ET3
* admin.et.127.0.0.1.nip.io:3100 For Admin
* et1.et.127.0.0.1.nip.io:3100 For ET1
* et1.et.127.0.0.1.nip.io:3100 For ET1

The services are run all together using 'forego' (like foreman - runs a Procfile) and once the port number for each
service is known, traefik is told about it - so it all just works.

There are other services as well that are run - which are there for testing - these are :-

* et-fake-acas-server (https://github.com/ministryofjustice/et_fake_acas_server) - Provides a fake ACAS server with predictable responses based on various special certificate numbers
* mailhog (https://github.com/mailhog/MailHog) - Captures all emails sent to allow the test suite or the developer to view them and check them
* minio (https://github.com/minio/minio) - A local amazon S3 server to avoid having S3 credentials for every environment
* azurite (https://github.com/Azure/Azurite) - A local azure blob server to avoid having azure credentials for every environment


## Pre Requisites

### Running With Docker

If you want to use the docker setup, it keeps everything inside a container and therefore doesnt interfere with your
system configuration at all.  All you need is

* Docker
* Docker Compose

### Running Without Docker

To run without docker, you need a few tools

* Traefik (https://traefik.io)
* Mailhog (https://github.com/mailhog/MailHog)
* Minio (https://github.com/minio/minio)
* Azurite (https://github.com/Azure/Azurite)

I will not include installation instructions here for them - please visit their web sites and install them on your platform.
For OSX users check out the homebrew repository - there are formulas for some of these.

## Installation

At the moment, this gem is not published anywhere - it is too specific to be published to rubygems.

So, there are 2 ways of installing it - using bundler from an existing project (et_full_system uses it) and installing from
github directly.

### Using Bundler

Add this line to your application's Gemfile:

```ruby
gem 'et_full_system', '~> 0.1'
```

And then execute:

    $ bundle

And if you want to install a binstub (do bundle help binstubs for more options you might want)

    $ bundle binstubs et_full_system --standalone

### Installing Direct

Or install it yourself directly from rubygems as follows:

    $ gem install et_full_system

## Usage (using docker)

To setup the docker system

    $ et_full_system docker setup

To start the server (Must have been setup with the command above - for the first time and after changing gems etc.. in the services)

    $ et_full_system docker server

To reset the server (Note: no other docker containers should be sharing the network - such as a test container)

    $ et_full_system docker reset

To setup and start the server in detached mode (i.e showing no logs etc..)

    $ et_full_system docker server -d

To watch the logs of an existing running server

    $ et_full_system docker compose logs -f

To do any other docker compose commands

    $ et_full_system docker compose <command> <command args>

To redirect a service to your own hosted version

If you want to host a service yourself for debugging or other purposes - you must setup the service yourself with all
the relevant environment variables (see the service_env command), then, to point the full system url's to your hosted service, use the following command

    $ et_full_system docker update_service_url <service_name> <service_url>

Where <service_name> is either et1, et3, admin, api or atos
and <service_url> must be a URL that is reachable from the docker container - you may need to use the special 'host.docker.internal'
or in general checkout this page https://docs.docker.com/docker-for-mac/networking/ or https://docs.docker.com/docker-for-windows/networking/

Note, you need to really think when you are doing this.  If you have 2 services running (one local, one in docker) - what will happen ?  In the
case of a web server, nothing - it will just waste resources - but if you have 2 sidekiq's running and they are pointing to the same redis
database, then they will both process jobs, meaning you might not see the jobs being taken by your local version.

### Examples Of Local Hosting

#### Web Server Only

Say I am working on a Mac and I wanted to work on some front end stuff in ET1 but wasn't touching any 
background jobs in sidekiq - I would do this (with et_full_system docker server already running) :-

    $ et_full_system docker update_service_url et1 http://docker.host.internal:3000
    
And then start your local server, not forgetting any important environment variables (hint - to see what the docker version has them 
set to - do use the service_env command as previously mentioned)    

This would leave the docker et1 running, but the reverse proxy (traefik) would be sending all traffic to your local server

#### Web Server AND Sidekiq

Say I am working on a Mac and I wanted to work on some front end stuff that includes the background jobs.
I need to redirect the web server, however I also need to prevent sidekiq from running on the server - and whilst I am at it,
I may as well tell it not to run the web server - so ive got more memory available on my machine.
I also want the database server and the sidekiq server to be available to save me running them

First, I would stop the existing et_full_system docker server, then restart it with the following command

    $ DB_PORT=5432 REDIS_PORT=6379 et_full_system docker server --without=et1_web et1_sidekiq
    
The DB_PORT and REDIS_PORT env vars tell the docker system to forward those ports to your local machine.  If you dont want to
do that as you have your own database and redisk server, leave that out - but as always, think about what you are doing.  If this
were the API for example, both admin and et_atos_file_transfer services share the same database - if yours were isolated then things
wouldnt go to plan.

The --without flag tells the system to start up, but exclude et1_web and et1_sidekiq


## Usage (Without docker)

To setup the local system

    $ et_full_system local setup

To start the server (Must have been setup with the command above - for the first time and after changing gems etc.. in the services)

    $ et_full_system local server

To reset the server - this will drop and recreate the database, empty redis etc..  so VERY destructive

    $ et_full_system local reset

To redirect a service to your own hosted version

If you want to host a service yourself for debugging or other purposes - you must setup the service yourself with all
the relevant environment variables (see the service_env command), then, to point the full system url's to your hosted service, use the following command

    $ et_full_system local update_service_url <service_name> <service_url>

Where <service_name> is either et1, et3, admin, api or atos

To setup the environment variables in the current shell to allow you to run a service manually for debugging for example

    $ export $(et_full_system local service_env <service_name>)


    Where <service_name> is either et1, et3, admin, api or atos

If for any reason, there are services that you don't want - you might just want to save resources and are not interested in
every part of the system, you can use the --without option on the server command as follows

    $ et_full_system local server --without=et3_web fake_acas_web

To see all options - do

    $ et_full_system local server --help

### Upgrading

Note that docker caches stuff for the better and for the worse.  So, the command in the Dockerfile that installs the version
of the gem that you have - but inside docker - will be cached forever - only if the command changes in the Dockerfile is this
cache busted.

So, for now - until there is a more automated solution to this, whenever a new version of this gem is installed - simply reset using the following command

    $ et_full_system docker reset

Which will re build it from scratch - then just use the gem as normal (it will have been setup by this command so you can
go straight to using the server command)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hmcts/et_full_system_gem. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the EtFullSystem project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hmcts/et_full_system_gem/blob/master/CODE_OF_CONDUCT.md).
