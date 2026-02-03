#!/bin/bash
# fichier : love-wrapper.sh (rends-le exécutable : chmod +x love-wrapper.sh)
export SDL_VIDEO_X11_VISUALID=0
exec love . "$@"
