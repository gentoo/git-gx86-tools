#!/bin/bash
# gentoo-infra: github.com/gentoo/git-gx86-tools.git:tests/update-02-gpg.sh
# Tests for update-02-gpg hook
# Copyright 2019 Michał Górny
# Distributed under the terms of the GNU General Public License v2 or later

. "${BASH_SOURCE%/*}"/lib.sh
HOOK_PATH=${BASH_SOURCE%/*}/../update-02-gpg
[[ ${HOOK_PATH} == /* ]] || HOOK_PATH=${PWD}/${HOOK_PATH}

einfo "SIGNED_BRANCHES test"
eindent

FAIL_MSG="[*][*][*] No signature on *, refusing"

einfo "(unset)"
eindent

tbegin "master rejected"
git config --add gentoo.verify-signatures no
git commit --allow-empty -m "A commit" -q
test_failure "${FAIL_MSG}"

tbegin "branch foo permitted"
git config --add gentoo.verify-signatures no
git commit --allow-empty -m "A master commit" -q
git checkout -b foo -q
git commit --allow-empty -m "A branch commit" -q
test_branch_success foo

tbegin "tag v1 permitted"
git config --add gentoo.verify-signatures no
git commit --allow-empty -m "A master commit" -q
git checkout --detach -q
git commit --allow-empty -m "A tag commit" -q
git tag v1
test_tag_success v1

eoutdent

einfo "all-refs"
eindent

tbegin "master rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches all-refs
git commit --allow-empty -m "A commit" -q
test_failure "${FAIL_MSG}"

tbegin "branch foo rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches all-refs
git commit --allow-empty -m "A master commit" -q
git checkout -b foo -q
git commit --allow-empty -m "A branch commit" -q
test_branch_failure foo "${FAIL_MSG}"

tbegin "tag v1 rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches all-refs
git commit --allow-empty -m "A master commit" -q
git checkout --detach -q
git commit --allow-empty -m "A tag commit" -q
git tag v1
test_tag_failure v1 "${FAIL_MSG}"

eoutdent

einfo "all"
eindent

tbegin "master rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches all
git commit --allow-empty -m "A commit" -q
test_failure "${FAIL_MSG}"

tbegin "branch foo rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches all
git commit --allow-empty -m "A master commit" -q
git checkout -b foo -q
git commit --allow-empty -m "A branch commit" -q
test_branch_failure foo "${FAIL_MSG}"

tbegin "tag v1 allowed"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches all
git commit --allow-empty -m "A master commit" -q
git checkout --detach -q
git commit --allow-empty -m "A tag commit" -q
git tag v1
test_tag_success v1

eoutdent

einfo "foo"
eindent

tbegin "master allowed"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A commit" -q
test_success

tbegin "branch foo rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A master commit" -q
git checkout -b foo -q
git commit --allow-empty -m "A branch commit" -q
test_branch_failure foo "${FAIL_MSG}"

tbegin "branch bar allowed"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A master commit" -q
git checkout -b bar -q
git commit --allow-empty -m "A branch commit" -q
test_branch_success bar

tbegin "tag v1 allowed"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A master commit" -q
git checkout --detach -q
git commit --allow-empty -m "A tag commit" -q
git tag v1
test_tag_success v1

eoutdent

einfo "foo bar"
eindent

tbegin "master allowed"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A commit" -q
test_success

tbegin "branch foo rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A master commit" -q
git checkout -b foo -q
git commit --allow-empty -m "A branch commit" -q
test_branch_failure foo "${FAIL_MSG}"

tbegin "branch bar rejected"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A master commit" -q
git checkout -b bar -q
git commit --allow-empty -m "A branch commit" -q
test_branch_success bar "${FAIL_MSG}"

tbegin "tag v1 allowed"
git config --add gentoo.verify-signatures no
git config --add gentoo.signed-branches foo
git commit --allow-empty -m "A master commit" -q
git checkout --detach -q
git commit --allow-empty -m "A tag commit" -q
git tag v1
test_tag_success v1

eoutdent

eoutdent

exit "${TEST_RET}"
