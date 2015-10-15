var looptime = 0.3;


var bendload = props.globals.getNode("sim/failure/bendload");
var breakload = props.globals.getNode("sim/failure/breakload");
var breakspeed = props.globals.getNode("sim/failure/breakspeed");
var maxpermrpm = props.globals.getNode("sim/failure/max-permiss-rpm");
var maxpermboost = props.globals.getNode("sim/failure/max-permiss-boost");
var emptyweight = props.globals.getNode("sim/failure/emptyweight");
var airspeed = props.globals.getNode("velocities/airspeed-kt");
var rstrain = props.globals.getNode("sim/failure/engines/engine[0]/rev-strain");
var oboost = props.globals.getNode("sim/failure/engines/engine[0]/boost-strain");
var nofuel = props.globals.getNode("engines/engine[0]/out-of-fuel",1 );
var gload = props.globals.getNode("accelerations/pilot-g",1);
var weight = props.globals.getNode("yasim/gross-weight-lbs",1);
var turn = props.globals.getNode("instrumentation/turn-indicator/indicated-turn-rate");
var fail_r = props.globals.getNode("sim/failure/controls/right-wing-failure");
var fail_l = props.globals.getNode("sim/failure/controls/left-wing-failure");




var main_loop = func {
	check_engine();
	check_airframe();
  settimer(main_loop, looptime);
}

var check_airframe = func {
	if (fail_r.getValue() <= 0.5 and fail_l.getValue() <= 0.5 ) {
		var gl = gload.getValue();
		var gw = weight.getValue();
		var as = airspeed.getValue();
		var slip = turn.getValue();
		var fail = fail_r.getValue();
		var emptyw = emptyweight.getValue();
		var breakld = breakload.getValue();
		var bendld = bendload.getValue();
		var breakspd = breakspeed.getValue();
		var ow = gw - emptyw;
			#print(gl, breakld - 0.0004 * ow );
		if (gl > (breakld - 0.0003 * ow) or (as > breakspd)) {
			print ("break");
			if (slip < 0) {
				fail_r.setValue(1);
			} else {
				fail_l.setValue(1);
			}
		}
		if (gl > (bendld - 0.0004 * ow)) {
			print ("bend");
		}		
	}
}

var check_engine = func {
		var rs = rstrain.getValue();
		var ob = oboost.getValue();
		#check for overrev

		if (rs > 300000 ) {
				setprop("sim/failure/engines/engine[0]/overrev", 1);
				kill_engine();
		}	
		#check for overboost

	if (ob > 500 ) {
				setprop("sim/failure/engines/engine[0]/overboost", 1);
				kill_engine();
	}
}

var kill_engine = func {
		nofuel.setValue(1);
		nofuel.setAttribute("writable", 0);
		interpolate ("/engines/engine[0]/fuel-press", 0, 1);
		interpolate ("/engines/engine[0]/mp-osi", 0, 1.5);
}

var init = func {

		print ("Los gehts!");
 	 }  
 	 settimer(main_loop, looptime);

setlistener("/sim/signals/fdm-initialized",init);
