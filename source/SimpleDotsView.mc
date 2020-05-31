using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Math;
using Toybox.ActivityMonitor;

class SimpleDotsView extends WatchUi.WatchFace {

	var primary_color;
	var secondary_color;
	var primary_off_color;
	var secondary_off_color;
	var good_color;
	var warning_color;
	var error_color;
	
	var font_small;
	var font_large;
	var font_icons;
	
	var font_small_width;
	var font_large_width;
	var font_icons_width;
	
	var width;
	var height;
	var font_icons_offset;

	var dot_thickness;
	var hour_position = new [2];
	var minute_position = new [2];
	var month_position = new [2];
	var date_position = new [2];
	var date_positions = new [7];
	var months_positions = new [12];
	var battery_positions = new [12];
	var right_data_position = new [2];

	var top;
	var bottom; 
	var right;
	var left;
	
	// 300 seconds.
	var heart_rate_period = new Time.Duration(300);
	
	var in_low_power= false;
	var can_burn_in = false;
	var burn_in_grid;
	var burn_in_grid_width;
	var burn_in_grid_height;
	var burn_in_grid_offset;
	var burn_in_grid_horizontal;
	var burn_in_grid_vertical;

    function initialize() {
        WatchFace.initialize();
        var settings = System.getDeviceSettings();
        if(settings has :requiresBurnInProtection) {
        	can_burn_in = settings.requiresBurnInProtection;
    	}
    }

    // Load your resources here
    function onLayout(dc) {
    	primary_color = Graphics.COLOR_WHITE;
    	secondary_color = 0x109AD7; // Light blue. (https://developer.garmin.com/connect-iq/user-experience-guide/brand-guidelines)
    	primary_off_color = 0x494848; // Dark gray. (https://developer.garmin.com/connect-iq/user-experience-guide/brand-guidelines)
    	secondary_off_color = 0xBBBDBF; // Light gray. (https://developer.garmin.com/connect-iq/user-experience-guide/brand-guidelines)
    	good_color = 0x00FF00; // Green. (https://developer.garmin.com/connect-iq/user-experience-guide/page-layout)
    	warning_color = 0xFFFF00; // Yellow. (https://developer.garmin.com/connect-iq/user-experience-guide/page-layout)
    	error_color = 0xFF0000; // Red. (https://developer.garmin.com/connect-iq/user-experience-guide/page-layout)

    	font_small = Graphics.FONT_XTINY;
    	font_large = Graphics.FONT_NUMBER_THAI_HOT;
    	font_icons = WatchUi.loadResource(Rez.Fonts.icons);

    	width = dc.getWidth();
    	height = dc.getHeight();

		var font_small_dimensions = getFontDimensions(dc, font_small);
		font_small_width = font_small_dimensions[0];
		var font_small_height = font_small_dimensions[1];
		var font_small_size = font_small_height;
    	if (font_small_size < font_small_width) {
    		font_small_size = font_small_width;
    	}
    	
		var font_large_dimensions = getFontDimensions(dc, font_large);
		font_large_width = font_large_dimensions[0];
		var font_large_height = font_large_dimensions[1];
		
		var font_icons_dimensions = getFontDimensions(dc, font_icons);
		font_icons_width = font_icons_dimensions[0];
    	
    	font_icons_offset = 1.25 * font_icons_width;
    	
		var watch_radius = width / 2.0;
		top = height / 2 - font_large_height / 2 - font_small_height / 2;
		bottom = height - top;
		var top_left_angle = Math.asin((height / 2.0 - top) / watch_radius);
		var top_left = calculateCirclePosition(Math.PI + top_left_angle, watch_radius);
		left = top_left[0] + font_small_size / 2.0;
		right = width - left;
		
		hour_position = [width / 2, height / 2];
    	minute_position = [width / 2, height / 2];
		month_position = [width / 2, top];
		date_position = [month_position[0], month_position[1]];
		date_position[0] += font_small_width * 2.0;
		right_data_position = [right, bottom];

		var radius = width / 2.0 - font_small_size / 2.0;
		var dots_height = (height / 2.0 - top - (font_small_size * radius / (width / 2.0))) * 2.0;
		var dots_angle = Math.asin(dots_height / 2.0 / radius) * 2.0;
		dot_thickness = dots_height / 48;

		var date_positions_step = dot_thickness * 6.0;
		for(var i = 0; i < date_positions.size(); ++i) {
			date_positions[i] = [width / 2, height / 2 + font_large_height / 2 + i * date_positions_step];
		}
		battery_positions = getDots(radius, battery_positions.size(), dots_angle, 0);
		months_positions = getDots(radius, months_positions.size(), dots_angle, Math.PI);

    	if (can_burn_in) {
    		burn_in_grid = WatchUi.loadResource(Rez.Drawables.grid);
    		burn_in_grid_offset = 0;
	    	burn_in_grid_width = 128;
	    	burn_in_grid_height = 128;
	    	burn_in_grid_horizontal = Math.ceil(width.toFloat() / burn_in_grid_width.toFloat());
	    	burn_in_grid_vertical = Math.ceil(height.toFloat() / burn_in_grid_height.toFloat());
    	}
    	
    	Application.Properties.setValue("info_bottom_right", 1);
    	Application.Properties.setValue("info_bottom_left", 2);
    }
    
    function getFontDimensions(dc, font) {
   		var font_dimensions = [0, 0];
		for(var i = '0'; i <= '9'; ++i) {
			var font_size = dc.getTextDimensions(i.toString(), font);
			if (font_size[0] > font_dimensions[0]) {
				font_dimensions[0] = font_size[0];
			}
			if (font_size[1] > font_dimensions[1]) {
				font_dimensions[1] = font_size[1];
			}
		}
		return font_dimensions;
    }
    
    function calculateCirclePosition(angle, radius) {
    	return [
    		width / 2.0 + Math.round(radius * Math.cos(angle)), 
    		height / 2.0 + Math.round(radius * Math.sin(angle))
    		];
    }
    
    function getDots(radius, count, total_angle, angle_offset) {
		var dot_step = total_angle / (count - 1.0);
		var dots = new [count];
		for(var i = 0; i < dots.size(); ++i) {
			dots[i] = calculateCirclePosition(angle_offset - (i - (dots.size() - 1.0) / 2.0) * dot_step, radius);
		}
		return dots;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
		View.onUpdate(dc);

        var time_short = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        drawTime(dc, time_short.hour, time_short.min);
        drawBattery(dc, System.getSystemStats().battery);
    	drawDate(dc, time_short.month, time_short.day);    	
    	drawStatus(dc);

        drawBottomLeftInfo(dc);
        drawBottomRightInfo(dc);

        if (can_burn_in) {
        	if (in_low_power) {
        		for (var i = 0; i < burn_in_grid_horizontal; ++i) {
        			for (var j = 0; j < burn_in_grid_vertical; ++j) {
						dc.drawBitmap(i * burn_in_grid_width + burn_in_grid_offset, j * burn_in_grid_height, burn_in_grid);
        			}
        		}
        		burn_in_grid_offset = (burn_in_grid_offset == 0) ? -1 : 0;
        	}
    	}
    }

    function drawTime(dc, hour, minute) {
        var hour_string = hour.format("%02d");
        var minute_string = minute.format("%02d");
		dc.setColor(primary_color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(hour_position[0], hour_position[1], font_large, hour_string, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.setColor(secondary_color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(minute_position[0], minute_position[1], font_large, minute_string, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawDate(dc, month, date) {
    	var date_string = date.format("%02d");
    	dc.setColor(primary_color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(left, top, font_small, date_string, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
   		for(var i = 0; i < months_positions.size(); ++i) {
   			if (i < month) {
   				dc.setColor(primary_color, Graphics.COLOR_TRANSPARENT);
   			} else {
				if (i == months_positions.size() - 1) {
   					dc.setColor(secondary_off_color, Graphics.COLOR_TRANSPARENT);
				} else {
   					dc.setColor(primary_off_color, Graphics.COLOR_TRANSPARENT);
				}
			}
   			dc.fillCircle(months_positions[i][0], months_positions[i][1], dot_thickness);
   		}
   		dc.setColor(primary_color, Graphics.COLOR_TRANSPARENT);
	}
	
	function drawStatus(dc) {
		var device_settings = System.getDeviceSettings();
		var status = "";
		if (!device_settings.phoneConnected) {
			status += "V";
		}
    	dc.setColor(error_color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(right, top, font_icons, status, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
	}
	
	function drawBottomLeftInfo(dc) {
		drawInfo(dc, Application.Properties.getValue("info_bottom_left"), [left, bottom], Graphics.TEXT_JUSTIFY_LEFT);
	}
	
	function drawBottomRightInfo(dc) {
		drawInfo(dc, Application.Properties.getValue("info_bottom_right"), [right, bottom], Graphics.TEXT_JUSTIFY_RIGHT);
	}

	function drawInfo(dc, info_type, position, orientation) {
		var info = null;
		switch(info_type) {
			case 1: // info_name_notifications
				info = getNotification(dc);
				break;
			case 2: // info_name_calories
				info = getCalories(dc);
				break;
			case 3: // info_name_heart_rate
				info = getHeartRate(dc);
				break;
			case 0: // info_name_empty
			default:
				return;
		}
		if (info == null) {
			return;
		}

		var font_icons_direction = (orientation == Graphics.TEXT_JUSTIFY_RIGHT) ? -1 : 1;
    	dc.setColor(primary_color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(position[0], position[1], font_icons, info[0], orientation | Graphics.TEXT_JUSTIFY_VCENTER);
   		dc.drawText(position[0] + font_icons_direction * font_icons_offset, position[1], font_small, info[1], orientation | Graphics.TEXT_JUSTIFY_VCENTER);
	}
    
    function drawBattery(dc, battery) {
        var battery_position = (battery / 100.0) * battery_positions.size() - 0.5;
    	var battery_color = primary_color;
		if (battery_position >= battery_positions.size() - 1) {
			battery_color = good_color;
		} else if (battery < 16.7) {
			battery_color = error_color;
		} else if (battery < 33.3) {
			battery_color = warning_color;
		} else {
			battery_color = primary_color;
		}
        
		for(var i = 0; i < battery_positions.size(); ++i) {
			if(i <= battery_position) {
   					dc.setColor(battery_color, Graphics.COLOR_TRANSPARENT);
			} else {
				if (i == battery_positions.size() - 1) {
   					dc.setColor(secondary_off_color, Graphics.COLOR_TRANSPARENT);
				} else {
   					dc.setColor(primary_off_color, Graphics.COLOR_TRANSPARENT);
				}
			}
   			dc.fillCircle(battery_positions[i][0], battery_positions[i][1], dot_thickness);
   		}	
	}

	function getNotification(dc) {
		var device_settings = System.getDeviceSettings();
		if (!device_settings.phoneConnected) {
			return null;
		}
		var notification_count = device_settings.notificationCount;
		if (notification_count == 0) {
			return null;
		}
		var notification_string = notification_count.format("%u");
		return ['2', notification_count.format("%u")];
    }
	
	function getCalories(dc) {
		var info = ActivityMonitor.getInfo();
		if (info == null || info.calories == null) {
			return null;
		}
		return ['X', info.calories.format("%u")];
    }
    
    function getHeartRate(dc) {
    	var hr_string = "--";
		var hr_iterator = ActivityMonitor.getHeartRateHistory(heart_rate_period, true);
    	var hr = null;
    	do {
    		var hr = hr_iterator.next();
    		if (hr != null && hr.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
    			hr_string = hr.heartRate.format("%u");
    			break;
    		}
    	} while (hr != null);
    	return ['m', hr_string];
    
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	in_low_power = false;
    	WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow update.
    function onEnterSleep() {
    	in_low_power = true;
    	WatchUi.requestUpdate();
    }

}
