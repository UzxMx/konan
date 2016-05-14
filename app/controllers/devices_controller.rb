MAX_COUNT_PER_PAGE = 15

class DevicesController < ApplicationController
	before_action :authenticate_user!

	def index
		logger.debug params

		if params[:page].nil?
			current_page = 1
		else
			current_page = params[:page].to_i
		end

		content = {
			app_id: 'kumamoto',
			start: (current_page - 1) * MAX_COUNT_PER_PAGE,
			max_count: MAX_COUNT_PER_PAGE,
		}

		if params[:online].nil?
			show_online = nil
		else
			show_online = params[:online] == 'true'
		end

		if !show_online.nil?
			content['online'] = show_online
		end

		resp = RequestProxy.get_devices(content)
		@total_count = resp['total_count']
		@online_count = resp['online_count']
		@devices = resp['records']

		if show_online.nil?
			total_records_count = @total_count
		elsif show_online
			total_records_count = @online_count
		else
			total_records_count = @total_count - @online_count
		end
				
		page_num = total_records_count / MAX_COUNT_PER_PAGE
		page_num += 1 if total_records_count % MAX_COUNT_PER_PAGE

		page_start, page_end = pagination(page_num, current_page, 8)

		@page_start = page_start
		@page_end = page_end
		@page_num = page_num
		@current_page = current_page

		@show_online = show_online
	end

	def show
		device = RequestProxy.get_device_info({
			id: params[:id]
		})

		logger.info(device)

		if device['device_info'].nil?
			device['device_info'] = {}
		else
			device_info = device['device_info']
			unless device_info['network_type'].nil?
				case device_info['network_type']
				when 1
					device_info['network_type'] = 'Wi-Fi'
				when 2
					device_info['network_type'] = 'Mobile'
				when 3
					device_info['network_type'] = 'Wimax'
				when 4
					device_info['network_type'] = 'Ethernet'
				when 5
					device_info['network_type'] = 'Bluetooth'				
				else
					device_info['network_type'] = 'Unknown'						
				end
			end

			battery_info = device_info['battery_info']
			battery_remaining = nil
			battery_consume_rate = nil
			battery_source = nil
			if !battery_info.nil? and battery_info != ''
				battery_info = JSON.parse(battery_info)
				battery_remaining = "#{battery_info['percent']}%"

				case battery_info['power_source_type']
				when 1
					battery_source = 'Not Charging'	
				when 2
					battery_source = 'AC'
				when 3
					battery_source = 'USB'
				when 4
					battery_source = 'Wireless'
				else
					battery_source = 'Unknown'
				end

				unless battery_source['amount_consumed'].nil?
					battery_consume_rate = "#{battery_source['amount_consumed']} / #{battery_source['duration']} min"
				end
			end

			if battery_remaining.nil?
				battery_remaining = 'Not Got'
			end

			if battery_source.nil?
				battery_source = 'Not Got'
			end

			if battery_consume_rate.nil?
				battery_consume_rate = 'Not Got'
			end

			@battery_remaining = battery_remaining
			@battery_source = battery_source
			@battery_consume_rate = battery_consume_rate
		end

		logs_dir = RequestProxy.get_user_logs_dir({
			id: params[:id]	
		})
		logger.debug("logs_dir: #{logs_dir}")

		files = []
		begin
			Dir.foreach(logs_dir) do |file|
				next if file == '.' or file == '..'
				files << file
			end
		rescue Exception => e
		end

		files.sort do |x, y|
			y <=> x
		end

		logs = []
		files.each do |file|
			filename = file
			file = File.join(logs_dir, file)
			size = File.size(file)
			if size < 1024
				size = "#{size} B"
			elsif size < 1024 * 1024
				size = "%0.1f KB" % [size / 1024.0]
			else
				size = "%0.1f MB" % [size / 1024.0 / 1024.0]
			end

			time_format = '%Y-%m-%d %H:%M:%S'
			mtime = File.mtime(file).strftime(time_format)
					
			log = {
				name: filename,
				size: size,
				mtime: mtime
			}
			logs << log
		end

		@id = params[:id]
		@user_info = device['user_info']
		@device_info = device['device_info']
		@logs = logs
	end

	def fetch_logs
		RequestProxy.fetch_logs({
			id: params[:id]
		})

		render json: {
			status: 1
		}
	end

	def configure_logger
		RequestProxy.configure_logger({
			id: params[:id],
			log_level: params[:log_level].to_i,
			log_sent_freq: params[:log_sent_freq].to_i
		})

		render json: {
			status: 1
		}		
	end

	def fetch_new_info
		RequestProxy.fetch_device_info({
			id: params[:id]
		})

		render json: {
			status: 1
		}		
	end

	def download_log
		logs_dir = RequestProxy.get_user_logs_dir({
			id: params[:id]	
		})

		path = File.join(logs_dir, "#{params[:file]}.#{params[:format]}")
		send_file(path)
	end

	private
		def pagination(page_num, current_page, showed_num)
			page_start = 1

			half = showed_num / 2
			if current_page > half
				page_start = current_page - half + 1
			end

			page_end = page_start + showed_num - 1
			if page_end > page_num
				page_end = page_num
			end

			[page_start, page_end]
		end
end
