#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>
#include <string>
#include <vector>

namespace {
constexpr wchar_t title[] = L"Majin FK Launcher";
int fail(const wchar_t* message, bool validation, int code) {
  if (!validation) MessageBoxW(nullptr, message, title, MB_OK | MB_ICONERROR);
  return code;
}
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
  int argc = 0;
  wchar_t** argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  if (!argv) return 2;
  bool validation = argc == 2 && std::wstring(argv[1]) == L"--validate-only";
  bool validArguments = argc == 1 || validation;
  LocalFree(argv);
  if (!validArguments) return fail(L"Unsupported launcher argument.", false, 2);
  if (!SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_APPLICATION_DIR |
                                LOAD_LIBRARY_SEARCH_SYSTEM32))
    return fail(L"Unable to establish a safe DLL search policy.", validation, 8);

  std::vector<wchar_t> module(32768);
  DWORD length = GetModuleFileNameW(nullptr, module.data(), static_cast<DWORD>(module.size()));
  if (!length || length >= module.size())
    return fail(L"Unable to locate the launcher folder.", validation, 3);
  std::wstring directory(module.data(), length);
  auto separator = directory.find_last_of(L"\\/");
  if (separator == std::wstring::npos)
    return fail(L"Unable to locate the launcher folder.", validation, 3);
  directory.resize(separator);
  const std::wstring script = directory + L"\\scripts\\launcher.ps1";
  DWORD attributes = GetFileAttributesW(script.c_str());
  if (attributes == INVALID_FILE_ATTRIBUTES || (attributes & FILE_ATTRIBUTE_DIRECTORY))
    return fail(L"Launcher files are missing. Extract the complete ZIP before opening Majin FK Launcher.", validation, 4);

  std::vector<wchar_t> system(32768);
  UINT systemLength = GetSystemDirectoryW(system.data(), static_cast<UINT>(system.size()));
  if (!systemLength || systemLength >= system.size())
    return fail(L"Unable to locate Windows PowerShell.", validation, 5);
  const std::wstring powershell = std::wstring(system.data(), systemLength) + L"\\WindowsPowerShell\\v1.0\\powershell.exe";
  std::wstring command = L"\"" + powershell + L"\" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File \"" + script + L"\" -Configuration Release";
  if (validation) command += L" -ValidateOnly";
  STARTUPINFOW startup{};
  startup.cb = sizeof(startup);
  PROCESS_INFORMATION process{};
  if (!CreateProcessW(powershell.c_str(), command.data(), nullptr, nullptr, FALSE,
                      CREATE_NO_WINDOW, nullptr, directory.c_str(), &startup, &process))
    return fail(L"Unable to start the launcher. Windows PowerShell 5.1 is required.", validation, 6);
  CloseHandle(process.hThread);
  DWORD wait = WaitForSingleObject(process.hProcess, INFINITE);
  DWORD exitCode = 1;
  bool complete = wait == WAIT_OBJECT_0 && GetExitCodeProcess(process.hProcess, &exitCode);
  CloseHandle(process.hProcess);
  if (!complete) return fail(L"Unable to read the launcher result.", validation, 7);
  if (exitCode) return fail(L"The launcher could not open. Check the extracted files and the reports folder.", validation, static_cast<int>(exitCode));
  return 0;
}
