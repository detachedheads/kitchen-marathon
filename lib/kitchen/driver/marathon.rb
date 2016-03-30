# -*- encoding: utf-8 -*-
#
# Author:: Anthony Spring (<aspring@yieldbot.com>)
#
# Copyright (C) 2016, Anthony Spring
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'kitchen'
require 'marathon'
require 'net/ssh'
require 'retryable'

module Kitchen
  module Driver
    # Marathon driver for Kitchen.
    #
    # @author Anthony Spring <aspring@yieldbot.com>
    class Marathon < Kitchen::Driver::SSHBase # rubocop:disable Metrics/ClassLength
      default_config  :app_prefix, 'kitchen'
      default_config  :app_template
      expand_path_for :app_template

      default_config :app_config, {}

      # Marathon HTTP Configuration

      default_config :marathon_host, 'http://localhost:8080'
      default_config :marathon_password
      default_config :marathon_username
      default_config :verify_ssl, false

      # Marathon Proxy Configuration

      default_config :http_proxyaddr
      default_config :http_proxyport
      default_config :http_proxyuser
      default_config :http_proxypass

      # SSH Configuration

      default_config  :ssh_username,     'kitchen'
      default_config  :ssh_private_key,  File.join(Dir.pwd, '.kitchen', 'kitchen.pem')
      expand_path_for :ssh_private_key

      default_config(:instance_name) do |driver|
        driver.windows_os? ? nil : driver.instance.name
      end

      # Creates a new Driver object using the provided configuration data
      # which will be merged with any default configuration.
      #
      # @param config [Hash] provided driver configuration
      def initialize(config = {})
        # Let our parent do its work
        super(config)

        # Initialize marathon
        initialize_marathon
      end

      def create(state)
        return if state[:app_id]

        # Update username/password
        state[:username]  = config[:ssh_username]
        state[:ssh_key]   = config[:ssh_private_key]

        # Generate the application configuration
        app_config = generate_app_config

        # Create the app
        state[:app_id] = create_app(app_config)

        # Update state
        update_app_state(state)
      end

      def converge(state)
        # Update the app state
        update_app_state(state)

        super(state)
      end

      def destroy(state)
        return if state[:app_id].nil?

        begin
          ::Marathon::App.delete(state[:app_id])
        rescue ::Marathon::Error::NotFoundError
          puts "App (#{state[:app_id]}) not found."
        end

        state.delete(:app_id)
      end

      def setup(state)
        # Update the app state
        update_app_state(state)

        super(state)
      end

      def verify(state)
        # Update the app state
        update_app_state(state)

        super(state)
      end

      protected

      def create_app(config) # rubocop:disable Metrics/MethodLength, Metrics/LineLength
        # Create the application
        Retryable.retryable(
          tries: 10,
          sleep: ->(n) { [2**n, 30].min },
          on: [::Marathon::Error::TimeoutError]
        ) do |_r, _|
          info("Creating the application: #{config['id']}")

          ::Marathon::App.create(config)
        end

        # Wait for the deployment to finish
        Retryable.retryable(
          tries: 10,
          sleep: ->(n) { [2**n, 30].min },
          on: [::Marathon::Error::TimeoutError, ::Timeout::Error]
        ) do |_r, _|
          info("Waiting for application to deploy: #{config['id']}")

          raise(::Timeout::Error.new, 'App is not running.') if ::Marathon::App.get(config['id']).info[:tasksRunning] == 0


          info("Application #{config['id']} is running.")
        end

        config['id']
      end

      def create_app_id
        # Need to remove any underscores from the app name
        "#{config[:app_prefix]}/#{config[:instance_name]}-#{SecureRandom.hex}".tr('_', '-')
      end

      def generate_app_config
        # Generate the necessary app config
        base_config = {}
        base_config['id']         = create_app_id
        base_config['instances']  = 1

        # Bring in the user defined JSON template
        user_config = if File.file?(config[:app_template])
                        JSON.parse(IO.read(config[:app_template]))
                      else
                        {}
                      end

        # user config -> app config -> basecconfig
        user_config.merge(config[:app_config]).merge(base_config)
      end

      def initialize_marathon
        # Initialize Marathon based off of configuration data
        marathon = {}

        # Basic HTTP Information
        marathon[:username] = config[:marathon_username]
        marathon[:password] = config[:marathon_password]

        # Basic SSL information
        marathon[:verify]   = config[:verify_ssl]

        # Basic Proxy information
        marathon[:http_proxyaddr] = config[:http_proxyaddr]
        marathon[:http_proxyport] = config[:http_proxyport]
        marathon[:http_proxyuser] = config[:http_proxyuser]
        marathon[:http_proxypass] = config[:http_proxypass]

        # Set the Marathon credentials if given
        ::Marathon.options = marathon

        # Set the Marathon URL
        ::Marathon.url = config[:marathon_host]
      end

      def update_app_state(state) # rubocop:disable Metrics/MethodLength, Metrics/LineLength
        puts 'Refreshing host and port from Marathon...'

        app = nil

        # Get the host and port to SSH on
        Retryable.retryable(
          tries: 10,
          sleep: ->(n) { [2**n, 30].min },
          on: [::Marathon::Error::TimeoutError]
        ) do |_r, _|
          # Get the app
          app = ::Marathon::App.get(state[:app_id])
        end

        # Get the host
        state[:hostname] = app.info[:tasks][0][:host]

        # Get the mappings
        mappings = app.info[:container][:docker][:portMappings]

        # Get the SSH port index
        ssh_index = mappings.find_index(mappings.find { |mapping| mapping[:labels][:SERVICE] == 'ssh' })

        # Get the port
        state[:port] = app.info[:tasks][0][:ports][ssh_index]
      end
    end
  end
end
