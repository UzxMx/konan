var Konan = window.Konan || {};
(function($) {
	var Devices = Konan.Devices = {};
	Devices.init = function() {
		$('.btn-fetch-new-info').click(function() {
			var id = $(this).attr('data-id');
			$.post({
				url: '/devices/' + id + '/fetch_new_info',
				success: function(data) {
					if (data.status == 1) {
						alert('Please wait some time for new info to be fetched. You can refresh pages to see if there is any new info');
					}
				}
			});
		});

		$('.btn-configure-logger').click(function() {
			var id = $(this).attr('data-id');
			var log_level = $('input[name=log_level]').val();
			var log_sent_freq = $('input[name=log_sent_freq').val();
			$.post({
				url: '/devices/' + id + '/configure_logger',
				data: {
					log_level: log_level,
					log_sent_freq: log_sent_freq
				},
				success: function(data) {
					if (data.status == 1) {
						alert('You MUST fetch the new info and refresh page to see if the change is made');
					}
				}
			});			
		})

		$('.btn-fetch-logs').click(function() {
			var id = $(this).attr('data-id');
			$.post({
				url: '/devices/' + id + '/fetch_logs',
				success: function(data) {
					if (data.status == 1) {
						alert('Please wait some time for logs to be uploaded. You can refresh pages to see if there is any file');
					}
				}
			});
		});
	};

	$(function() {
		Devices.init();
	});
})(jQuery);