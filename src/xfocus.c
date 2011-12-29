#include <X11/X.h>
#include <X11/Xlib.h>
#include "ratpoison.h"
#include "xfocus.h"

void xfocus (XEvent *ev, int moused) {
    Window root_win, child_win;
    int root_x, root_y, m_x, m_y;
    unsigned int mask;

    XQueryPointer (dpy, DefaultRootWindow(dpy), &root_win, &child_win, &root_x, &root_y, &m_x, &m_y, &mask);

    if( moused ) {
        // we did this movement with the mouse, so focus this frame now
        fprintf(stderr, "focus on the frame located here: (%d, %d)\n", root_x, root_y);

    } else {
        // we did this movement with the keyboard, so move the mouse accordingly
        fprintf(stderr, "move the mouse to the current frame\n");
    }
}
