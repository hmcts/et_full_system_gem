require 'bundler'
module EtFullSystem
  #!/usr/bin/env ruby
  # frozen_string_literal: true
  module Cli
    module Docker
      class ServerCommand < Thor
        BEFORE_BOOT_SCRIPT =
        desc "up", "Starts the full system server on docker"
        method_option :without, type: :array, default: [], banner: "service1 service2", desc: "If specified, disables the specified services from running. The services are et1_web, et1_sidekiq, et3_web, mail_web, api_web, api_sidekiq, admin_web, atos_api_web, azure_blob_web, fake_acas_web, fake_ccd_web"
        method_option :ccd_docker, type: :boolean, default: false, aliases: 'ccd-docker', desc: "If specified, instead of using the built in fake ccd server, the system will connect to your local machine (see ccd-docker-host option also)"
        method_option :ccd_docker_host, type: :string, default: 'docker.for.mac.localhost', aliases: 'ccd-docker-host', desc: "Only used if ccd-docker=true.  This specifies the host name of your machine when viewed from inside the docker container.  This defaults to docker.for.mac.localhost which is suitable for mac OSX only.  Consult docker documentation for other systems"
        method_option :minimal, type: :boolean, default: false, desc: 'Set to true to only start the minimum (db, redis, mail, azure blob, fake_acas, fake_ccd)'
        def up(*args)
          unbundled do
            server_args = []
            server_args << "--minimal" if options.minimal?
            server_args << "--without=#{options[:without].join(' ')}" unless options[:without].empty?
            env_vars = ["SERVER_ARGS='#{server_args.join(' ')}'"]
            env_vars << "LOCALHOST_FROM_DOCKER_IP=#{host_ip}"
            env_vars << "RECORD_VIDEO=#{options.record_video?}"
            if options.ccd_docker?
              env_vars << "CCD_AUTH_BASE_URL=http://#{options.ccd_docker_host}:4502"
              env_vars << "CCD_IDAM_BASE_URL=http://#{options.ccd_docker_host}:5000"
              env_vars << "CCD_DATA_STORE_BASE_URL=http://#{options.ccd_docker_host}:4452"
              env_vars << "CCD_DOCUMENT_STORE_BASE_URL=http://#{options.ccd_docker_host}:4506"
              env_vars << "CCD_GATEWAY_API_URL=http://#{options.ccd_docker_host}:3453"
              env_vars << "CCD_DOCUMENT_STORE_URL_REWRITE=#{options.ccd_docker_host}:4506:dm-store:8080"
              env_vars << "CCD_SIDAM_USERNAME=m@m.com"
              env_vars << "CCD_SIDAM_PASSWORD=Pa55word11"
              env_vars << "CCD_GENERATE_ETHOS_CASE_REFERENCE=true"
            end
            extra_args = []
            env_vars << "DB_PORT=#{ENV.fetch('DB_PORT', EtFullSystem.is_port_open?(5432) ? 0 : 5432)}"
            env_vars << "REDIS_PORT=#{ENV.fetch('REDIS_PORT', EtFullSystem.is_port_open?(6379) ? 0 : 6379)}"
            gem_root = File.absolute_path('../../../..', __dir__)
            cmd = "GEM_VERSION=#{EtFullSystem::VERSION} #{env_vars.join(' ')} docker-compose -f #{gem_root}/docker/docker-compose.yml up #{(extra_args + args).join(' ')}"
            puts cmd
            exec(cmd)
          end
        end

        desc "down", "Stops the full system server on docker"
        def down(*args)
          unbundled do
            gem_root = File.absolute_path('../../../..', __dir__)
            cmd = "GEM_VERSION=#{EtFullSystem::VERSION} LOCALHOST_FROM_DOCKER_IP=#{host_ip} docker-compose -f #{gem_root}/docker/docker-compose.yml down #{args.join(' ')}"
            puts cmd
            exec(cmd)
          end
        end

        default_task :up

        private

        def unbundled(&block)
          method = Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_original_env
          Bundler.send(method, &block)
        end


        def host_ip
          result = JSON.parse `docker network inspect \`docker network list | grep docker_et_full_system | awk '{print $1}'\``
          result.first.dig('IPAM', 'Config').first['Gateway']
        end
      end
    end
  end
end
