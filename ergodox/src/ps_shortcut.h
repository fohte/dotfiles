#ifndef PS_SHORTCUT_H
#define PS_SHORTCUT_H

#include "keymap.h"

// Common Shortcuts
#define PS_UNDO LALT(LGUI(KC_Z))
#define PS_REDO LSFT(LGUI(KC_Z))
#define PS_SAVE LGUI(KC_S)
#define PS_SAVE_AS LSFT(LGUI(KC_S))
#define PS_CUT LGUI(KC_X)
#define PS_COPY LGUI(KC_C)
#define PS_PASTE LGUI(KC_V)
#define PS_DESELECT LGUI(KC_D)
#define PS_ZOOM_IN LGUI(KC_PLUS)
#define PS_ZOOM_OUT LGUI(KC_MINUS)
#define PS_ZOOM_FIT LGUI(KC_0)
#define PS_NEW_LAYER LGUI(LSFT(LALT(KC_N)))

// Temporarily Activate Tools
#define PS_HAND KC_SPACE
#define PS_MOVE KC_LGUI
#define PS_SPUIT KC_LALT

// Show/Hide Panels
#define PS_BRUSH_PANEL KC_F5
#define PS_COLOR_PANEL KC_F6
#define PS_LAYER_PANEL KC_F7

// Switch Tools
#define PS_RECT_TOOL KC_M
#define PS_LASSO_TOOL KC_L
#define PS_BRUSH_TOOL KC_B
#define PS_ERASER_TOOL KC_E
#define PS_BUCKET_TOOL KC_G

#endif
