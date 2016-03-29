# -*- encoding: utf-8 -*-
#
# Author:: Anthony Spring (<tony@porkchopsandpaintchips.com>)
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
    # @author Anthony Spring <tony@porkchopsandpaintchips.com>
    class Marathon < Kitchen::Driver::SSHBase

      #kitchen_driver_api_version 2

      #plugin_version Kitchen::Driver::MARATHON_VERSION

      default_config  :app_prefix, 'kitchen'
      default_config  :app_template
      expand_path_for :app_template

      default_config :wait_for_sshd, true

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

      default_config :ssh_username,     'kitchen'
      default_config :ssh_private_key,  File.join(Dir.pwd, '.kitchen', 'kitchen.pem')
      expand_path_for :ssh_private_key

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

        # Wait for SSHD to be available
        #wait_for_sshd(state[:hostname], nil, :port => state[:port]) if config[:wait_for_sshd]
      end

      def converge(state) # rubocop:disable Metrics/AbcSize
        # Update the app state
        update_app_state(state)

        super(state)
      end

      # (see Base#setup)
      
      def destroy(state)
        return if state[:app_id].nil?

        begin
          ::Marathon::App.delete(state[:app_id])
        rescue ::Marathon::Error::NotFoundError => e
        end 

        state.delete(:app_id)
      end

      def setup(state)
        super(state)
      end

      def verify(state)
        # Update the app state
        update_app_state(state)

        super(state)
      end

      protected

      def create_app(config)

        # Create the application
        Retryable.retryable(
          :tries => 10,
          :sleep => lambda { |n| [2**n, 30].min },
          :on => [::Marathon::Error::TimeoutError]
        ) do |r, _|

          info("Creating the application: #{config['id']}")

          ::Marathon::App.create(config)
        end

        # Wait for the deployment to finish
        Retryable.retryable(
          :tries => 10,
          :sleep => lambda { |n| [2**n, 30].min },
          :on => [::Marathon::Error::TimeoutError, ::Timeout::Error]
        ) do |r, _|

          info("Waiting for application to deploy: #{config['id']}")

          raise ::Timeout::Error.new() if ::Marathon::App.get(config['id']).info[:tasksRunning] == 0

          info("Application #{config['id']} is running.")
        end

        config['id']
      end

      def create_app_id
        "#{config[:app_prefix]}/#{File.basename(config[:kitchen_root])}-#{SecureRandom.hex}"
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
        
        user_config.merge(base_config)
      end

      def get_application_host(id)
        puts ::Marathon::App.get(id)
      end

      def get_application_port(id)
        puts ::Marathon::App.get(id)
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

      def update_app_state(state)
        puts "Refreshing host and port from Marathon..."

        app = nil

        # Get the host and port to SSH on
        Retryable.retryable(
          :tries => 10,
          :sleep => lambda { |n| [2**n, 30].min },
          :on => [::Marathon::Error::TimeoutError]
        ) do |r, _|

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

