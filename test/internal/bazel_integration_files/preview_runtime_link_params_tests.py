import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
from unittest import mock


_SCRIPT = Path(__file__).parents[3] / (
    "xcodeproj/internal/bazel_integration_files/preview_runtime_link_params.py"
)
_SPEC = importlib.util.spec_from_file_location("preview_runtime_link_params", _SCRIPT)
runtime = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(runtime)


class RuntimeLinkParamsTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="runtime plan's ")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.driver = self.root / "Selected Toolchain/usr/bin/clang"
        self.driver.parent.mkdir(parents=True)
        self.driver.write_text("not executed by mocked planning tests")
        self.driver.chmod(0o755)
        self.sdk = self.root / "Selected SDK.sdk"
        self.sdk.mkdir()
        self.target = "arm64-apple-ios16.0-simulator"
        self.platform = self.archive("libclang_rt.iossim.a")
        self.profile = self.archive("libclang_rt.profile_iossim.a")
        self.alignment = [
            value
            for section in ("__llvm_prf_cnts", "__llvm_prf_bits", "__llvm_prf_data")
            for value in ("-sectalign", "__DATA", section, "0x4000")
        ]

    def archive(self, name):
        path = self.root / "Runtime's \\\" directory" / name
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(b"archive identity validated separately by real controls")
        return str(path)

    def job(self, values=()):
        # Normalized actual Xcode26.5/26.6 Darwin job shape. No installed SDK,
        # runtime archive or host tool is required for this unit test.
        return [
            str(self.driver.with_name("ld")), "-demangle", "-dynamic", "-dylib",
            "-arch", "arm64", "-platform_version", "ios-simulator", "16.0.0",
            "26.5", "-syslibroot", str(self.sdk), "-o", "/dev/null",
            "/temporary-planned-object.o", "-lSystem", *values,
        ]

    def plan(self, job):
        return (
            "Apple clang version 21.0.0\n"
            " (in-process)\n"
            + " ".join(json.dumps(value) for value in [str(self.driver), "-cc1", "-emit-obj", "/dev/null"])
            + "\n " + " ".join(json.dumps(value) for value in job) + "\n"
        )

    def query(self, values=(), *, driver_policy=(), swift_profile=False, plan=None):
        with mock.patch.object(runtime.subprocess, "run") as run:
            run.return_value = subprocess.CompletedProcess([], 0, "", self.plan(self.job(values)) if plan is None else plan)
            result = runtime.runtime_link_args(
                str(self.driver), str(self.sdk), self.target,
                swift_profile=swift_profile, driver_policy=driver_policy,
            )
        return result, run.call_args

    def cli(self, *extra):
        return [
            "--driver", str(self.driver), "--sdk", str(self.sdk),
            "--target", self.target, "--swift-profile", "NO", *extra,
        ]

    def test_actual_darwin_shapes_select_only_runtime_closure(self):
        expected = [self.profile, *self.alignment, self.platform]
        for version in ("26.5", "26.6"):
            with self.subTest(xcode=version):
                # Both inspected installations carry the26.5 SDK; do not infer
                # the SDK version from the Xcode application's name.
                job = self.job(expected)
                job[0] = str(self.root / f"Xcode-{version}/usr/bin/ld")
                job += ["-framework", "Foundation", "-lobjc", "-rpath", "/usr/lib/swift"]
                result, _ = self.query(plan=self.plan(job))
                self.assertEqual(result, expected)

    def test_profile_off_does_not_enable_query_profiling(self):
        result, call = self.query([self.platform])
        self.assertEqual(result, [self.platform])
        self.assertEqual(call.args[0], [
            str(self.driver), "-###", "-dynamiclib", "-target", self.target,
            "-isysroot", str(self.sdk), "-x", "c", "/dev/null", "-o", "/dev/null",
        ])
        self.assertEqual(call.kwargs, {"capture_output": True, "text": True, "timeout": 30})

    def test_profile_requirement_precedes_explicit_ordered_driver_policy(self):
        policy = ["-fno-profile-generate", "-nodefaultlibs"]
        # Both real drivers still select the profile runtime in this case.
        expected = [self.profile, *self.alignment]
        result, call = self.query(expected, driver_policy=policy, swift_profile=True)
        self.assertEqual(result, expected)
        self.assertEqual(call.args[0][7:-5], ["-fprofile-generate", *policy])
        self.assertEqual(policy, ["-fno-profile-generate", "-nodefaultlibs"])

    def test_valid_suppressed_zero_runtime_plan(self):
        for flag in ("-nostdlib", "-nodefaultlibs"):
            with self.subTest(flag=flag):
                result, call = self.query(driver_policy=[flag])
                self.assertEqual(result, [])
                self.assertIn(flag, call.args[0])

    def test_driver_choice_not_fixed_archive_count(self):
        result, _ = self.query([])
        self.assertEqual(result, [])

    def test_policy_values_remain_single_arguments(self):
        policy = ["-fprofile-instr-generate=/path with spaces/out.profraw", "--rtlib=compiler-rt"]
        _, call = self.query(driver_policy=policy)
        self.assertEqual(call.args[0][7:-5], policy)

    def test_policy_rejects_inputs_forwarded_flags_and_unknown_options(self):
        for policy in ("-nostdlib", {}, [False], ["-all_load"], ["-Xlinker", "-fprofile-generate"],
                       ["-u", "-fprofile-generate"], ["@policy.rsp"], ["-isysroot", "/another-sdk"],
                       ["-fprofile-generate="], ["-fprofile-generate=bad\nvalue"]):
            with self.subTest(policy=policy), mock.patch.object(runtime.subprocess, "run") as run:
                with self.assertRaisesRegex(ValueError, "policy"):
                    runtime.runtime_link_args(self.driver, self.sdk, self.target, driver_policy=policy)
                run.assert_not_called()

    def test_misleading_environment_is_not_an_input_fallback(self):
        with mock.patch.dict(os.environ, {
            "TOOLCHAIN_DIR": "/Metal.xctoolchain", "SDKROOT": "wrong-sdk",
            "CURRENT_ARCH": "undefined_arch", "NATIVE_ARCH_ACTUAL": "arm64e",
            "ARCHS": "x86_64 arm64", "ENABLE_CODE_COVERAGE": "YES",
        }):
            _, call = self.query([self.platform])
        self.assertEqual(call.args[0][0], str(self.driver))
        self.assertIn(str(self.sdk), call.args[0])
        self.assertIn(self.target, call.args[0])
        self.assertNotIn("-fprofile-generate", call.args[0])

    def test_explicit_inputs_are_required_before_planning(self):
        cases = [
            ("clang", self.sdk, self.target),
            (self.root / "missing-driver", self.sdk, self.target),
            (self.driver, "named-sdk", self.target),
            (self.driver, self.root / "missing-sdk", self.target),
            (self.driver, self.sdk, "arm64 x86_64-apple-ios16.0-simulator"),
            (self.driver, self.sdk, "arm64-unknown-linux-gnu"),
            (self.driver, self.sdk, ""),
        ]
        for args in cases:
            with self.subTest(args=args), mock.patch.object(runtime.subprocess, "run") as run:
                with self.assertRaises(ValueError):
                    runtime.runtime_link_args(*args)
                run.assert_not_called()

    def test_nonexecutable_driver_and_nonboolean_requirement(self):
        self.driver.chmod(0o644)
        with self.assertRaisesRegex(ValueError, "executable"):
            runtime.runtime_link_args(self.driver, self.sdk, self.target)
        self.driver.chmod(0o755)
        with self.assertRaisesRegex(ValueError, "boolean"):
            runtime.runtime_link_args(self.driver, self.sdk, self.target, swift_profile="NO")

    def test_nonzero_driver_has_actionable_identity(self):
        with mock.patch.object(runtime.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "", "unsupported runtime policy")):
            with self.assertRaisesRegex(ValueError, "exited 1.*unsupported runtime policy") as error:
                runtime.runtime_link_args(self.driver, self.sdk, self.target)
        for value in (str(self.driver), str(self.sdk), self.target):
            self.assertIn(value, str(error.exception))

    def test_failed_or_timed_out_driver_has_no_fallback(self):
        for error in (OSError("cannot execute"), subprocess.TimeoutExpired("clang", 30)):
            with self.subTest(error=error), mock.patch.object(runtime.subprocess, "run", side_effect=error):
                with self.assertRaisesRegex(ValueError, "Cannot plan Preview compiler runtimes"):
                    runtime.runtime_link_args(self.driver, self.sdk, self.target)

    def test_missing_ambiguous_and_malformed_linker_jobs_fail(self):
        plan = self.plan(self.job([self.platform]))
        cases = ["version only\n", plan + plan, '"unterminated\n', self.plan(["/usr/bin/ld", "-arch", "arm64"])]
        for value in cases:
            with self.subTest(plan=value), self.assertRaises(ValueError):
                self.query(plan=value)

    def test_linker_plan_must_match_architecture_and_sdk(self):
        for flag, value in (("-arch", "arm64e"), ("-syslibroot", "/different-sdk")):
            job = self.job([self.platform])
            job[job.index(flag) + 1] = value
            with self.subTest(flag=flag), self.assertRaisesRegex(ValueError, "does not match"):
                self.query(plan=self.plan(job))

    def test_platform_version_group_must_be_complete(self):
        job = self.job([self.platform])
        index = job.index("-platform_version")
        for values in (["-platform_version"], ["-platform_version", "ios-simulator", "16.0"],
                       ["-platform_version", "ios-simulator", "bad-version", "26.5"],
                       job[index:index + 4] * 2):
            with self.subTest(values=values), self.assertRaisesRegex(ValueError, "platform-version"):
                self.query(plan=self.plan(job[:index] + job[index + 4:] + values))

    def test_unsupported_linker_and_relative_tool_plan_fail(self):
        for name in ("/tools/ld.lld", "ld"):
            job = self.job([self.platform])
            job[0] = name
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.query(plan=self.plan(job))

    def test_missing_and_repeated_identity_flags_fail(self):
        for option in ("-arch", "-syslibroot"):
            job = self.job([self.platform])
            index = job.index(option)
            removed = job[:index] + job[index + 2:]
            repeated = job + job[index:index + 2]
            for value in (removed, repeated, removed + [option]):
                with self.subTest(option=option, job=value), self.assertRaisesRegex(ValueError, option):
                    self.query(plan=self.plan(value))

    def test_missing_relative_and_directory_runtime_paths_fail(self):
        directory = self.root / "libclang_rt.directory.a"
        directory.mkdir()
        for path in (str(self.root / "libclang_rt.missing.a"), "relative/libclang_rt.iossim.a", str(directory)):
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, "absolute file"):
                self.query([path])

    def test_bound_runtime_does_not_silently_become_lazy(self):
        for flag in ("-force_load", "-weak_library", "-reexport_library"):
            with self.subTest(flag=flag), self.assertRaisesRegex(ValueError, "bound"):
                self.query([flag, self.platform])

    def test_incomplete_associated_alignment_fails(self):
        for group in (["-sectalign"], ["-sectalign", "__DATA", "__llvm_prf_cnts"],
                      ["-sectalign", "__DATA", "__llvm_prf_cnts", "-lSystem"],
                      ["-sectalign", "__DATA", "__llvm_prf_cnts", "not-alignment"]):
            with self.subTest(group=group), self.assertRaisesRegex(ValueError, "sectalign"):
                self.query([self.profile, *group])

    def test_unassociated_alignment_and_link_inputs_stay_caller_owned(self):
        values = ["-sectalign", "__DATA", "__caller", "0x20", "-all_load", "/external/dependency.a", self.platform]
        result, _ = self.query(values)
        self.assertEqual(result, [self.platform])
        self.assertEqual(values[4], "-all_load")

    def test_order_and_repeated_runtime_tokens_are_not_deduplicated(self):
        result, _ = self.query([self.profile, *self.alignment, self.platform, self.profile])
        self.assertEqual(result, [self.profile, *self.alignment, self.platform, self.profile])

    def test_cli_response_quotes_every_argument_and_round_trips(self):
        expected = [self.profile, *self.alignment, self.platform]
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(runtime, "runtime_link_args", return_value=expected), contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            status = runtime.main(self.cli())
        self.assertEqual(status, 0)
        self.assertEqual(err.getvalue(), "")
        self.assertEqual(shlex.split(out.getvalue()), expected)
        self.assertTrue(all(line.startswith('"') and line.endswith('"') for line in out.getvalue().splitlines()))

    def test_cli_valid_empty_plan_emits_no_arguments(self):
        out = io.StringIO()
        with mock.patch.object(runtime, "runtime_link_args", return_value=[]), contextlib.redirect_stdout(out):
            status = runtime.main(self.cli())
        self.assertEqual((status, out.getvalue()), (0, ""))

    def test_cli_failure_never_emits_partial_output(self):
        for plan in (self.plan(self.job([self.profile, str(self.root / "libclang_rt.missing.a")])), "not a plan"):
            out, err = io.StringIO(), io.StringIO()
            with mock.patch.object(runtime.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "", plan)), contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                status = runtime.main(self.cli())
            self.assertEqual((status, out.getvalue()), (1, ""))
            self.assertIn("error:", err.getvalue())

    def test_cli_invalid_policy_json_never_runs_driver(self):
        for value in ("not json", "{}", '["-all_load"]'):
            out, err = io.StringIO(), io.StringIO()
            with mock.patch.object(runtime.subprocess, "run") as run, contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                status = runtime.main(self.cli("--driver-policy-json", value))
            self.assertEqual((status, out.getvalue()), (1, ""))
            run.assert_not_called()

    def test_cli_policy_file_preserves_literal_data_and_order(self):
        policy = ["-fprofile-generate=Author's \\\"profile\\\" dir", "-nodefaultlibs"]
        path = self.root / "policy data.json"
        path.write_text(json.dumps(policy))
        with mock.patch.object(runtime, "runtime_link_args", return_value=[]) as query:
            self.assertEqual(runtime.main(self.cli("--driver-policy-file", str(path))), 0)
        self.assertEqual(query.call_args.kwargs["driver_policy"], policy)

    def test_cli_missing_or_malformed_policy_file_does_not_plan(self):
        path = self.root / "policy.json"
        for content in (None, "not json", "{}", '["-all_load"]'):
            if content is not None:
                path.write_text(content)
            out, err = io.StringIO(), io.StringIO()
            with mock.patch.object(runtime.subprocess, "run") as run, contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                status = runtime.main(self.cli("--driver-policy-file", str(path)))
            self.assertEqual((status, out.getvalue()), (1, ""))
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
