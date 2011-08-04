#!/usr/bin/perl

use common::sense;
use Inline Config=>DIRECTORY=>"$ENV{HOME}/.ratsloppy_c_";
use Inline C=>DATA=>LIBS =>"-L/usr/X11R6/lib -lX11";

# NOTE: callbacks to perl
# http://www.perlmonks.org/?node_id=507831

sloppy();

__END__
__C__

#include <X11/Xos.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>

int sloppy() {
    Display *display;
    int i, numscreens;

    display = XOpenDisplay(NULL);

    if(!display) {
        perror("could not open display");
        exit(1);
    }

    numscreens = ScreenCount(display);

    for (i=0; i<numscreens; i++) {
        unsigned int j, nwins;
        Window dw1, dw2, *wins;

        XSelectInput(display,RootWindow(display, i), SubstructureNotifyMask);
        XQueryTree(display, RootWindow(display, i), &dw1, &dw2, &wins, &nwins);
        for (j=0; j<nwins; j++)
            XSelectInput(display, wins[j], EnterWindowMask);
    }

    XCloseDisplay (display);

    printf("sloppy\n");
}
