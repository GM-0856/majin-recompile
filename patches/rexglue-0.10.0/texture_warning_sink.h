#pragma once
// Logging-only filter: texture validation and GPU behavior are unchanged.
#include <cstdint>
#include <mutex>
#include <string>
#include <string_view>
#include <vector>
#include <spdlog/sinks/base_sink.h>

namespace majin {
// Warning auto-flush would turn every suppressed warning into a summary.
// Keep error/critical flushing immediate; periodic and explicit flushes retain counts.
inline spdlog::level::level_enum TextureFlushLevel(spdlog::level::level_enum level) {
  return level < spdlog::level::err ? spdlog::level::err : level;
}
class TextureWarningSink final : public spdlog::sinks::base_sink<std::mutex> {
 public:
  explicit TextureWarningSink(std::vector<spdlog::sink_ptr> targets)
      : targets_(std::move(targets)) {}
 protected:
  void sink_it_(const spdlog::details::log_msg& msg) override {
    const std::string_view text(msg.payload.data(), msg.payload.size());
    const bool matches = msg.level == spdlog::level::warn &&
        text.starts_with("Texture fetch constant (") &&
        text.find("has \"invalid\" type!") != std::string_view::npos;
    if (!matches) { Forward(msg); return; }
    ++total_;
    if (total_ <= 8) { Forward(msg); return; }
    if (total_ % 4096 == 0) {
      Summary(msg);
      // Keep a representative descriptor as the problematic scene changes.
      Forward(msg);
    } else {
      ++suppressed_;
    }
  }
  void flush_() override {
    if (suppressed_ != reported_) {
      spdlog::details::log_msg msg("gpu", spdlog::level::warn, "");
      Summary(msg);
    }
    for (auto& target : targets_) target->flush();
  }
 private:
  void Forward(const spdlog::details::log_msg& msg) {
    for (auto& target : targets_) if (target->should_log(msg.level)) target->log(msg);
  }
  void Summary(const spdlog::details::log_msg& original) {
    const std::string text = "[Majin texture-warning summary] occurrences=" +
        std::to_string(total_) + "; suppressed=" + std::to_string(suppressed_) +
        "; texture validation unchanged.";
    auto msg = original;
    msg.payload = spdlog::string_view_t(text.data(), text.size());
    Forward(msg);
    reported_ = suppressed_;
  }
  std::vector<spdlog::sink_ptr> targets_;
  uint64_t total_ = 0, suppressed_ = 0, reported_ = 0;
};
}  // namespace majin