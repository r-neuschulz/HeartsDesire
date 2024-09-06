using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.UserProfile as Up;
using Toybox.ActivityMonitor as Act;
using Toybox.Activity as Acty;

class heartsDesireView extends Ui.WatchFace {

    //! Instance variable to store heart rate zones and font
    private var heartRateZones as Lang.Array or Null;
    private var bigNumProtomolecule as Ui.FontResource or Null;
    private var width, height as Lang.Number or Null;

    // private var u = 0;

    private function getSensorRateIterator() {
        Sys.println("[" + Sys.getTimer() + "] getSensorRateIterator() - Getting heart rate iterator");

        // Check device for SensorHistory compatibility
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getHeartRateHistory)) {
            return Toybox.SensorHistory.getHeartRateHistory({:period => 360, :order => SensorHistory.ORDER_OLDEST_FIRST});
        }

        return null;
    }

    private function getHeartRateColor(inheartRate, inheartRateZones as Lang.Array or Null) {
        if (inheartRate < inheartRateZones[0]) {
            return Graphics.COLOR_WHITE;
        } else if (inheartRate <= inheartRateZones[1]) {
            return Graphics.COLOR_LT_GRAY;
        } else if (inheartRate <= inheartRateZones[2]) {
            return Graphics.COLOR_BLUE;
        } else if (inheartRate <= inheartRateZones[3]) {
            return Graphics.COLOR_GREEN;
        } else if (inheartRate <= inheartRateZones[4]) {
            return Graphics.COLOR_ORANGE;
        } else {
            return Graphics.COLOR_RED;
        }
    }


    function initialize() {
        WatchFace.initialize();
        
        //read last values from the Object Store
        var temp=null;
        if(temp!=null && temp instanceof String) {_bgdata=temp;}
        
        // Init the correct font        
        bigNumProtomolecule = Ui.loadResource(Rez.Fonts.protomoleculefont);
        // System.println("[" + System.getTimer() + "] initialize() - Font loaded: " + bigNumProtomolecule);

        // Determine and store HRZones once
        heartRateZones = UserProfile.getHeartRateZones(Up.HR_ZONE_SPORT_GENERIC);
        // System.println("[" + System.getTimer() + "] initialize() - Heart rate zones: " + heartRateZones.toString());


    }

    // Load your resources here
    function onLayout(dc) {
        // System.println("[" + System.getTimer() + "] onLayout() - onLayout started");

        width = dc.getWidth();
        height = dc.getHeight();

        // System.println("[" + System.getTimer() + "] onLayout() - Screen dimensions: width=" + width + ", height=" + height);
     }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // // Display Debug Information
        
        // u++;

        // // Get and show the current time
        // var clockTime = Sys.getClockTime();
        // var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
		
		


		// dc.setColor(Gfx.COLOR_BLUE,Gfx.COLOR_TRANSPARENT);
		
		// dc.drawText(width/2,height-40,Gfx.FONT_XTINY,timeString,Gfx.TEXT_JUSTIFY_CENTER);
		// dc.drawText(width/2,height-60,Gfx.FONT_XTINY,"BG Available? "+_canDoBG,Gfx.TEXT_JUSTIFY_CENTER);
		// dc.drawText(width/2,height-80,Gfx.FONT_XTINY,"Count="+_counter,Gfx.TEXT_JUSTIFY_CENTER);
		// dc.drawText(width/2,height-100,Gfx.FONT_XTINY,"_bgdata="+_bgdata,Gfx.TEXT_JUSTIFY_CENTER);
		// dc.drawText(width/2,height-120,Gfx.FONT_XTINY,"onUpdate="+u,Gfx.TEXT_JUSTIFY_CENTER);
    
        // My Functions

        // System.println("[" + System.getTimer() + "] onUpdate() - Updating view");

        // // Clear the DC
        
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
		dc.clear();

        // Get and show the current time
        var showClockTime = System.getClockTime();
        var timeStringHH = Lang.format("$1$", [showClockTime.hour.format("%02d")]);
        var timeStringMM = Lang.format("$1$", [showClockTime.min.format("%02d")]);

        // System.println("[" + System.getTimer() + "] onUpdate() - Updating view");


        // Draw HH part
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, height * 0.20, bigNumProtomolecule, timeStringHH, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw MM part
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, height * 0.53, bigNumProtomolecule, timeStringMM, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw HR Graph
        var sensorIter = getSensorRateIterator();

        // Nullcheck the sensorIterator
        if (sensorIter == null) {
            // System.println("[" + System.getTimer() + "] onUpdate() - No heart rate data available");
            return;
        }

        var graphBottom = height;
        var graphHeight = height * 0.43;
        var graphWidth = width;

        
        // System.println("[" + System.getTimer() + "] onUpdate() - Total duration: " + totalDuration);

        System.println("[" + System.getTimer() + "] onUpdate() - Starting graph drawing loop");
        
        var reducedWidth = (0.88 * graphWidth);  // Convert to integer not needed
        var yCoordinates = new [reducedWidth + 1]; // Array to store the y coordinates
        var colorArray = new [reducedWidth + 1];   // Array to store the colors

        // Assuming sensorData is the array containing the heart rate samples
        var totalSamples = sensorIter;
        var indices = new [reducedWidth + 1];
        var stepSize = totalSamples / reducedWidth;

        // Calculate the index array
        for (var x = 0; x <= reducedWidth; x++) {
            indices[x] = (x * stepSize).toNumber;
        }

        // Iterate through the precomputed index array
        for (var x = 0; x <= reducedWidth; x++) {
            var sampleIndex = indices[x];
            var sample = sensorIter[sampleIndex];  // Fetch the heart rate sample

            if (sample != null && sample.data != null) {
                var heartRate = sample.data;
                var y = graphBottom * 1.0 - (heartRate * 1.0 / heartRateZones[5] * 1.0) * graphHeight;
                yCoordinates[x] = y;
                colorArray[x] = getHeartRateColor(heartRate, heartRateZones);
            } else {
                yCoordinates[x] = graphBottom; // Default to graphBottom if no data
                colorArray[x] = Graphics.COLOR_WHITE; // Default to white color if no data
            }
        }

        // Second loop: Draw the graph and the black outline
        for (var x = 0; x < reducedWidth; x++) {
            var y = yCoordinates[x];
            var prevY = (x > 0) ? yCoordinates[x - 1] : graphBottom;
            var nextY = (x < reducedWidth - 1) ? yCoordinates[x + 1] : graphBottom;

            // Set the color based on the stored color array
            dc.setColor(colorArray[x], colorArray[x]);

            // Printing one element of the loop here
            // if (x == 0) {
            //     Sys.println("[" + Sys.getTimer() + "] onUpdate() - Drawing heart rate at x=" + x + ", y=" + y);
            // }

            // Draw the original line
            dc.drawLine(x, graphBottom, x, y);

            

            var outlineY = y + 1; // Start with y + 1 as the initial value

            if (prevY != null && prevY + 1 > outlineY) {
                outlineY = prevY + 1; // Update if prevY + 1 is greater
            }

            if (nextY != null && nextY + 1 > outlineY) {
                outlineY = nextY + 1; // Update if nextY + 1 is greater
            }
            Sys.println("[" + Sys.getTimer() + "] onUpdate() - Drawing heart rate at x=" + x + ", y=" + y);
            
            // Draw the black outline line on top
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.drawLine(x, y, x, outlineY);
        }



        var heartRate = 0;
        var currentHeartRate = Activity.getActivityInfo().currentHeartRate;

        if (currentHeartRate != null) {
            heartRate = currentHeartRate;
        }

        if (currentHeartRate == null && Act has :getHeartRateHistory) {
            var HRH = Act.getHeartRateHistory(1, true);
            var HRS = HRH.next();

            if (HRS != null && HRS.heartRate != Act.INVALID_HR_SAMPLE) {
                heartRate = HRS.heartRate;
            }
        }

        var heartRateColor = getHeartRateColor(heartRate, heartRateZones);

        dc.setColor(heartRateColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/1.3,height-180,Gfx.FONT_TINY,heartRate.toString(),Gfx.TEXT_JUSTIFY_CENTER);

        
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
