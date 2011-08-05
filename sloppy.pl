#!/usr/bin/perl

use common::sense;
use Inline Config=>DIRECTORY=>"$ENV{HOME}/.ratsloppy_c_";
use Inline C=>DATA=>LIBS =>"-L/usr/X11R6/lib -lX11";

# NOTE: callbacks to perl
# http://www.perlmonks.org/?node_id=507831

sub enter_notify_callback {
    print "enter_notify(): @_\n";
}

sloppy( \&enter_notify_callback );

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

int sloppy(SV *enter_notify_callback) {
    Display *display;
    int i, numscreens;

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

            if (event.type == CreateNotify)
                XSelectInput(display, event.xcreatewindow.window, EnterWindowMask);

        } while(event.type != EnterNotify);

        printf("window id: %ld\n", event.xcrossing.window);
        call_sv( enter_notify_callback, G_VOID );
    }


    XCloseDisplay (display);

    printf("sloppy\n");

    return 0;
}
