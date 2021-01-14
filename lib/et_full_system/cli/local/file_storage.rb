module EtFullSystem
  #!/usr/bin/env ruby
  # frozen_string_literal: true
  require "rubygems"
  require "thor"
  require 'aws-sdk-s3'
  require 'azure/storage'

  module Cli
    module Local
      class FileStorageCommand < Thor
        GEM_PATH = File.absolute_path('../../../..', __dir__)

        desc "setup", "Primes the storage account(s) for running locally - i.e. using local S3 or Azure Blob storage"
        def setup_storage
          setup_s3_storage
          setup_azure_storage
        end

        private

        def unbundled(&block)
          method = Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_original_env
          Bundler.send(method, &block)
        end

        def setup_s3_storage
          config = {
            region: ENV.fetch('AWS_REGION', 'us-east-1'),
            access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', 'accessKey1'),
            secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', 'verySecretKey1'),
            endpoint: ENV.fetch('AWS_ENDPOINT', 'http://s3.et.127.0.0.1.nip.io:3100/'),
            force_path_style: ENV.fetch('AWS_S3_FORCE_PATH_STYLE', 'true') == 'true'
          }
          s3 = Aws::S3::Client.new(config)
          retry_countdown = 10
          begin
            Aws::S3::Bucket.new(client: s3, name: 'et1bucket').tap do |bucket|
              bucket.create unless bucket.exists?
            end
            Aws::S3::Bucket.new(client: s3, name: 'etapibucket').tap do |bucket|
              bucket.create unless bucket.exists?
            end
          rescue Seahorse::Client::NetworkingError, Aws::S3::Errors::NotFound, Aws::S3::Errors::Http502Error, Aws::Errors::ServiceError
            retry_countdown -= 1
            if retry_countdown.zero?
              fail "Could not connect to the S3 server after 10 retries"
            else
              STDERR.puts "Retrying connection to S3 server in 30 seconds"
              sleep 30
              retry
            end
          end
        end

        def setup_azure_storage
          unbundled do
            puts `bash --login -c "export RAILS_ENV=production && cd systems/api && rvm use && dotenv -f \"#{GEM_PATH}/foreman/.env\" dotenv -f \"#{GEM_PATH}/foreman/et_api.env\" bundle exec rails configure_azure_storage_containers configure_azure_storage_cors"`

          end
        end
      end
    end
  end
end
