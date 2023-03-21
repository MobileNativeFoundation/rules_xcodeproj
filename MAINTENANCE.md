# Maintainers

The @MobileNativeFoundation/rules_xcodeproj-maintainer team and sub-teams lists
the current maintainers.

## Responsibilities

Maintainers are responsible for the health of the project. They keep the project
healthy by:

- Acting as stewards for the community of users
- Responding to discussions, issues, and pull requests in a timely manner
- Ensuring changes don’t break existing projects as much as possible (e.g.
  maintaining Bazel, rules, and Xcode version backwards compatibility)
- Participating in idea and design discussions
- Adding support for new Bazel, rules (e.g. rules_apple, rules_swift,
  rules_ios), and Xcode versions
- Keeping CI green

## Access control

Maintainers have varying levels of access control in the repository, depending
on their level of involvement and the types of contributions they have made. The
access control corresponds with the
@MobileNativeFoundation/rules_xcodeproj-maintainer sub-team they are a member
of:

- @MobileNativeFoundation/rules_xcodeproj-maintainers-commit
  - Can create branches
  - Can approve pull requests
    - Unblocks Workflows to run for outside contributions
    - Unblocks pull requests when more than one approval is required
  - Can close issues and pulls requests
  - Workflows (CI) runs without an approval needed
- @MobileNativeFoundation/rules_xcodeproj-maintainers-merge
  - Everything in @MobileNativeFoundation/rules_xcodeproj-maintainers-commit
  - Can merge pull requests when requirements are met
- @MobileNativeFoundation/rules_xcodeproj-maintainer-release
  - Everything in @MobileNativeFoundation/rules_xcodeproj-maintainers-merge
  - Can create releases

## How to become a maintainer

rules_xcodeproj is community owned and maintained. Any community member can
become a maintainer. Ideally we have a large set of maintainers who can work on
improving different parts of the project for different use cases, or are
representatives of complicated or large projects and can ensure that changes
continue to work for them.

In order to become a maintainer you must meet one or more of these criteria:

- Participated in numerous community discussions (e.g. bug reports, ideas, pull
  requests, and questions)
- Demonstrated proficiency working on the project, usually through contributing
  multiple non-trivial changes over time
- Maintain a complicated or large project that uses rules_xcodeproj, and have
  participated in feature or release testing on multiple occasions

If you believe you meet some of the criteria above, and would like to become a
maintainer, reach out to Brentley Jones (`@brentley` on the Bazel slack, or
github@brentleyjones.com). The existing maintainers will discuss the request
and either add you as a maintainer, or provide specific feedback on what they
would like to see before doing so.

# Design goals

The [high-level design goals document](docs/design-goals.md) details the goals
that guide our high-level decision making.
