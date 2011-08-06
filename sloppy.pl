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

sub create_notify_callback {
    print "create_notify(): @_\n";
}

sub kepress_callback {
    print "keypress(): @_\n";
}

sub mousemove_callback {
    print "mousemove(): @_\n";
}

sub enter_notify_callback {
    print "enter_notify(): @_\n";
}

print "listening for window entries…\n";
sloppy(
    \&enter_notify_callback,
    \&create_notify_callback,
    \&kepress_callback,
    \&mousemove_callback,
);

__END__
__C__

#include <X11/Xos.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>

#define event_mask (PointerMotionMask | PointerMotionHintMask | KeyPressMask | KeyReleaseMask | EnterWindowMask)

int (*defaulthandler)();

int errorhandler(Display *display, XErrorEvent *error) {
    if(error->error_code != BadWindow)
        (*defaulthandler)(display,error);

    return 0;
}

void call_perl(SV *callback, long _a) {
    SV *argument = newSViv(_a);

    dSP; // make a new local stack

    PUSHMARK(SP); // start pushing
    XPUSHs(argument); // push the sv as a mortal
    PUTBACK; // end the stack

    call_sv(callback, G_DISCARD);
}

void traverse_windows(Display *d, Window w) {
    Window dw1, dw2, *wins;
    unsigned int i,nwins;

    if( !XQueryTree(d, w, &dw1, &dw2, &wins, &nwins) ) {
        perror("XQueryTree() failure");
        exit(1);
    }

    if( !nwins )
        XSelectInput(d, w, event_mask);

    else
        for(i=0; i<nwins; i++)
            traverse_windows(d, wins[i]);

    if(wins)
        XFree(wins);
}

void sloppy(SV *enter_notify_callback, SV *create_notify_callback, SV *keypress_callback, SV *mousemove_callback) {
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
        traverse_windows(display, RootWindow(display, i));

    while (1) {
        XEvent event;

        XNextEvent(display, &event);

        printf("event.type: %d\n", event.type);

        if(0)
        switch(event.type) {
            case CreateNotify:
                XSelectInput(display, event.xcreatewindow.window, event_mask);
                call_perl(create_notify_callback, event.xcreatewindow.window);
                break;

            case EnterNotify:
                call_perl(create_notify_callback, event.xcrossing.window);
                break;

            case KeyPress:
            case KeyRelease:
                call_perl(keypress_callback, 0);
                break;

            case MotionNotify:
                call_perl(mousemove_callback, 0);
                break;
        }
    }


    XCloseDisplay(display);

    printf("sloppy\n");
}
