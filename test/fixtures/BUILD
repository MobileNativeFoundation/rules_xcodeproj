load("//xcodeproj:testing.bzl", "update_fixtures")
load(":fixtures.bzl", "FIXTURE_TARGETS")

exports_files([
    "fixtures.bzl",
    "updater.template.sh",
])

update_fixtures(
    name = "update",
    tags = ["manual"],
    targets = FIXTURE_TARGETS,
)
