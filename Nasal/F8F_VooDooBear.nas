init = func {

  if (getprop("/controls/engines/engine[0]/on-startup-running") == 1) {
		magicstart();
	setprop ("instrumentation/altimeter/pressure-alt-ft",10);
  }  
   main_loop();
   }
    setlistener("/controls/fuel/switch-position", func(n) {
	position=n.getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
        if(position >= 0.0){
           if(getprop("/engines/engine[0]/overrev") == 0){
             if(getprop("/engines/engine[0]/overheat") == 0){
               setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
  }
      };
    };
   },1);
    setlistener("/controls/engines/engine[0]/primer", func(n) {
	pos2=n.getValue();
        if(pos2 > 0.9){

               setprop("/engines/engine[0]/out-of-fuel",0);
      
    };
   },1);
    setlistener("/controls/engines/engine[0]/throttle", func(n) {
	pos3=n.getValue();
        if(pos3 >= 0.7){
           setprop("/controls/engines/engine[0]/prop-auto",1);
    };
   },1);
    setlistener("engines/engine[0]/running", func(n) {
	pos4=n.getValue();
        if(pos4 == 0.0){
           interpolate ("engines/engine[0]/fuel-press",0,3);
           interpolate ("engines/engine[0]/oil-press",0,3);
    };
   },1);
main_loop = func {

#### Set boost level

	var alt = "instrumentation/altimeter/pressure-alt-ft";
	var boost = "controls/engines/engine[0]/boost";
	if (getprop(alt) > 12000) {
		setprop (boost, 1.0);
		}
	if (getprop(alt) < 12000) {
		setprop (boost, 0.5);
		}
	
#### prop-adjust  
  if (getprop("/controls/engines/engine[0]/prop-auto") == 1) {  
		var	revs = getprop("/engines/engine[0]/rpm");
    ppitch = getprop("/controls/engines/engine[0]/propeller-pitch");
    mpress = getprop("/engines/engine/mp-osi");  
    revs = getprop("/engines/engine[0]/rpm");
      if (revs / mpress < 55.0)  {
          setprop("/controls/engines/engine[0]/propeller-pitch", ppitch + 0.003);
          }
      if (revs / mpress > 55.0)  {
          setprop("/controls/engines/engine[0]/propeller-pitch", ppitch - 0.003);
          }
    
### kill engine when overreved
  }
  rev2 = getprop("/engines/engine[0]/rpm");
  rstrain = getprop("/engines/engine[0]/rev-strain");
  if (rstrain > 350000) {
    setprop("/engines/engine[0]/overrev", 1);
    setprop("/engines/engine[0]/running", 0);
    setprop("/engines/engine[0]/out-of-fuel", 1);
    setprop("/consumables/fuel/tank[0]/selected",0);
    interpolate ("/engines/engine[0]/fuel-press", 0, 1);
    }
  if (rev2 > 2800) {
    strain = rev2 - 2800;
    setprop("/engines/engine[0]/rev-strain", rstrain + strain);
  }
  

### coolant temp
  if (getprop("/engines/engine[0]/running") == 1) {
    rev = getprop("/engines/engine[0]/rpm");
    thrust = getprop("/engines/engine[0]/prop-thrust");
#    print ("#");
#    print ( thrust );
    ctemp = getprop("/engines/engine[0]/coolant-temp-degc");
#    print ( ctemp );
    cpos = getprop("/controls/engines/engine[0]/cowl-flaps-norm");
#    print ( cpos );
    airspeed = getprop("/velocities/airspeed-kt");
#    print ( airspeed );
    temp = getprop("/environment/temperature-degc");
#    print ( temp );
    dtemp = 0.008*((0.007*thrust+temp)-0.2*(1.5*(airspeed*cpos+55)));
#    print ( dtemp );
    newtemp = (ctemp + dtemp);
#    print (newtemp);
    setprop ("/engines/engine[0]/coolant-temp-degc" , newtemp);

### fuel pressure
		interpolate ("engines/engine[0]/fuel-press", 1.5, 3);

### oil and viscosity


    otemp = getprop("engines/engine[0]/oil-temperature-degf");
    visc = getprop("engines/engine[0]/oil-visc");
		interpolate ("engines/engine[0]/oil-press", 8.2 - 2*visc, 1);
    if (visc < 1.0 ) {
      setprop("engines/engine[0]/oil-visc", visc + 0.002);
			setprop("engines/engine[0]/oiltempc", otemp *visc);
      if (rev2 > 1000) {
           setprop("/engines/engine[0]/rev-strain", rstrain + (600/visc));
      }
    }     
### kill engine when overheated

    if (newtemp > 135) {
      setprop("/engines/engine[0]/overheat", 1);
      setprop("/engines/engine[0]/running", 0);
      setprop("/engines/engine[0]/out-of-fuel", 1);
   		setprop("/consumables/fuel/tank[0]/selected",0);
      interpolate ("/engines/engine[0]/fuel-press", 0, 3);
      interpolate ("/engines/engine[0]/oil-press", 0, 1);
    }
  }
### automatic coolflap adjustment

  if (getprop("/controls/engines/engine[0]/coolflap-auto") == 1) {
    ctemp = getprop("/engines/engine[0]/coolant-temp-degc");
    cpos = getprop("/controls/engines/engine[0]/cowl-flaps-norm");
    npos = cpos;
    if (ctemp < 65) {
      npos = cpos - 0.05;
      } 
      if (ctemp > 85) {
      npos = cpos + 0.05;
      }
    
    interpolate ("/controls/engines/engine[0]/cowl-flaps-norm" , npos, 0.5 );
  }
  
  settimer(main_loop, 0.2)
  
} 


toggle_canopy = func {
  canopy = aircraft.door.new ("/controls/canopy/",3);
  if(getprop("/controls/canopy/position-norm") > 0) {
      canopy.close();
  } else {

      canopy.open();
  }
}

toggle_revi = func {
  revi = aircraft.door.new ("/controls/armament/revi",2);
  if(getprop("/controls/armament/revi/position-norm") > 0) {
      revi.close();
  } else {

      revi.open();
  }
}

fire_MG = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
     setprop("/controls/armament/trigger", 1);
		if (getprop("/sim/weight[1]/weight-lb") == 110)  {
    	 setprop("/controls/armament/trigger2", 1);
		}
     } 
}
stop_MG = func {
     setprop("/controls/armament/trigger", 0); 
     setprop("/controls/armament/trigger2", 0);
}

fire_cannon = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
     setprop("/controls/armament/trigger1", 1);
     } 
}
stop_cannon = func {
     setprop("/controls/armament/trigger1", 0); 
}

fire_wgr = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
  rcount=getprop("/sim/weight[1]/weight-lb");
  if(rcount > 20){
    if(rcount == 270)  {
     setprop("/controls/armament/wgr", 1)
     } 
  setprop("sim/weight[1]/weight-lb", rcount - 250.0);
  setprop("sim/weight[2]/weight-lb", rcount - 250.0);
  }
 }
}

drop_bomb = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
  rcount=getprop("/sim/weight[0]/weight-lb");
  if(rcount > 49){
     setprop("/controls/armament/station/release-all", 1);
     setprop("/sim/weight[0]/selected","none");
     } 
 }
}


drop_tank = func {
  rcount=getprop("/sim/weight[0]/weight-lb");
  if(rcount > 49){
     setprop("/controls/armament/station/release-tank", 1);
     setprop("/sim/weight[0]/selected","none");
     setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[1]/level-gal_us",0);
    setprop("/consumables/fuel/tank[1]/level-lbs",0);
    setprop("/consumables/fuel/tank[1]/capacity-gal_us",0);
     } 
 }

starter = func {
	starter_power = getprop("/systems/electrical/volts");
	if(starter_power == nil)
		{starter_power = 0;}
	if (arg[0] == 1){
		if( starter_power > 5.0){ 
			setprop("/controls/engines/engine[0]/starter",1);
		}
		}else{
			setprop("/controls/engines/engine[0]/starter",0);}	
	}

fuel_jettison = func {
  remaining = getprop("consumables/fuel/tank[0]/level-gal_us");
  interpolate("consumables/fuel/tank[0]/level-gal_us", (remaining-20),5);
}

open_coolflaps = func {
      setprop("/controls/engines/engine[0]/coolflap-auto",0);
      interpolate("controls/engines/engine[0]/cowl-flaps-norm",1,4);
      setprop("/controls/engines/engine[0]/radlever",2);
}
close_coolflaps = func {
      setprop("/controls/engines/engine[0]/coolflap-auto",0);
      interpolate("controls/engines/engine[0]/cowl-flaps-norm",0,4);
      setprop("/controls/engines/engine[0]/radlever",0);
}
auto_coolflaps = func {
      setprop("/controls/engines/engine[0]/radlever",1);
      setprop("/controls/engines/engine[0]/coolflap-auto",1);
}

magicstart = func {
    setprop("/consumables/fuel/tank[0]/selected",1);
    setprop("/controls/engines/engine[0]/magnetos",3);
    setprop("/controls/engines/engine[0]/coolflap-auto",1);
    setprop("/controls/engines/engine[0]/radlever",1);
    setprop("/controls/engines/engine[0]/propeller-pitch",0.5);
    setprop("/engines/engine[0]/oil-visc",1);
    setprop("/engines/engine[0]/rpm",800);
    setprop("/engines/engine[0]/engine-running",1);
    setprop("/engines/engine[0]/out-of-fuel",0);
    setprop("/engines/engine[0]/coolant-temp-degc",40);
}
var flash_trigger = props.globals.getNode("controls/armament/trigger", 0);
aircraft.light.new("sim/model/F8F_VooDooBear/lighting/flash-l", [0.05, 0.052], flash_trigger);
aircraft.light.new("sim/model/F8F_VooDooBear/lighting/flash-r", [0.052, 0.05], flash_trigger);

var flash1_trigger = props.globals.getNode("controls/armament/trigger1", 0);
aircraft.light.new("sim/model/F8F_VooDooBear/lighting/flash-wr", [0.05, 0.052], flash1_trigger);
aircraft.light.new("sim/model/F8F_VooDooBear/lighting/flash-wl", [0.052, 0.05], flash1_trigger);

aircraft.livery.init("Aircraft/F8F_VooDooBear/Models/Liveries");
