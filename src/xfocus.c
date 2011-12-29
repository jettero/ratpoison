#include <X11/X.h>
#include <X11/Xlib.h>
#include "ratpoison.h"
#include "xfocus.h"
#include "globals.h"
#include "split.h"

static rp_frame * find_frame_by_mouse_position(int x, int y) {
    int i;
    rp_frame *cur;

    for (i=0; i<num_screens; i++) {
        rp_screen *s = &screens[i];

        fprintf(stderr, "  screen(%d) - loc(%d,%d) dim(%d,%d)\n", i, s->left, s->top, s->width, s->height);
        if( x>=s->left && x<=(s->width + s->left) && y>=s->top && y<=(s->height + s->top) ) {
            list_for_each_entry (cur, &s->frames, node) {
                if( x>=(cur->x+s->left) && x<=(cur->x+s->left+cur->width) && y>=(cur->y+s->top) && y<=(cur->y+s->top+cur->height) ) {
                    fprintf(stderr, "    frame(%ld) - loc(%d,%d) dim(%d,%d)\n", cur, cur->x, cur->y, cur->width, cur->height);
                    return cur;
                }
            }
        }
    }

    return NULL;
}

void xfocus (int type, XEvent *ev) {
    Window root_win, child_win;
    int root_x, root_y, m_x, m_y;
    unsigned int mask;
    rp_frame *f;

    XQueryPointer (dpy, DefaultRootWindow(dpy), &root_win, &child_win, &root_x, &root_y, &m_x, &m_y, &mask);
    fprintf(stderr, "event type(%d): %s; curmpos: (%d, %d)\n", type, TYPE2STRING(type), root_x, root_y);

    if( type == MotionNotify || type == EnterNotify ) {
        // This was a mouse move, so select the frame
        if( type == EnterNotify ) {
            XCrossingEvent *_ec = &ev->xcrossing;
            fprintf(stderr, "  mode: %s\n", MTYPE2STRING(_ec->mode));
            if( _ec->mode != NotifyNormal )
                return; // we're not interested in ungrab re-entries and other things, just the mouse initiated ones
        }

        if( (f = find_frame_by_mouse_position(root_x, root_y)) ) {
            fprintf(stderr, "      focus this frame\n");
            set_active_frame(f, 1); // frame, forced
        }
    }
}
