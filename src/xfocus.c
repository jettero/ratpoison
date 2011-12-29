#include <X11/X.h>
#include <X11/Xlib.h>
#include "ratpoison.h"
#include "xfocus.h"
#include "globals.h"
#include "window.h"

void xfocus (int type, XEvent *ev) {
    Window root_win, child_win;
    int root_x, root_y, m_x, m_y;
    unsigned int mask;
    rp_window *win;

    XQueryPointer (dpy, DefaultRootWindow(dpy), &root_win, &child_win, &root_x, &root_y, &m_x, &m_y, &mask);
    fprintf(stderr, "event type(%d): %s; curmpos: (%d, %d)\n", type, TYPE2STRING(type), root_x, root_y);

    // if( win = find_window(WINDOW) ) {
    //     fprintf(stderr, "move the mouse to the current window(%ld): (%d,%d)\n", win, win->mouse_x, win->mouse_y);
    //     XWarpPointer (dpy, None, win->w, 0, 0, 0, 0, win->mouse_x, win->mouse_y);
    // }
}
