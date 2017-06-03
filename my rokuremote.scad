
$fn = 30;

width         = 42;
height        = 15.5;
thickness         = 1.4;
length        = 70;
slider_depth  = 2;
stop_distance = 33.5;
stop_depth    = 3;
stop_length   = 4;
stop_height   = 1.5;

clip_length       = 8;
clip_gap_length   = 2.5;
clip_catch_length = 4;
clip_catch_height = 2.4;
clip_gap_height   = 1.1;
clip_mount_height = 2.4;
clip_width        = 5;

curve_ratio   = 0.6;
curve_height = height - slider_depth;
// curve_width  = curve_height / curve_ratio; 
curve_width  = width/2;

module quartercircle() {
    intersection() {
        circle();
        square(2);
    }
}
module arc90(h, w, t) {
    difference() {
        resize([w,h]) quartercircle();
        resize([w-t,h-t,0]) quartercircle();
    }
}



module halfcurve(w,ch,cw, t) {
   translate([w-cw,0,0]) arc90(ch, cw, t);
   translate([0,ch-t,0]) square([w-cw,t]);
}
module thecurve(w, ch, cw, t) {

    rotate(-90) { 
        halfcurve(w/2,ch,cw, t);
        mirror() halfcurve(w/2, ch, cw, t);
    }
}

module long_edge() {
    translate([-(length-height+slider_depth),-(width/2),0])
    square([length-curve_height, thickness]);
}

module slider() {
    rotate([0,0,180])

    linear_extrude(slider_depth) {
        thecurve(width,curve_height, curve_width, thickness);
        long_edge();
        mirror([0,1,0]) long_edge();
    }
}

module shell_body() {
    
    rotate([0,90,0]) {
        linear_extrude(length - curve_height  )
            thecurve(width, curve_height, curve_width, thickness);
        rotate(90, [1,0,0]) rotate_extrude(angle=-90) {     
            translate([0.0000001,0,0]) // some bug with -0 ? 
            thecurve(width, curve_height, curve_width, thickness);
        }
    }
}

module shell() {
    
    shell_body();
    
    difference() {
        notch_depth = 3;
        slider();
        translate([-curve_height, -1.5, slider_depth - notch_depth])
            cube(notch_depth);
    }
}

module stop() {
    //cube([stop_length, stop_depth, stop_height]);
    rotate([90,0,90])
    linear_extrude(stop_length) {
        polygon([
            [0, stop_height * 1/3 ],       
            [0,stop_height* 2/3],

            [stop_depth, stop_height],
            [stop_depth, 0]
        ]);
    }

   
}

module right_stops() {
    zpos = (slider_depth/2) - (stop_height/2);
    
    translate([
        length - curve_height - stop_length - stop_distance,
        width/2-stop_depth,
        zpos
    ]) 
    stop();
    
    // todo calc rotation along the elipse to be 6units from 
    // center
    fudge = 1.6;

    translate([-curve_height+stop_depth + fudge ,6,zpos])
    rotate([0,0,90])
    stop();

}
module left_stops() {
    mirror([0,1,0])  right_stops();
}


module stops() {
    right_stops();
    left_stops();
}

module clip() {

    clip_catchpoint   = clip_length - clip_catch_length;
    clip_mount_point  = clip_catchpoint - clip_gap_length;
    clip_height  = -curve_height+thickness + clip_mount_height;
    clip_mount_length = clip_length - clip_catch_length - clip_gap_length;
    
    translate([
        length-height + slider_depth - clip_mount_length,
        clip_width/2, 
        clip_height
    ])
    rotate([90,90,0])
    linear_extrude(clip_width)
    polygon([
        [0,0],
        [0,clip_length],
        [clip_catch_height, clip_catchpoint],
        [clip_gap_height, clip_catchpoint],
        [clip_gap_height, clip_mount_point],
        [clip_mount_height, clip_mount_point],
        [clip_mount_height, 0]
    ]);
    
}

shell();
clip();
stops();

//translate([-curve_height, -curve_height/2, 0])
//cube([curve_height, curve_height, 3]);

