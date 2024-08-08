using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.UserProfile as Up;

class heartsDesireView extends Ui.WatchFace {

    //! Instance variable to store heart rate zones and font
    private var heartRateZones as Lang.Array or Null;
    private var bigNumProtomolecule as Ui.FontResource or Null;
    private var width, height as Lang.Number or Null;

    private var u = 0;

    private function getSensorRateIterator() {
        Sys.println("[" + Sys.getTimer() + "] getSensorRateIterator() - Getting heart rate iterator");

        // Check device for SensorHistory compatibility
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getHeartRateHistory)) {
            var sixHours = new Time.Duration(21600);  // Six hours in seconds
            Sys.println("[" + Sys.getTimer() + "] getSensorRateIterator() - Invoking getHeartRateHistory method");

            return Toybox.SensorHistory.getHeartRateHistory({:period => sixHours, :order => SensorHistory.ORDER_OLDEST_FIRST});
        }

        return null;
    }

    function initialize() {
        WatchFace.initialize();
        
        //read last values from the Object Store
        //counter now read in app initialize
        //var temp=App.getApp().getProperty(OSCOUNTER);
        //if(temp!=null && temp instanceof Number) {counter=temp;}
 
        //var temp=App.getApp().getProperty(OSDATA);
        var temp=null;
        if(temp!=null && temp instanceof String) {_bgdata=temp;}
        
        var now = Sys.getClockTime();
    	var ts = now.hour + ":" + now.min.format("%02d");
        
        Sys.println("From OS: data="+ _bgdata + " " + _counter + " at "+ts);        
    
        // My Code
        // Init the correct font        
        bigNumProtomolecule = Ui.loadResource(Rez.Fonts.protomoleculefont);
        System.println("[" + System.getTimer() + "] initialize() - Font loaded: " + bigNumProtomolecule);

        // Determine and store HRZones once
        heartRateZones = UserProfile.getHeartRateZones(Up.HR_ZONE_SPORT_GENERIC);
        System.println("[" + System.getTimer() + "] initialize() - Heart rate zones: " + heartRateZones.toString());


    }

    // Load your resources here
    function onLayout(dc) {
        System.println("[" + System.getTimer() + "] onLayout() - onLayout started");

        width = dc.getWidth();
        height = dc.getHeight();

        System.println("[" + System.getTimer() + "] onLayout() - Screen dimensions: width=" + width + ", height=" + height);
     }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        u++;

        // Get and show the current time
        var clockTime = Sys.getClockTime();
        var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
		
		// Clear the DC
        
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
		dc.clear();


		dc.setColor(Gfx.COLOR_BLUE,Gfx.COLOR_TRANSPARENT);
		
		dc.drawText(width/2,height-40,Gfx.FONT_XTINY,timeString,Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText(width/2,height-60,Gfx.FONT_XTINY,"BG Available? "+_canDoBG,Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText(width/2,height-80,Gfx.FONT_XTINY,"Count="+_counter,Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText(width/2,height-100,Gfx.FONT_XTINY,"_bgdata="+_bgdata,Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText(width/2,height-120,Gfx.FONT_XTINY,"onUpdate="+u,Gfx.TEXT_JUSTIFY_CENTER);
    
        // My Functions

        System.println("[" + System.getTimer() + "] onUpdate() - Updating view");


        // Get and show the current time
        var showClockTime = System.getClockTime();
        var timeStringHH = Lang.format("$1$", [showClockTime.hour.format("%02d")]);
        var timeStringMM = Lang.format("$1$", [showClockTime.min.format("%02d")]);

        System.println("[" + System.getTimer() + "] onUpdate() - Updating view");


        // Draw HH part
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, height * 0.28, bigNumProtomolecule, timeStringHH, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw MM part
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, height * 0.60, bigNumProtomolecule, timeStringMM, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw HR Graph
        var sensorIter = getSensorRateIterator();

        // Nullcheck the sensorIterator
        if (sensorIter == null) {
            System.println("[" + System.getTimer() + "] onUpdate() - No heart rate data available");
            return;
        }

        var graphBottom = height;
        var graphHeight = height * 0.40;
        var graphWidth = width;

        // Determine the total time span in the data
        var oldestTimeMoment = sensorIter.getOldestSampleTime() as Toybox.Time.Moment or Null;
        var newestTimeMoment = sensorIter.getNewestSampleTime() as Toybox.Time.Moment or Null;

        // Nullcheck the TimeMoments
        if (oldestTimeMoment == null || newestTimeMoment == null) {
            System.println("[" + System.getTimer() + "] onUpdate() - Time moments are null");
            return;
        }

        var oldestTime = oldestTimeMoment.value() as Lang.Number or Null;
        var newestTime = newestTimeMoment.value() as Lang.Number or Null;

        if (oldestTime == null || newestTime == null) {
            System.println("[" + System.getTimer() + "] onUpdate() - Oldest or newest time is null");
            return;
        }

        System.println("[" + System.getTimer() + "] onUpdate() - Oldest time: " + oldestTime);
        System.println("[" + System.getTimer() + "] onUpdate() - Newest time: " + newestTime);

        var totalDuration = newestTime - oldestTime;
        System.println("[" + System.getTimer() + "] onUpdate() - Total duration: " + totalDuration);

        // Getting the next sample
        var sample = sensorIter.next();
        // Nullchecking the next sample
        if (sample == null) {
            System.println("[" + System.getTimer() + "] onUpdate() - No samples found");
            return;
        }
        
        var nextSample = sample;
        var nextSampleTime = sample.when.value() as Lang.Number or Null;

        System.println("[" + System.getTimer() + "] onUpdate() - Starting graph drawing loop");
        
        //Don't paint the graph entirely left to right, only make it look like it would at RHR.
        var reducedWidth = 0.87*graphWidth;

        for (var x = 0; x < reducedWidth; x++) {
            // Calculate the target time for this x position
            var targetTime = oldestTime + (totalDuration * x / graphWidth);

            // Find the nearest sample to the target time
            while (nextSampleTime != null && nextSampleTime < targetTime) {
                sample = nextSample;
                nextSample = sensorIter.next();
                nextSampleTime = (nextSample != null) ? nextSample.when.value() : null;
            }

            if (sample != null && sample.data != null) {
                var heartRate = sample.data;
                var y = graphBottom*1.0 - (heartRate*1.0 / heartRateZones[5]*1.0) * graphHeight;

                // Color it, depending on the HR Zones, currently set for Running
                if (heartRate < heartRateZones[0]) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
                } else if (heartRate <= heartRateZones[1]) {
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
                } else if (heartRate <= heartRateZones[2]) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                } else if (heartRate <= heartRateZones[3]) {
                    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
                } else if (heartRate <= heartRateZones[4]) {
                    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_ORANGE);
                } else {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                }

                //Printing one element of the loop here
                if (x == 0){
                    Sys.println("[" + Sys.getTimer() + "] onUpdate() - Drawing heart rate at x=" + x + ", y=" + y);
                }

                dc.drawLine(x, graphBottom, x, y);
            }
        }
    
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    	//may not be called on real watch  Moved to onStop()
    	//var now=Sys.getClockTime();
    	//var ts=now.hour+":"+now.min.format("%02d");        
        //Sys.println("onHide counter="+counter+" "+ts);    
    	//App.getApp().setProperty(OSCOUNTER, counter);    
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
