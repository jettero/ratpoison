#!/usr/bin/perl

# ALL Xlib logic shamelessly lifted from: Copyright (C) 2005 Shawn Betts <sabetts@vcn.bc.ca>
# sloppy.c was GPL2, so is this.  See that file for further info.
# This file is Copyright © 2011 — Paul Miller <jettero@gmail.com>

my $sloppy_location;
BEGIN {
    $sloppy_location = "$ENV{HOME}/.ratsloppy_c_";
    mkdir $sloppy_location unless -d $sloppy_location
}

use common::sense;
use Inline Config=>DIRECTORY=>$sloppy_location;
use Inline C=>DATA=>LIBS=>"-L/usr/X11R6/lib -lX11";
use IPC::System::Simple qw(systemx capturex);

my $last_mouse_target;
sub event_callback {
    my $event = shift;

    # see /usr/include/X11/X.h near #define KeyPress 2
    given( $event ) {
        when( 7 ) {
            my $target_xid = shift;
            my @rats = capturex(qw(ratpoison -c), 'windows %s %n %i');
            for(@rats) {
                if( my ($status, $window, $xid) = m/^\s*([-+*])\s+(\d+)\s+(\d+)/ ) {
                    if( $target_xid == $xid ) {
                        if( $status eq "*" ) {
                            print "already on $window/$xid\n";

                        } elsif( $status eq "+" ) {
                            print "noframe for $window/$xid\n";

                        } else {
                            $last_mouse_target = $target_xid;
                            print "select $window\n";
                            systemx(qw(ratpoison -c), "select $window");
                        }

                        last;
                    }

                } else {
                    print "bad rat [7-$target_xid]: $_";
                }
            }
        }

        when( 9 ) {
            my $target_xid = shift;

            if( $target_xid != $last_mouse_target ) {
                my @rats = capturex(qw(ratpoison -c), 'windows %s %n %i');
                for(@rats) {
                    if( my ($status, $window, $xid) = m/^\s*([-+*])\s+(\d+)\s+(\d+)/ ) {
                        if( $target_xid == $xid ) {
                            if( $status eq "-" ) {
                                banish_rat_kindof(); # uses last FocusIn window
                            }

                            last;
                        }

                    } else {
                        print "bad rat [7-$target_xid]: $_";
                    }
                }
            }
        }

        default { print "unhandled event_callback($event, @_)\n"; }
    }
}

print "listening for window entries…\n";
sloppy( \&event_callback );

__END__
__C__

#include <X11/Xos.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>

#define event_mask (EnterWindowMask | FocusChangeMask)

Display *_last_display;
Window  *_last_window;

int (*defaulthandler)();

int errorhandler(Display *display, XErrorEvent *error) {
    if(error->error_code != BadWindow)
        (*defaulthandler)(display,error);

    return 0;
}

void call_perl(SV *callback, long _e, long _o) {
    dSP; // make a new local stack

    PUSHMARK(SP); // start pushing
    XPUSHs(newSViv(_e)); // push the sv as a mortal
    XPUSHs(newSViv(_o)); // push the sv as a mortal
    PUTBACK; // end the stack

    call_sv(callback, G_DISCARD);
}

void traverse_windows(Display *d, Window w, unsigned int depth) {
    Window dw1, dw2, *wins;
    unsigned int i,nwins;

    // printf("%*s%ld\n", depth, "", w);

    if( !XQueryTree(d, w, &dw1, &dw2, &wins, &nwins) ) {
        perror("XQueryTree() failure");
        exit(1);
    }

    XSelectInput(d, w, depth ? event_mask : SubstructureNotifyMask);

    for(i=0; i<nwins; i++)
        traverse_windows(d, wins[i], depth+1);

    if(wins)
        XFree(wins);
}

void sloppy(SV *event_callback) {
    Display *display;
    int i, numscreens;

    display = XOpenDisplay(NULL);

    if(!display) {
        perror("could not open display");
        exit(1);
    }

    defaulthandler = XSetErrorHandler(errorhandler);
    numscreens = ScreenCount(display);

    for (i=0; i<numscreens; i++)
        traverse_windows(display, RootWindow(display, i), 0);

    while(1) {
        XEvent event;

        XNextEvent(display, &event);

        switch(event.type) {
            case CreateNotify:
                XSelectInput(display, event.xcreatewindow.window, event_mask);
                call_perl(event_callback, event.type, event.xcreatewindow.window);
                break;

            case EnterNotify:
                call_perl(event_callback, event.type, event.xcrossing.window);
                break;

            case FocusIn:
                _last_display = display;
                _last_window  = event.xfocus.window;
                call_perl(event_callback, event.type, event.xfocus.window);
                break;


            default:
                call_perl(event_callback, event.type, 0);
                break;
        }
    }


    XCloseDisplay(display);

    printf("sloppy\n");
}

void banish_rat_kindof() {
    XWindowAttributes attrs;
    XGetWindowAttributes(_last_display, _last_window, &attrs);
    printf("banish_rat_kindof() working: width=%d, height=%d\n", attrs.width, attrs.height);

    XWarpPointer(_last_display, None, _last_window, 0, 0, 0, 0, attrs.width-25, 25);
}
