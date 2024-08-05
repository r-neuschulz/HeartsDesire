//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;

import Toybox.System;
import Toybox.WatchUi;

//! Display graph of heart rate history
class HeartRateHistoryView extends WatchUi.View {

    //! Constructor
    public function initialize() {
        View.initialize();
    }

    //! Get the heart rate iterator
    //! @return The heart rate iterator
    private function getHeartRateIterator() as SensorHistoryIterator? {
        if (Toybox has :SensorHistory && SensorHistory has :getHeartRateHistory) {
            var getMethod = new Lang.Method(SensorHistory, :getHeartRateHistory);
            return getMethod.invoke({}) as SensorHistoryIterator;
        }
        return null;
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        

        if (Toybox has :SensorHistory) {
            var sensorIter = getHeartRateIterator();
            if (sensorIter != null) {
                var sample = sensorIter.next();
                var x = 0;
                var graphBottom = dc.getHeight();
                var graphHeight = graphBottom * 0.35;

                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);

                while (sample != null) {
                    var heartRate = sample.data;
                    if (heartRate != null) {
                        var y = graphBottom - (heartRate / 200.0) * graphHeight;
                        dc.drawLine(x, graphBottom, x, y);
                    }
                    x++;
                    sample = sensorIter.next();
                }

            } else {
                var message = "Heart Rate\nSensor not available";
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, message, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));
            }

        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            var message = "Sensor History\nNot Supported";
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, message, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));
        }

        // Get and show the current time
        var clockTime = System.getClockTime();
        var timeStringHH = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var timeStringMM = Lang.format("$1$", [clockTime.min.format("%02d")]);

        // Draw HH part
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.10, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, timeStringHH, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw MM part
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.40, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, timeStringMM, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

    }
}
