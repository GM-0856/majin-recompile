// majin - ReXGlue Recompiled Project
//
// Customize your app by overriding virtual hooks from rex::ReXApp.

#pragma once

#include <rex/rex_app.h>
#include <rex/ui/keybinds.h>
#include <rex/cvar.h>
#include <rex/perf/counter.h>
#include <rex/logging.h>
#include <rex/ui/window.h>
#include <stdexcept>
#include <string>
#include "window_layout.h"
#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

class MajinApp : public rex::ReXApp {
 public:
  using rex::ReXApp::ReXApp;
  ~MajinApp() override {
#if defined(_WIN32)
    StopTitleTimer();
#endif
  }

  static std::unique_ptr<rex::ui::WindowedApp> Create(
      rex::ui::WindowedAppContext& ctx) {
#if defined(_WIN32)
    // Process-local policy: omit the working directory and PATH from DLL lookup.
    if (!SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_APPLICATION_DIR |
                                  LOAD_LIBRARY_SEARCH_SYSTEM32)) {
      throw std::runtime_error("Unable to establish a safe DLL search policy.");
    }
#endif
    return std::unique_ptr<MajinApp>(new MajinApp(ctx, "majin",
        PPCImageConfig));
  }

 private:
  bool exit_prompt_open_ = false;

#if defined(_WIN32)
  // MessageBoxEx may localize standard buttons using the Windows UI language.
  // This thread-local hook labels our modal dialog before it is activated.
  static LRESULT CALLBACK LabelExitButtons(int code, WPARAM wparam, LPARAM lparam) {
    if (code == HCBT_ACTIVATE) {
      const HWND dialog = reinterpret_cast<HWND>(wparam);
      SetDlgItemTextW(dialog, IDYES, L"Yes");
      SetDlgItemTextW(dialog, IDNO, L"No");
    }
    return CallNextHookEx(nullptr, code, wparam, lparam);
  }
#endif

  void OnKeyDown(rex::ui::KeyEvent& event) override {
#if defined(_WIN32)
    if (event.virtual_key() == rex::ui::VirtualKey::kEscape) {
      event.set_handled(true);
      if (event.prev_state() || exit_prompt_open_) return;
      exit_prompt_open_ = true;
      const HHOOK labels = SetWindowsHookExW(WH_CBT, LabelExitButtons, nullptr,
                                             GetCurrentThreadId());
      const int answer = MessageBoxExW(GetActiveWindow(),
          L"Are you sure you want to quit?\n\nProgress since your last save will be lost.",
          L"Majin - Quit Game", MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2,
          MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US));
      if (labels) UnhookWindowsHookEx(labels);
      exit_prompt_open_ = false;
      if (answer == IDYES) { StopTitleTimer(); window()->RequestClose(); }
      return;
    }
#endif
    rex::ui::ProcessKeyEvent(event);
  }

  void OnPostInitLogging() override {
    // The SDK already timestamps guest GPU swap packets and supports buffered CSV.
    // Connect its writer before the GPU thread starts; no telemetry or UI overlay.
    if (!rex::cvar::Query<bool>("majin_record_performance")) {
      rex::cvar::SetFlagByName("perf_log_csv", "");
      return;
    }
    const auto path = rex::cvar::GetFlagByName("perf_log_csv");
    if (!path.empty()) {
      rex::perf::SetCsvLogPath(path);
      REXLOG_INFO("[Majin performance] Local per-frame CSV enabled; source=guest_gpu_swap_interval; not GPU execution or monitor display timing.");
    }
  }

#if defined(_WIN32)
  HWND title_window_ = nullptr;
  UINT_PTR title_timer_ = 0;
  static constexpr wchar_t kTitleOwner[] = L"MajinFK.CaptionOwner";

  void StopTitleTimer() {
    if (title_window_ && IsWindow(title_window_) && GetPropW(title_window_, kTitleOwner) == this) {
      if (title_timer_) KillTimer(title_window_, title_timer_);
      if (GetPropW(title_window_, kTitleOwner) == this)
        RemovePropW(title_window_, kTitleOwner);
    }
    title_timer_ = 0;
    title_window_ = nullptr;
  }

  static void CALLBACK TitleTimer(HWND hwnd, UINT, UINT_PTR timer, DWORD) {
    auto* self = static_cast<MajinApp*>(GetPropW(hwnd, kTitleOwner));
    if (self && self->title_timer_ == timer) self->RefreshTitle();
  }

  void RefreshTitle() {
    if (!window()) return;
    if (window()->IsFullscreen()) {
      window()->SetTitle("Majin Recompile");
      return;
    }
    const int64_t fps = rex::perf::GetSnapshotCounter(rex::perf::CounterId::kFps);
    const int64_t sample = rex::perf::GetSnapshotCounter(rex::perf::CounterId::kFrameTimeUs);
    const auto text = sample > 0 ? std::to_string(IsIconic(title_window_) ? 0 : fps) : "...";
    window()->SetTitle("Majin Recompile | " + text + " FPS");
  }

  void FitDecoratedWindow(HWND hwnd) {
    const LONG_PTR before = GetWindowLongPtrW(hwnd, GWL_STYLE);
    const LONG_PTR decorated = (before & ~LONG_PTR(WS_POPUP)) | WS_OVERLAPPEDWINDOW;
    if (before != decorated) {
      SetWindowLongPtrW(hwnd, GWL_STYLE, decorated);
      SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
          SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    }
    MONITORINFO monitor{sizeof(monitor)};
    RECT outer{}, client{};
    if (!GetMonitorInfoW(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor) ||
        !GetWindowRect(hwnd, &outer) || !GetClientRect(hwnd, &client)) return;
    const int frame_w = (outer.right - outer.left) - (client.right - client.left);
    const int frame_h = (outer.bottom - outer.top) - (client.bottom - client.top);
    const auto fit = majin::FitWindowClient(client.right, client.bottom,
        monitor.rcWork.right - monitor.rcWork.left,
        monitor.rcWork.bottom - monitor.rcWork.top, frame_w, frame_h);
    const int width = fit.width + frame_w, height = fit.height + frame_h;
    const int x = monitor.rcWork.left + ((monitor.rcWork.right - monitor.rcWork.left) - width) / 2;
    const int y = monitor.rcWork.top + ((monitor.rcWork.bottom - monitor.rcWork.top) - height) / 2;
    SetWindowPos(hwnd, nullptr, x, y, width, height, SWP_NOZORDER | SWP_NOACTIVATE);
    REXLOG_INFO("[Majin window] mode=windowed client={}x{} decorated=true; native minimize/maximize/close enabled", fit.width, fit.height);
  }
#endif

  bool SetupPresentation() override {
    if (!rex::ReXApp::SetupPresentation()) return false;
    window()->SetTitle("Majin Recompile");
    REXLOG_INFO("[Majin window] requested fullscreen={} title_fps={}",
        rex::cvar::GetFlagByName("fullscreen"), rex::cvar::GetFlagByName("majin_window_fps"));
#if defined(_WIN32)
    title_window_ = static_cast<HWND>(window()->GetNativeWindowHandle());
    if (title_window_) {
      if (!window()->IsFullscreen()) FitDecoratedWindow(title_window_);
      if (SetPropW(title_window_, kTitleOwner, this)) {
        // With an HWND, use our explicit ID for callback matching and KillTimer.
        // A zero request ID does not provide a reliable matching return value.
        constexpr UINT_PTR kCaptionTimerId = 0x4D464B;
        if (SetTimer(title_window_, kCaptionTimerId, 500, TitleTimer))
          title_timer_ = kCaptionTimerId;
        if (!title_timer_) RemovePropW(title_window_, kTitleOwner);
      }
      RefreshTitle();
    }
#endif
    return true;
  }

  bool OnWindowCloseRequested() override {
#if defined(_WIN32)
    StopTitleTimer();
#endif
    return true;
  }

  // Override virtual hooks for customization:
  // void OnPostInitLogging() override {}
  // void OnPreSetup(rex::RuntimeConfig& config) override {}
  // void OnLoadXexImage(std::string& xex_image) override {}
  // void OnPostLoadXexImage() override {}
  // void OnPostSetup() override {}
  // void OnCreateDialogs(rex::ui::ImGuiDrawer* drawer) override {}
  // std::unique_ptr<rex::ui::ImGuiDialog> CreateAchievementsOverlay() override;
  // std::unique_ptr<rex::ui::AchievementNotificationDialog>
  // CreateAchievementNotificationDialog() override;
  // void OnShutdown() override {}
  // void OnConfigurePaths(rex::PathConfig& paths) override {}
};
