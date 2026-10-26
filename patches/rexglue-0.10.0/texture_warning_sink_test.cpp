#define SPDLOG_HEADER_ONLY
#define FMT_HEADER_ONLY
#include "texture_warning_sink.h"
#include <spdlog/logger.h>
#include <iostream>
#include <thread>
#include <stdexcept>
class Capture final : public spdlog::sinks::base_sink<std::mutex> {
 public: std::vector<std::string> lines;
 protected:
  void sink_it_(const spdlog::details::log_msg& msg) override { lines.emplace_back(msg.payload.data(),msg.payload.size()); }
  void flush_() override {}
};
void Check(bool ok) { if(!ok) throw std::runtime_error("logging regression"); }
int main() {
 auto capture=std::make_shared<Capture>();
 majin::TextureWarningSink sink({capture});
 const std::string warning="Texture fetch constant (1234) has \"invalid\" type!";
 auto emit=[&]{sink.log(spdlog::details::log_msg("gpu",spdlog::level::warn,warning));};
 for(int i=0;i<8;++i) emit();
 Check(capture->lines.size()==8);
 std::vector<std::thread> workers;
 for(int t=0;t<4;++t) workers.emplace_back([&]{for(int i=0;i<100000;++i) emit();});
 for(auto& worker:workers) worker.join();
 sink.log(spdlog::details::log_msg("gpu",spdlog::level::err,warning));
 Check(capture->lines.back()==warning);
 sink.log(spdlog::details::log_msg("gpu",spdlog::level::warn,"Texture fetch constant (1234) is completely invalid!"));
 Check(capture->lines.back().find("completely invalid")!=std::string::npos);
 sink.log(spdlog::details::log_msg("gpu",spdlog::level::warn,"Other GPU warning"));
 Check(capture->lines.back()=="Other GPU warning");
 sink.flush();
 Check(capture->lines.back().find("occurrences=400008;")!=std::string::npos);
 Check(capture->lines.size()<220);
 auto size=capture->lines.size();sink.flush();Check(capture->lines.size()==size);
 // Exercise the real logger auto-flush path, not only direct sink calls.
 auto liveCapture=std::make_shared<Capture>();
 auto liveSink=std::make_shared<majin::TextureWarningSink>(std::vector<spdlog::sink_ptr>{liveCapture});
 spdlog::logger logger("gpu",liveSink);
 logger.flush_on(majin::TextureFlushLevel(spdlog::level::warn));
 for(int i=0;i<100000;++i) logger.warn("{}",warning);
 Check(liveCapture->lines.size()<65);
 logger.flush();
 Check(liveCapture->lines.back().find("occurrences=100000;")!=std::string::npos);
 logger.error("Preserved immediate error");
 Check(liveCapture->lines.back()=="Preserved immediate error");
 Check(majin::TextureFlushLevel(spdlog::level::critical)==spdlog::level::critical);
 Check(majin::TextureFlushLevel(spdlog::level::off)==spdlog::level::off);
 std::cout<<"PASS: 400008 warnings bounded to "<<size<<" records; first samples, periodic samples, final counts, other warnings/errors and concurrent writes preserved.\n";
}