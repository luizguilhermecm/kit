window.onload = function onLoad() {
	function Clock(year, month, day, hour, minute, name, description) {
	  var self = this;
		var NAME = name;
		var YY = year;
		var MM = month;
		var DD = day;
		var HH = hour;
		var MI = minute;
	  var ss, mm, hh, dd;
		self.description = description;

		self.urgency = function(object, value, total) {
			if (value < 0) {
				object.animate(0,
		        	{
					    from: { color: '#fe2801' },
					    to: { color: '#fe2801' },
					    step: function(state, circle, attachment) {
					        circle.path.setAttribute('stroke', state.color);
					    }
					}, function() {object.setText(0)}
			    );
			} else {
		        var percentage = value / total;
		        if (percentage <= 0.1) {
		        	object.animate(value/total,
			        	{
						    from: { color: '#fe2801' },
						    to: { color: '#fe2801' },
						    step: function(state, circle, attachment) {
						        circle.path.setAttribute('stroke', state.color);
						    }
						}, function() {object.setText(value)}
				    );
		        } else if (percentage <= 0.2) {
		        	object.animate(value/total,
			        	{
						    from: { color: '#f86512' },
						    to: { color: '#f86512' },
						    step: function(state, circle, attachment) {
						        circle.path.setAttribute('stroke', state.color);
						    }
						}, function() {object.setText(value)}
				    );
		        } else if (percentage <= 0.5) {
		            object.animate(value/total,
			        	{
						    from: { color: '#ffff00' },
						    to: { color: '#ffff00' },
						    step: function(state, circle, attachment) {
						        circle.path.setAttribute('stroke', state.color);
						    }
						}, function() {object.setText(value)}
				    );
		        } else {
		        	object.animate(value/total,
			        	{
						    from: { color: '#51dd16' },
						    to: { color: '#51dd16' },
						    step: function(state, circle, attachment) {
						        circle.path.setAttribute('stroke', state.color);
						    }
						}, function() {object.setText(value)}
				    );
				}
			}
	    }

	    self.refresh = function() {
	        var SS = 00;
	        var today = new Date();
	        var future = new Date(YY, MM - 1, DD, HH, MI, SS);
	        ss = parseInt((future - today) / 1000);
	        mm = parseInt(ss / 60);
	        hh = parseInt(mm / 60);
	        dd = parseInt(hh / 24);
	        ss = ss - (mm * 60);
	        mm = mm - (hh * 60);
	        hh = hh - (dd * 24);

	        self.urgency(self.circle_days, dd, 30);
	        self.urgency(self.circle_hours, hh, 24);
	        self.urgency(self.circle_minutes, mm, 60);
	        self.urgency(self.circle_seconds, ss, 60);
	    }

	    self.addElement = function(element) {
			$(element).append(
			'<div class="reminder">' +
				'    <div class="clocks">' +
			'        <div id="' + name + '_days" class="clock"></div>' +
			'        <div id="' + name + '_hours" class="clock"></div>' +
			'        <div id="' + name + '_minutes" class="clock"></div>' +
			'        <div id="' + name + '_seconds" class="clock"></div>' +
      '    <div class="description">' +
			'        <br><p id="' + name + '_descriptions">' + self.description + ' - ' + DD + ' / ' + MM + ' / ' + YY + '</p>' +
			'    </div>' +
			'    </div>' +
			'</div>');

			self.circle_days = new ProgressBar.Circle('#' + name + '_days', {
                color: '#111',
                trailColor: 'black',
                strokeWidth: 8,
                trailWidth: 1,
                duration: 200
            });
			self.circle_hours = new ProgressBar.Circle('#' + name + '_hours', {
                color: '#111',
                trailColor: 'black',
                strokeWidth: 8,
                trailWidth: 1,
                duration: 200
            });
			self.circle_minutes = new ProgressBar.Circle('#' + name + '_minutes', {
                color: '#111',
                trailColor: 'black',
                strokeWidth: 8,
                trailWidth: 1,
                duration: 200
            });
			self.circle_seconds = new ProgressBar.Circle('#' + name + '_seconds', {
                color: '#111',
                trailColor: 'black',
                strokeWidth: 8,
                trailWidth: 1,
                duration: 200
            });
	    }

	    return self;
	}

	function Countdown() {
		var self = this;
		self.oid = 0;

		self.add = function (day, month, year, hour, minute, description) {
	    	var clock = new Clock(year, month, day, hour, minute, "clock" + self.oid, description);
	    	clock.addElement("#contador");
	    	self.oid++;
	    	setInterval(function(){clock.refresh()}, 1000);

	    	return self;
	    }

	    return {
	    	add: self.add
	    }
	}

	var countdown = new Countdown();

	countdown
		.add(12,11,2016,6,20, "Guarulhos")
}
