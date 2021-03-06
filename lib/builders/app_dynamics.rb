# Encoding: utf-8
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'builders/base'
require 'net/http'

module Builders
  class AppDynamics < Base
    def initialize(options)
      super 'app-dynamics', 'zip', options
    end

    protected

    def download(file, version)
      uri = URI(instance_exec(version, &version_specific(version)))

      print "Downloading #{@name} #{version} from #{uri}"

      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new('https://login.appdynamics.com/sso/login/')
        request.set_form_data('username' => @username, 'password' => @password)
        cookie = http.request(request).response['set-cookie'].split('; ')[0]

        request = Net::HTTP::Get.new(uri.path)
        request['Cookie'] = cookie
        http.request request do |response|
          progress = ProgressIndicator.new(response['Content-Length'].to_i)

          response.read_body do |chunk|
            file.write chunk
            progress.increment chunk.length
          end

          progress.finish
        end
      end

      file.close
    end

    def normalize(raw)
      components = raw.split('.')
      mmm = components[0..2]
      q = components[3, components.length - 3]
      new_q = q && q.length > 0 ? '_' + q.join('.') : nil
      mmm.join('.') + (new_q ? new_q : '')
    end

    def version_specific(version)
      if @latest
        ->(v) { 'http://download.appdynamics.com/onpremise/public/latest/AppServerAgent.zip' }
      else
        ->(v) { "http://download.appdynamics.com/onpremise/public/archives/#{v}/AppServerAgent.zip" }
      end
    end
  end
end
