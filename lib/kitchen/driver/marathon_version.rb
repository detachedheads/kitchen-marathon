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

module Kitchen
  module Driver
    # This defines the version of the gem
    module Version
      MAJOR = 0
      MINOR = 0
      PATCH = 3
      BUILD = ''.freeze

      STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.').chomp('.')

      module_function

      def json_version
        {
          'version' => STRING
        }.to_json
      end
    end
  end
end
