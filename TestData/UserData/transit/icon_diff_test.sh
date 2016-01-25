#!/bin/bash

source gbash.sh || exit
source module gbash_unit.sh

readonly TRANSIT_FS="googledata/html/external_content/maps_gstatic_com/mapfiles/transit/iw2/mapfiles"
readonly TRANSIT_FS_RUNFILES="${RUNFILES}/google3/${TRANSIT_FS}"
readonly LEGACY_TRANSIT_FS="googledata/html/external_content/maps_gstatic_com/mapfiles/transit/iw/transit_icons"
readonly LEGACY_TRANSIT_FS_RUNFILES="${RUNFILES}/google3/${LEGACY_TRANSIT_FS}"
readonly SVG_FS_RUNFILES="${TRANSIT_FS_RUNFILES}/svg"
readonly SVG_LIGHT_FS_RUNFILES="${TRANSIT_FS_RUNFILES}/svg_light"
readonly L10N_FS="googledata/maps/transit/icons/transit_icons"
readonly L10N_FS_RUNFILES="${RUNFILES}/google3/${L10N_FS}"

DEFINE_file whitelist_file "${RUNFILES}/google3/googledata/maps/transit/icons/icon_diff_whitelist.txt"

# Checks that the transit icons in the localization library helper are identical
# with the SVG_FS_RUNFILES counterparts (as the source of truth).
function test::icon_diff::same_svg_directories() {
  local result=$(diff -qr "${SVG_FS_RUNFILES}" "${L10N_FS_RUNFILES}" | \
      egrep -v --line-regexp -f "${FLAGS_whitelist_file}")

  EXPECT_STR_EMPTY "${result}" "Unexpected diffs."
}

# Base workhorse for the same_files tests.
# Checks for the existence of transit icons assuming the SVG_FS_RUNFILES as
# the source of truth.
function icon_diff::diff_dirs() {
  local path="$1"
  local label="$2"
  local result_file="${TEST_TMPDIR}/result_file.txt"

  diff --old-line-format="${label}: Missing copy: %l
" \
      --new-line-format="${label}: Missing SVG: %l
" \
      --unchanged-group-format="" \
      <(ls -1 "${SVG_FS_RUNFILES}" | cut -d. -f 1 | sort) \
      <(ls -1 "${path}" | cut -d. -f 1 | sort) > ${result_file}

  egrep -v --line-regexp -f "${FLAGS_whitelist_file}" "${result_file}"
}

function test::icon_diff::same_files_iw_7() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${LEGACY_TRANSIT_FS_RUNFILES} iw/7)"
}

function test::icon_diff::same_files_iw2_2() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/2 iw2/2)"
}

function test::icon_diff::same_files_iw2_5() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/5 iw2/5)"
}

function test::icon_diff::same_files_iw2_6() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/6 iw2/6)"
}

function test::icon_diff::same_files_iw2_7() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/7 iw2/7)"
}

function test::icon_diff::same_files_iw2_8() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/8 iw2/8)"
}

function test::icon_diff::same_files_iw2_a() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/a iw2/a)"
}

function test::icon_diff::same_files_iw2_b() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/b iw2/b)"
}

function test::icon_diff::same_files_iw2_c() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/c iw2/c)"
}

function test::icon_diff::same_files_iw2_d() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/d iw2/d)"
}

function test::icon_diff::same_files_iw2_e() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/e iw2/e)"
}

function test::icon_diff::same_files_iw2_f() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/f iw2/f)"
}

function test::icon_diff::same_files_iw2_g() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/g iw2/g)"
}

function test::icon_diff::same_files_iw2_h() {
  EXPECT_STR_EMPTY "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/h iw2/h)"
}

function test::icon_diff::same_files_iw2_svg_light() {
  EXPECT_STR_EMPTY \
      "$(icon_diff::diff_dirs ${TRANSIT_FS_RUNFILES}/svg_light iw2/svg_light)"
}

gbash::unit::main "$@"
