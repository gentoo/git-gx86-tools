#!/bin/bash
# gentoo-infra: github.com/gentoo/git-gx86-tools.git:tests/lib.sh
# Git hook test helpers
# Copyright 2018 Michał Górny
# Distributed under the terms of the GNU General Public License v2 or later

[[ -z ${RC_GOT_FUNCTIONS} ]] && . /lib/gentoo/functions.sh

die() {
	echo "died @ ${BASH_SOURCE[1]}:${BASH_LINENO[0]}" >&2
	exit 1
}

TEST_RET=0

# Starts a test.  Creates temporary git repo and enters it.
# $1 - test description (printed)
tbegin() {
	local desc=${1}
	TEST_DIR=$(mktemp -d) || die
	export GIT_DIR=${TEST_DIR}/.git

	pushd "${TEST_DIR}" >/dev/null || die
	git init -q || die
	# create an initial commit to avoid a lot of pain ;-)
	git commit -q --allow-empty -m 'empty initial commit' || die

	ebegin "${desc}"
}

# Finish a test.  Does popd and cleans up the temporary directory.
# $1 - test result (defaults to $?)
# $2 - error message (optional)
tend() {
	local ret=${1:-${?}}
	local msg=${2}

	popd >/dev/null || die
	rm -rf "${TEST_DIR}" || die

	eend "${ret}" "${msg}"
}

run_test() {
	local initial_commit
	initial_commit=$(git rev-list --all | tail -n 1) || die
	(
		set -- refs/heads/master "${initial_commit}" HEAD
		set +e
		. "${HOOK_PATH}"
	)
}

# Run the test for specified ref, presuming it's a new branch/tag.
# $1 - ref path
run_test_ref() {
	local ref=${1}

	(
		set -- "${ref}" 0000000000000000000000000000000000000000 HEAD
		set +e
		. "${HOOK_PATH}"
	)
}

# Run the hook for all commits since the initial commit.
# Expect success.
test_success() {
	run_test
	tend ${?}
	: $(( TEST_RET |= ${?} ))
}

# Run the hook presuming new branch is added.
# Expect success.
# $1 - branch name
test_branch_success() {
	local branch=${1}
	run_test_ref "refs/heads/${branch}"
	tend ${?}
	: $(( TEST_RET |= ${?} ))
}

# Run the hook presuming new tag is added.
# Expect success.
# $1 - tag name
test_tag_success() {
	local tag=${1}
	run_test_ref "refs/tags/${tag}"
	tend ${?}
	: $(( TEST_RET |= ${?} ))
}

# Run the hook for all commits since the initial commit.
# Expect failure with message matching the pattern.
# $1 - bash pattern to match
test_failure() {
	local expected=${1}
	local msg

	if msg=$(run_test); then
		tend 1 "Hook unexpectedly succeeded"
		return 1
	fi

	[[ ${msg} == ${expected} ]]
	tend ${?} "'${msg}' != '${expected}'"
	: $(( TEST_RET |= ${?} ))
}

# Run the hook presuming new branch is added.
# Expect failure with message matching the pattern.
# $1 - branch name
# $2 - bash pattern to match
test_branch_failure() {
	local branch=${1}
	local expected=${2}
	local msg

	if msg=$(run_test_ref "refs/heads/${branch}"); then
		tend 1 "Hook unexpectedly succeeded"
		return 1
	fi

	[[ ${msg} == ${expected} ]]
	tend ${?} "'${msg}' != '${expected}'"
	: $(( TEST_RET |= ${?} ))
}

# Run the hook presuming new tag is added.
# Expect failure with message matching the pattern.
# $1 - tag name
# $2 - bash pattern to match
test_tag_failure() {
	local tag=${1}
	local expected=${2}
	local msg

	if msg=$(run_test_ref "refs/tags/${tag}"); then
		tend 1 "Hook unexpectedly succeeded"
		return 1
	fi

	[[ ${msg} == ${expected} ]]
	tend ${?} "'${msg}' != '${expected}'"
	: $(( TEST_RET |= ${?} ))
}

# Run the hook presuming branch is being removed.
# Expect success (our hooks shouldn't prevent removal).
test_branch_removal() {
	(
		set -- "refs/heads/removed-branch" HEAD 0000000000000000000000000000000000000000
		set +e
		. "${HOOK_PATH}"
	)

	tend ${?}
	: $(( TEST_RET |= ${?} ))
}
