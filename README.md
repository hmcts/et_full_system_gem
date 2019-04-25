# EtFullSystem

This gem is used to boot up all of the components of the Employment Tribunals system ready for testing or other purposes

## Installation

Because the gem is not yet published anywhere, it cannot be installed using the normal 'gem install' command, as it
only exists in github - only Bundler can install from github.
The full system test suite, which also checks out all 5 services into sub directories includes this gem, so once you have
done 'bundle install' from there - the gem will be installed, but you will need to prefix all commands with 'bundle exec' unless
you have produced a 'binstub' for this gem (see below) - then you can just use the executable directly.

Add this line to your application's Gemfile:

```ruby
gem 'et_full_system'
```

And then execute:

    $ bundle

And if you want to install a binstub (do bundle help binstubs for more options you might want)

    $ bundle binstubs et_full_system --standalone

Or install it yourself directly from github as follows:

    $ git checkout git@github.com:hmcts/et_full_system_gem.git
    $ cd et_full_system_gem
    $ gem build et_full_system -o et_full_system.gem
    $ gem install et_full_system.gem
    $ rm et_full_system.gem

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


## Usage (Without docker)

To setup the environment variables in the current shell to allow you to run a service manually for debugging for example

    $ export $(et_full_system local service_env <service_name>)


    Where <service_name> is either et1, et3, admin, api or atos

### Upgrading

Note that docker caches stuff for the better and for the worse.  So, the command in the Dockerfile that installs the version
of the gem that you have - but inside docker - will be cached forever - only if the command changes in the Dockerfile is this
cache busted.

So, for now - until there is a more automated solution to this, whenever a new version of this gem is installed - simply re build
your docker image using the following command

    $ et_full_system docker compose build --no-cache

Which will re build it from scratch - then just use the gem as normal


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/et_full_system. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the EtFullSystem project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/et_full_system/blob/master/CODE_OF_CONDUCT.md).
