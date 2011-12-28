#ifndef __XFOCUS
#define __XFOCUS

void xfocus (int type, XEvent *ev);

#define TYPE2STRING(X) (X==FocusIn ? "focus" : X==FocusOut ? "!focus" : X==MotionNotify ? "motion" : X==EnterNotify ? "enter" : "unknown")
#define MTYPE2STRING(X) (X==NotifyNormal ? "normal" : X==NotifyGrab ? "grab" : X==NotifyUngrab ? "!grab" : X==NotifyWhileGrabbed ? "GRABBED" : "unknown")

#endif
