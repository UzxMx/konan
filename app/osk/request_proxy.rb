require 'socket'
require 'thread'
require 'json'

EOL = ["\r", "\n"]

class RequestProxy

	class << self
		def init
			connections = []
			8.times do
				s = TCPSocket.new('127.0.0.1', 8082)
				connections << s
			end

			@connections = connections
			@connections_mutex = Mutex.new
			@connections_cond = ConditionVariable.new
		end

		def logger
			Rails.logger
		end

		def acquire_connection
			connection = nil
			@connections_mutex.synchronize do
				logger.info "connection count in pool: #{@connections.length}"

				while @connections.length == 0
					logger.info 'wait for connection...'
					@connections_cond.wait(@connections_mutex)
				end
				connection = @connections.shift
			end
			logger.info 'got connection'
			connection
		end

		def release_connection(connection)
			@connections_mutex.synchronize do
				@connections << connection
				@connections_cond.signal

				logger.info "release connection"
				logger.info "connection count in pool: #{@connections.length}"
			end
		end
	end

	init

	class << self
		def send_message(connection, command, content)
			message = {command: command}
			if content
				message["content"] = content
			end

			buf = StringIO.new
			buf << JSON.generate(message)
			buf << "\r\n"

			connection.print(buf.string)
		end

		def get_response(connection)
			buf = StringIO.new
			loop do
				str = connection.recv(4096)
				if /(.*)\r\n$/ =~ str
					buf << $1
					break
				end
				buf << str
			end
			JSON.parse(buf.string)
		end

		# app_id, online?, start, max_count
		def get_devices(params = {})
			connection = acquire_connection
			send_message(connection, 'get_devices', params)
			resp = get_response(connection)
			release_connection(connection)
			resp['content']
		end

		def fetch_logs(params = {})
			connection = acquire_connection
			send_message(connection, 'fetch_all_logs', params)
		end

		def get_user_logs_dir(params = {})
			connection = acquire_connection
			send_message(connection, 'get_user_logs_dir', params)
			resp = get_response(connection)
			release_connection(connection)
			resp['content']['path']
		end

		def get_device_info(params = {})
			connection = acquire_connection
			send_message(connection, "get_device_info", params)
			resp = get_response(connection)
			release_connection(connection)
			resp['content']
		end

		def fetch_device_info(params = {})
			connection = acquire_connection
			send_message(connection, "fetch_device_info", params)
			release_connection(connection)
		end

		def configure_logger(params = {})
			connection = acquire_connection
			send_message(connection, "configure_logger", params)
			release_connection(connection)
		end
	end
end