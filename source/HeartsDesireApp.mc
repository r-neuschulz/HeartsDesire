using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Toybox.Time as Time;

// info about whats happening with the background process
var _counter=0;
var _bgdata="none";
var _canDoBG=false;
var _inBackground=false;			//new 8-27


// keys to the object storage
var OSDATA="osdata";
var OSCOUNTER="oscounter";

(:background)
class heartsDesireApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();

    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");

    	//you'll see this gets called in both the foreground and background        
        Sys.println("App initialize "+ts);
        var temp=App.Storage.getValue(OSCOUNTER);

        //var temp=null;

        if(temp!=null && temp instanceof Number) {_counter=temp;}
        Sys.println("Counter in App initialize: "+_counter);        
    }

    // onStart() is called on application start up
    function onStart(state) {
		Sys.println("onStart");   
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	//moved from onHide() - using the "is this background" trick
    	if(!_inBackground) {
	    	var now=Sys.getClockTime();
    		var ts=now.hour+":"+now.min.format("%02d");        
        	Sys.println("onStop _counter="+_counter+" "+ts);    
    		App.Storage.setValue(OSCOUNTER, _counter);     
    	} else {
    		Sys.println("onStop");
    	}
    }

    // Return the initial view of your application here
    function getInitialView() {
    	Sys.println("getInitialView");
		//register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
    		_canDoBG=true;
    		Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    	} else {
    		Sys.println("****background not available on this device****");
    	}
        return [ new heartsDesireView() ];
    }
    
    function onBackgroundData(data) {
    	_counter++;
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        Sys.println("onBackgroundData="+data+" "+_counter+" at "+ts);
        _bgdata=data;
        App.Storage.setValue(OSDATA, _bgdata);
        Ui.requestUpdate();
    }    

    function getServiceDelegate(){
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");    
    	Sys.println("getServiceDelegate: "+ts);
        return [new BgbgServiceDelegate()];
    }
    
    function onAppInstall() {
    	Sys.println("onAppInstall");
    }
    
    function onAppUpdate() {
    	Sys.println("onAppUpdate");
    }
}