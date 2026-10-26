// majin - ReXGlue Recompiled Project

#include "generated/default/majin_init.h"

#include "majin_app.h"

REXCVAR_DEFINE_BOOL(majin_record_performance, true, "Diagnostics",
                    "Enable local guest-frame CSV recording (no automatic upload)");

REXCVAR_DEFINE_BOOL(majin_window_fps, false, "Diagnostics",
                    "Show live guest FPS in the window title only");

REX_DEFINE_APP(majin, MajinApp::Create)
