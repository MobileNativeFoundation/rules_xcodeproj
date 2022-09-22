#include <spawn.h>

#include <filesystem>
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>
#include <regex>
#include <string>
#include <vector>

extern char **environ;

namespace {

// Returns the base name of the given filepath. For example, given
// /foo/bar/baz.txt, returns 'baz.txt'.
const char *Basename(const char *filepath) {
  const char *base = strrchr(filepath, '/');
  return base ? (base + 1) : filepath;
}

// Converts an array of string arguments to char *arguments.
// The first arg is reduced to its basename as per execve conventions.
// Note that the lifetime of the char* arguments in the returned array
// are controlled by the lifetime of the strings in args.
std::vector<const char *> ConvertToCArgs(const std::vector<std::string> &args) {
  std::vector<const char *> c_args;
  c_args.push_back(Basename(args[0].c_str()));
  for (int i = 1; i < args.size(); i++) {
    c_args.push_back(args[i].c_str());
  }
  c_args.push_back(nullptr);
  return c_args;
}

// Spawns a subprocess for given arguments args. The first argument is used
// for the executable path.
void RunSubProcess(const std::vector<std::string> &args) {
  std::vector<const char *> exec_argv = ConvertToCArgs(args);
  pid_t pid;
  int status = posix_spawn(&pid, args[0].c_str(), nullptr, nullptr,
                           const_cast<char **>(exec_argv.data()), environ);
  if (status == 0) {
    int wait_status;
    do {
      wait_status = waitpid(pid, &status, 0);
    } while ((wait_status == -1) && (errno == EINTR));
    if (wait_status < 0) {
      std::cerr << "Error waiting on child process '" << args[0] << "'. "
                << strerror(errno) << "\n";
      abort();
    }
    if (WEXITSTATUS(status) != 0) {
      std::cerr << "Error in child process '" << args[0] << "'. "
                << WEXITSTATUS(status) << "\n";
      abort();
    }
  } else {
    std::cerr << "Error forking process '" << args[0] << "'. "
              << strerror(status) << "\n";
    abort();
  }
}

static std::string FindFlagValue(const std::vector<std::string> &args,
                                 const std::string key) {
  std::string value;
  bool saw_key = false;

  for (const auto &arg : args) {
    if (saw_key) {
      return arg;
    }
    if (arg == key) {
      saw_key = true;
    }
  }

  return "";
}

void Touch(const std::string path) {
  std::vector<std::string> invocation_args = {"/usr/bin/touch", path};
  RunSubProcess(invocation_args);
}

static std::string ReplaceExt(const std::string path,
                              const std::string extension) {
  std::string new_path =
      std::filesystem::path(path).replace_extension(extension).string();
  return new_path;
}

// static std::string ReplaceSuffix(std::string &str, const std::string &search,
//                                  const std::string &replace) {
//   int pos = str.rfind(search);
//   if (pos != std::string::npos) {
//     str.replace(pos, search.length(), replace);
//   }
//   return str;
// }

// Touch the Xcode-required .d files
void TouchDepsFiles(const std::vector<std::string> &args) {
  std::string output_file_map_path = FindFlagValue(args, "-output-file-map");
  nlohmann::json output_file_map;
  std::ifstream stream(output_file_map_path);
  stream >> output_file_map;

  for (auto &[key, value] : output_file_map.items()) {
    if (value["dependencies"] != nullptr) {
      Touch(value["dependencies"]);
    }
  }

  // std::string d_file = ReplaceSuffix(output_file_map_path, "-OutputFileMap.json", "-master.d");
  // Touch(d_file);
}

// Returns whether a given string `text` ends with `suffix`.
static bool EndsWith(const std::string text, const std::string suffix) {
  return (text.length() >= suffix.length()) &&
         std::equal(text.cend() - suffix.length(), text.cend(),
                    suffix.cbegin());
}

void TouchSwiftmoduleArtifacts(const std::vector<std::string> &args) {
  std::string swiftmodule_path = FindFlagValue(args, "-emit-module-path");
  std::string swiftdoc_path = ReplaceExt(swiftmodule_path, "swiftdoc");
  std::string swiftsourceinfo_path =
      ReplaceExt(swiftmodule_path, "swiftsourceinfo");
  std::string swiftinterface_path =
      ReplaceExt(swiftmodule_path, "swiftinterface");

  Touch(swiftmodule_path);
  Touch(swiftdoc_path);
  Touch(swiftsourceinfo_path);
  Touch(swiftinterface_path);

  std::string generated_header_path =
      FindFlagValue(args, "-emit-objc-header-path");
  if (generated_header_path != "") {
    Touch(generated_header_path);
  }
}

}  // namespace

int main(int argc, char *argv[]) {
  auto args = std::vector<std::string>(argv + 1, argv + argc);

  for (const auto &arg : args) {
    if (arg == "-v") {
      // TODO: Make this be the correct swiftc (see `DEVELOPER_DIR` and custom
      // toolchain comment below)
      std::vector<std::string> invocation_args = {"swiftc", "-v"};
      RunSubProcess(invocation_args);
      return 0;
    }
  }

  std::regex developer_dir_pattern = std::regex("(.*?/Contents/Developer)/.*");
  std::string output_file_map_path = FindFlagValue(args, "-output-file-map");
  if (output_file_map_path != "") {
    for (const auto &arg : args) {
      if (EndsWith(arg, ".preview-thunk.swift")) {
        std::string sdk_path = FindFlagValue(args, "-sdk");
        if (!std::regex_match(sdk_path, developer_dir_pattern)) {
          std::cerr << "Failed to parse DEVELOPER_DIR from -sdk\n";
          abort();
        }

        std::match_results<std::string::const_iterator> results;
        std::regex_match(sdk_path, results, developer_dir_pattern);
        std::string swiftc =
            results.str(0) +
            "/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc";

        std::vector<std::string> invocation_args = args;
        invocation_args[0] = swiftc;
        RunSubProcess(invocation_args);
        return 0;
      }
    }
  }

  TouchDepsFiles(args);
  TouchSwiftmoduleArtifacts(args);

  return 0;
}
