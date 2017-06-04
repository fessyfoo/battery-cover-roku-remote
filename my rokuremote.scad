
$fn = 50;

width         = 41.66;
height        = 16;
thickness     = (width - 38.98) / 2;
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

module end_stop(offset) {
  zpos = -slider_depth/2;

  echo("offset", offset);
  translate([-offset, rear_stop_offset,zpos])
  stop();
}

module end_stops(offset = curve_height) {
  intersection() {
      hull() end_slider();
      union () {
        end_stop(offset);
        mirror([0,1,0]) end_stop(offset);
      }
  }
}

module side_stops(offset) {
  side_stop(offset);
  mirror([0,1,0]) side_stop(offset);
}

module side_stop(offset) {
  zpos = -slider_depth/2;
  translate([
      length - offset - stop_length - stop_distance,
      width/2,
      zpos
  ])
  rotate([0,0,-90])
  stop();
}

module stops(offset = curve_height) {
  end_stops(offset);
  side_stops(offset);
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

module halfshell_curve() {
translate([shell_height - shell_radius, 0,0])
  difference() {
    quartercircle(shell_radius);
    quartercircle(shell_radius - thickness);
    translate([-shell_height,0,0])
    square(shell_radius*2,center=true);
  }
}

module shell_curve() {
  halfshell_curve();
  mirror([0,1,0]) halfshell_curve();
}

module shell(length) {
  rotate([180,-90,0])
  linear_extrude(length) shell_curve();
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

module slider(length) {
  translate([0,-width/2,-slider_depth])
  cube([length, thickness, slider_depth]);
}

module sliders(length) {
  slider(length);
  mirror([0,1,0]) slider(length);
}

module end_slider() {
  translate([-slider_depth,0,0]) // why did I add slider depth?
  rotate([0,180,0])
  linear_extrude(slider_depth) endcurve();

  translate([-slider_depth,0,0]) sliders(slider_depth);
}


module endcap() {
  union() {

    end_slider();
    shell(slider_depth);

    translate([0,slider_depth/2,0])
    rotate ([0,-90,90]) linear_extrude(slider_depth)
    resize([0,rear_end_radius + slider_depth,0])
    halfshell_curve();


  }
}

module battery_cover() {
  endcap();

  shell_length = (length - rear_end_depth);
  shell(shell_length);
  sliders(shell_length);
  stops(rear_end_radius + slider_depth, 0);
  translate([shell_length, 0, shell_height - thickness ])
    clip();
}

module battery_cover_with_cutouts() {
  difference () {
    battery_cover();
    translate([10, -width/2, slider_depth])
    cube([(length - rear_end_depth )/2 - 10, width, 3]);
  }
}

module end_test() {
  end_slider();
  end_stops(rear_end_radius + slider_depth);
  side_stops(rear_end_radius + slider_depth);
  sliders(23);
}

battery_cover();
