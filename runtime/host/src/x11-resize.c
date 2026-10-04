#define _POSIX_C_SOURCE 200809L
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <errno.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static void save_geometry(const char *path, int width, int height) {
    char *temporary = malloc(strlen(path) + 40);
    if (!temporary) exit(1);
    sprintf(temporary, "%s.tmp.%ld", path, (long)getpid());
    FILE *file = fopen(temporary, "w");
    if (!file) { perror(path); free(temporary); exit(1); }
    int written = fprintf(file, "%dx%d\n", width, height);
    int closed = fclose(file);
    if (written < 0 || closed != 0 || rename(temporary, path) != 0) {
        perror(path);
        unlink(temporary);
        free(temporary);
        exit(1);
    }
    free(temporary);
}

int main(int argc, char **argv) {
    if (argc != 3 && argc != 4) {
        fprintf(stderr, "usage: %s WESTON_WINDOW_ID GEOMETRY_FILE [REFLOW_CALLBACK]\n", argv[0]);
        return 2;
    }
    char *end = NULL;
    errno = 0;
    Window window = strtoul(argv[1], &end, 0);
    if (errno || !window || end == argv[1] || *end) return 2;
    Display *display = XOpenDisplay(NULL);
    if (!display) { fputs("Cannot open X display\n", stderr); return 1; }
    XClassHint hint = {0};
    int weston = XGetClassHint(display, window, &hint) && hint.res_class &&
                 strcmp(hint.res_class, "Weston Compositor") == 0;
    if (hint.res_name) XFree(hint.res_name);
    if (hint.res_class) XFree(hint.res_class);
    if (!weston) {
        fputs("Refusing to resize a window outside Weston\n", stderr);
        XCloseDisplay(display);
        return 1;
    }

    Window root = DefaultRootWindow(display);
    XSelectInput(display, root, StructureNotifyMask);
    XSelectInput(display, window, StructureNotifyMask);
    int saved_width = 0, saved_height = 0;
    for (;;) {
        XWindowAttributes screen, current;
        if (!XGetWindowAttributes(display, root, &screen) ||
            !XGetWindowAttributes(display, window, &current)) break;
        if (screen.width >= 128 && screen.height >= 128 &&
            screen.width <= 8192 && screen.height <= 8192) {
            if (current.width != screen.width || current.height != screen.height ||
                current.x != 0 || current.y != 0) {
                XMoveResizeWindow(display, window, 0, 0, screen.width, screen.height);
                XFlush(display);
            } else if (current.width != saved_width || current.height != saved_height) {
                save_geometry(argv[2], current.width, current.height);
                printf("Weston follows Android display: %dx%d\n", current.width, current.height);
                fflush(stdout);
                saved_width = current.width;
                saved_height = current.height;
                if (argc == 4) {
                    char width[16], height[16];
                    snprintf(width, sizeof(width), "%d", current.width);
                    snprintf(height, sizeof(height), "%d", current.height);
                    pid_t child = fork();
                    if (child == 0) {
                        execl(argv[3], argv[3], width, height, (char *)NULL);
                        _exit(127);
                    }
                    if (child < 0) { perror("reflow callback"); return 1; }
                    int status;
                    while (waitpid(child, &status, 0) < 0) {
                        if (errno != EINTR) return 1;
                    }
                    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
                        fputs("Display changed but the desktop reflow callback failed\n", stderr);
                }
            }
        }

        XEvent event;
        XNextEvent(display, &event);
        if (event.type == DestroyNotify && event.xdestroywindow.window == window) break;
        // Coalesce the brief sequence of surface changes during folding/rotation.
        struct pollfd fd = { .fd = ConnectionNumber(display), .events = POLLIN };
        for (;;) {
            while (XPending(display)) {
                XNextEvent(display, &event);
                if (event.type == DestroyNotify && event.xdestroywindow.window == window)
                    goto done;
            }
            if (poll(&fd, 1, 100) <= 0) break;
            if (fd.revents & (POLLERR | POLLHUP | POLLNVAL)) goto done;
        }
    }
done:
    XCloseDisplay(display);
    return 0;
}
