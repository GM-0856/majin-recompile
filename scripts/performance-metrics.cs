// SPDX-License-Identifier: GPL-3.0-only
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

namespace Majin.Diagnostics {
    public sealed class FrameSummary {
        public int SchemaVersion = 1;
        public string Source = "guest_gpu_swap_interval";
        public string Scope = "Intervals between guest swap packets; includes loading, pauses and stalls. Not GPU execution or monitor display timing.";
        public long ValidIntervals, ZeroIntervals, InvalidRows;
        public bool InputTruncated;
        public double MeasuredSeconds, AverageFPS, MeanFrameMs, MinimumFrameMs, MaximumFrameMs;
        public double P50FrameMs, P95FrameMs, P99FrameMs;
        public long Over33Point333Ms, Over50Ms, Over100Ms;
        public string PercentileMethod = "Nearest rank over all valid intervals, without removing outliers.";
        public string EndOfSessionLimit = "The upstream buffered writer may lose its final 59 rows on hard exit/crash.";
    }

    public static class Frames {
        // Bounded offline analysis: never runs on the game's frame thread.
        const int MaxRows = 2000000, MaxLine = 4096;
        const long MaxBytes = 128L * 1024 * 1024;
        static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

        public static string ReadBoundedLine(TextReader reader) {
            var value = new StringBuilder(256);
            int c;
            while ((c = reader.Read()) != -1) {
                if (c == '\n') break;
                if (value.Length >= MaxLine) throw new InvalidDataException("Diagnostic record exceeds the line limit.");
                if (c != '\r') value.Append((char)c);
            }
            return c == -1 && value.Length == 0 ? null : value.ToString();
        }
        static double Percentile(List<long> sorted, double fraction) {
            int index = Math.Max(0, (int)Math.Ceiling(sorted.Count * fraction) - 1);
            return sorted[index] / 1000.0;
        }
        static string Number(double value) { return value.ToString("0.######", Inv); }
        static void Window(StreamWriter writer, double elapsedUs, long count, double totalUs, long maxUs) {
            if (count == 0) return;
            writer.WriteLine(Number(elapsedUs / 1000) + "," + count.ToString(Inv) + "," + Number(totalUs / 1000) + "," +
                Number(count * 1000000.0 / totalUs) + "," + Number(totalUs / count / 1000) + "," + Number(maxUs / 1000.0));
        }
        public static FrameSummary Analyze(string csv, string series) {
            var info = new FileInfo(csv);
            if (info.Length > MaxBytes) throw new InvalidDataException("Frame CSV exceeds 128 MiB; retain the original and analyze a bounded excerpt.");
            var result = new FrameSummary();
            var times = new List<long>();
            double total = 0, windowUs = 0;
            long windowCount = 0, windowMax = 0;
            using (var input = new StreamReader(csv, Encoding.UTF8, true, 65536))
            using (var output = new StreamWriter(series, false, new UTF8Encoding(false), 65536)) {
                var header = ReadBoundedLine(input);
                if (header == null) throw new InvalidDataException("Empty frame CSV.");
                var columns = header.Split(',');
                int index = Array.IndexOf(columns, "frame_time_us");
                if (index < 0 || columns.Length > 64) throw new InvalidDataException("Unsupported frame CSV header.");
                output.WriteLine("elapsed_ms,intervals,window_ms,average_fps,mean_frame_ms,max_frame_ms");
                string line;
                int rows = 0;
                while ((line = ReadBoundedLine(input)) != null) {
                    if (++rows > MaxRows) { result.InputTruncated = true; break; }
                    var fields = line.Split(',');
                    long dt;
                    if (fields.Length != columns.Length || !Int64.TryParse(fields[index], NumberStyles.None, Inv, out dt) || dt > 86400000000L) {
                        ++result.InvalidRows; continue;
                    }
                    if (dt == 0) { ++result.ZeroIntervals; continue; }
                    times.Add(dt); total += dt; windowUs += dt; ++windowCount; windowMax = Math.Max(windowMax, dt);
                    if (dt > 100000.0 / 3) ++result.Over33Point333Ms;
                    if (dt > 50000) ++result.Over50Ms;
                    if (dt > 100000) ++result.Over100Ms;
                    if (windowUs >= 1000000) {
                        Window(output, total, windowCount, windowUs, windowMax);
                        windowCount = 0; windowUs = 0; windowMax = 0;
                    }
                }
                Window(output, total, windowCount, windowUs, windowMax);
            }
            result.ValidIntervals = times.Count;
            if (times.Count == 0) return result;
            times.Sort();
            result.MeasuredSeconds = total / 1000000;
            result.AverageFPS = times.Count * 1000000.0 / total;
            result.MeanFrameMs = total / times.Count / 1000;
            result.MinimumFrameMs = times[0] / 1000.0;
            result.MaximumFrameMs = times[times.Count - 1] / 1000.0;
            result.P50FrameMs = Percentile(times, .50);
            result.P95FrameMs = Percentile(times, .95);
            result.P99FrameMs = Percentile(times, .99);
            return result;
        }
    }
}
