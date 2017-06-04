
$fn = 50;

width         = 41.66;
height        = 16;
thickness     = (width - 38.98) / 2;
echo(thickness);
length        = 70;
slider_depth  = 2;

stop_distance = 33.5;
stop_depth    = 3;
stop_length   = 4;
stop_height   = 1.5;
rear_stop_offset = 6;

rear_end_radius   = width/2 - thickness - rear_stop_offset;
rear_end_depth    = rear_end_radius + slider_depth;

clip_length       = 10;
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

module quartercircle(s = 1) {
    resize([s,s])
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

module shell1_end() {
  rotate([180,0,180])
  linear_extrude(slider_depth) {
    thecurve(width,curve_height, curve_width, thickness);
  }
}

module slider() {
  shell1_end();
  sliders(length-curve_height);
}

module shell_body() {
   
    rotate([0,-90,180]) {
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
    slider();
   
    difference() {
        notch_depth = 3;
        slider();
        translate([-curve_height, -1.5, slider_depth - notch_depth])
            cube(notch_depth);
    }
}

module stop() {
    translate([stop_depth,0,-stop_height/2])
    rotate([90,0,180])
    linear_extrude(stop_length) {
        polygon([
            [0, stop_height * 1/3 ],      
            [0,stop_height* 2/3],

            [stop_depth, stop_height],
            [stop_depth, 0]
        ]);
    }

  
}

module right_stops(offset, fudge = 1.6) {
    zpos = -slider_depth/2;
   
    translate([
        length - offset - stop_length - stop_distance,
        width/2,
        zpos
    ])
    rotate([0,0,-90])
    stop();
   
    // todo calculate position against any end curve to avoid fudge?

    echo("offset", offset);
    translate([-offset + fudge, rear_stop_offset,zpos])
    stop();

}
module left_stops(offset, fudge) {
    mirror([0,1,0])  right_stops(offset, fudge);
}


module stops(offset = curve_height, fudge = 1.6) {
    right_stops(offset, fudge);
    left_stops(offset, fudge);
}

module clip() {

    clip_catchpoint   = clip_length - clip_catch_length;
    clip_mount_point  = clip_catchpoint - clip_gap_length;
    clip_height       = -curve_height+thickness + clip_mount_height;
    clip_mount_length = clip_length - clip_catch_length - clip_gap_length;
   
    translate([-clip_mount_length,-clip_width/2,-clip_mount_height])
    rotate([0,-90,-90])
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

//shell_radius   = height / 2 + width * width / ( 8 / height);
// shell_radius = h^2 + l^2) / 8h
shell_height = height - slider_depth;
shell_radius = (shell_height / 2) + ((width * width) / (8 * shell_height));

echo(shell_radius, shell_height, width / 2);

module halfshell2curve() {
translate([shell_height - shell_radius, 0,0])
  difference() {
    quartercircle(shell_radius);
    quartercircle(shell_radius - thickness);
    translate([-shell_height,0,0])
    square(shell_radius*2,center=true);
  }
}

module shell2curve() {
  halfshell2curve();
  mirror([0,1,0]) halfshell2curve();
}

module shell2(length) {
  rotate([180,-90,0])
  linear_extrude(length) shell2curve();
}


module halfendradius() {
  rear_flat = rear_stop_offset * 2;
  radius = shell_height;

  difference() {
    quartercircle(radius);
    quartercircle(radius - thickness);
  }
}

module halfendcurve() {
  rear_flat = rear_stop_offset * 2;
  radius = width/2 - thickness - rear_flat/2;

  translate([0, rear_stop_offset + thickness])
  difference() {
    quartercircle(radius);
    quartercircle(radius - thickness);
  }
  translate([radius - thickness,0,0])
  square([thickness, rear_stop_offset + thickness]);
}

module endcurve() {
  halfendcurve();
  mirror([0,1,0]) halfendcurve();
}

module end_slider() {
}

module endthing() {
  union() {

    rotate([0,0,180])
    translate([0,0,-slider_depth])
    linear_extrude(slider_depth) endcurve();

    shell2(5);

    translate([0,2.5,0])
    resize([rear_end_radius,0,0])
    rotate ([0,-90,90]) linear_extrude(5) halfshell2curve();

  }
}


module a_slider(length) {
  translate([0,-width/2,-slider_depth])
  cube([length, thickness, slider_depth]);
}

module sliders(length) {
  a_slider(length);
  mirror([0,1,0]) a_slider(length);
}


module endthing2() {
  union() {

    translate([-slider_depth,0,0]) // why did I add slider depth?
    rotate([0,180,0])
    linear_extrude(slider_depth) endcurve();

    shell2(slider_depth);

    translate([0,slider_depth/2,0])
    rotate ([0,-90,90]) linear_extrude(slider_depth)
    resize([0,rear_end_radius + slider_depth,0])
    halfshell2curve();

    translate([-slider_depth,0,0])
    sliders(slider_depth*2);

  }
}

module oldthing() {
  shell();
  translate([length-height + slider_depth, 0, shell_height - thickness ])
    clip();
  stops();
}

module newthing() {
  endthing2();

  shell_length = (length - rear_end_depth);
  shell2(shell_length);
  sliders(shell_length);
  stops(rear_end_radius + slider_depth, 1);
  translate([shell_length, 0, shell_height - thickness ])
    clip();
}

rotate([0,0,0])
difference () {
  newthing();
  translate([10, -width/2, 0])
  cube([(length - rear_end_depth )/2 - 10, width, 3]);

}
