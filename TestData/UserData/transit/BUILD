# Copyright 2012 Google Inc. All Rights Reserved.
# Author: kulkin@google.com (Igor Kulkin)
#
# Description:
#   This package contains all the custom icons that we use for Transit (agency
#   icons, line icons, etc.) in SVG format.

Fileset(
    name = "icons_fs",
    out = "transit_icons",
    entries = [
        FilesetEntry(
            files = glob([
                "*.svg",
                "jp-tokyo-metro/*.svg",
                "jp-tokyo-jr/*.svg",
                "uk-easter-eggs/*.svg",
                "us-ny-mta/*.svg",
            ]),
        ),
    ],
    visibility = [
        "//maps/directions/localization/transit:__pkg__",
    ],
)

sh_test(
    name = "icon_diff_test",
    srcs = ["icon_diff_test.sh"],
    data = [
        "icon_diff_whitelist.txt",
        ":icons_fs",
        "//googledata/html/external_content/maps_gstatic_com/mapfiles/transit/iw:transit_icons_fs",
        "//googledata/html/external_content/maps_gstatic_com/mapfiles/transit/iw2:mapfiles_fs",
        "//util/shell/gbash:unit",
    ],
)
