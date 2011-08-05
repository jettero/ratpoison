#!/usr/bin/perl

# ALL Xlib logic shamelessly lifted from: Copyright (C) 2005 Shawn Betts <sabetts@vcn.bc.ca>
# sloppy.c was GPL2, so is this.  See that file for further info.
# This file is Copyright © 2011 — Paul Miller <jettero@gmail.com>

use common::sense;
use Inline Config=>DIRECTORY=>"$ENV{HOME}/.ratsloppy_c_";
use Inline C=>DATA=>LIBS =>"-L/usr/X11R6/lib -lX11";

sub create_notify_callback {
    print "create_notify(): @_\n";
}

sub kepress_callback {
    print "keypress(): @_\n";
}

sub enter_notify_callback {
    print "enter_notify(): @_\n";
}

print "listening for window entries…\n";
sloppy(\&enter_notify_callback, \&create_notify_callback, \&kepress_callback);

__END__
__C__

#include <X11/Xos.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>

int (*defaulthandler)();

int errorhandler(Display *display, XErrorEvent *error) {
    if(error->error_code != BadWindow)
        (*defaulthandler)(display,error);

    return 0;
}

int sloppy(SV *enter_notify_callback, SV *create_notify_callback, SV *keypress_callback) {
    Display *display;
    int i, numscreens;
    SV *window;

    display = XOpenDisplay(NULL);

    if(!display) {
        perror("could not open display");
        return 1;
    }

    defaulthandler = XSetErrorHandler(errorhandler);
    numscreens = ScreenCount(display);

    for (i=0; i<numscreens; i++) {
        unsigned int j, nwins;
        Window dw1, dw2, *wins;

        XSelectInput(display,RootWindow(display, i), SubstructureNotifyMask);
        XQueryTree(display, RootWindow(display, i), &dw1, &dw2, &wins, &nwins);
        for (j=0; j<nwins; j++)
            XSelectInput(display, wins[j], EnterWindowMask);
    }


    while (1) {
        XEvent event;

        do {
            XNextEvent(display, &event);

            if (event.type == CreateNotify) {
                XSelectInput(display, event.xcreatewindow.window, EnterWindowMask);

                window = newSViv(event.xcreatewindow.window);

                dSP; // make a new local stack

                PUSHMARK(SP); // start pushing
                XPUSHs(window); // push the sv as a mortal
                PUTBACK; // end the stack

                call_sv(create_notify_callback, G_DISCARD);
            }

        } while(event.type != EnterNotify);

        window = newSViv(event.xcrossing.window);

        dSP; // make a new local stack

        PUSHMARK(SP); // start pushing
        XPUSHs(window); // push the sv as a mortal
        PUTBACK; // end the stack

        call_sv(enter_notify_callback, G_DISCARD);
    }


    XCloseDisplay (display);

    printf("sloppy\n");

    return 0;
}
