#!/usr/bin/env python3
"""
Generates CinemanaNew.xcodeproj/project.pbxproj from scratch by scanning the
CinemanaNew/ source folder. Avoids committing a binary/UUID-fragile pbxproj —
run this in CI before `xcodebuild`.
"""
import hashlib
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_NAME = "CinemanaNew"
SRC_DIR = os.path.join(ROOT, APP_NAME)
PROJ_DIR = os.path.join(ROOT, f"{APP_NAME}.xcodeproj")
BUNDLE_ID = "com.xfff0.cinemananew"


def uuid_for(name: str) -> str:
    """Deterministic 24-hex-char UUID (stable across regenerations)."""
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()


def collect_swift_files():
    files = []
    for dirpath, _, filenames in os.walk(SRC_DIR):
        for fn in filenames:
            if fn.endswith(".swift") or fn == "Info.plist":
                files.append(os.path.relpath(os.path.join(dirpath, fn), ROOT))
    return sorted(files)


def main():
    if os.path.isdir(PROJ_DIR):
        shutil.rmtree(PROJ_DIR)
    os.makedirs(PROJ_DIR, exist_ok=True)

    swift_files = [f for f in collect_swift_files() if f.endswith(".swift")]
    plist_path = f"{APP_NAME}/Info.plist"

    root_uuid = uuid_for("root-object")
    main_group_uuid = uuid_for("main-group")
    products_group_uuid = uuid_for("products-group")
    target_uuid = uuid_for("app-target")
    product_ref_uuid = uuid_for("app-product")
    build_config_list_project_uuid = uuid_for("build-config-list-project")
    build_config_list_target_uuid = uuid_for("build-config-list-target")
    debug_config_project_uuid = uuid_for("debug-config-project")
    release_config_project_uuid = uuid_for("release-config-project")
    debug_config_target_uuid = uuid_for("debug-config-target")
    release_config_target_uuid = uuid_for("release-config-target")
    sources_phase_uuid = uuid_for("sources-phase")
    frameworks_phase_uuid = uuid_for("frameworks-phase")
    resources_phase_uuid = uuid_for("resources-phase")

    file_refs = {}
    build_files = {}
    for f in swift_files:
        file_refs[f] = uuid_for(f"ref:{f}")
        build_files[f] = uuid_for(f"build:{f}")

    lines = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {};")
    lines.append("\tobjectVersion = 56;")
    lines.append("\tobjects = {")

    # PBXBuildFile
    lines.append("\n/* Begin PBXBuildFile section */")
    for f in swift_files:
        lines.append(
            f"\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */ = "
            f"{{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {os.path.basename(f)} */; }};"
        )
    lines.append("/* End PBXBuildFile section */")

    # PBXFileReference
    # NOTE: `path` must be the location relative to the project root (SRCROOT),
    # since the main group has no `path` of its own (sourceTree = "<group>").
    # Using only the basename here previously caused Xcode to look for every
    # file directly in SRCROOT instead of its actual subfolder, producing
    # "Build input files cannot be found" errors.
    lines.append("\n/* Begin PBXFileReference section */")
    for f in swift_files:
        lines.append(
            f'\t\t{file_refs[f]} /* {os.path.basename(f)} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
            f'name = "{os.path.basename(f)}"; path = "{f}"; sourceTree = "<group>"; }};'
        )
    plist_ref_uuid = uuid_for(f"ref:{plist_path}")
    lines.append(
        f'\t\t{plist_ref_uuid} /* Info.plist */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
        f'name = "Info.plist"; path = "{plist_path}"; sourceTree = "<group>"; }};'
    )
    lines.append(
        f'\t\t{product_ref_uuid} /* {APP_NAME}.app */ = '
        f'{{isa = PBXFileReference; explicitFileType = wrapper.application; '
        f'includeInIndex = 0; path = {APP_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )
    lines.append("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase
    lines.append("\n/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{frameworks_phase_uuid} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = ();")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup
    lines.append("\n/* Begin PBXGroup section */")
    lines.append(f"\t\t{main_group_uuid} = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for f in swift_files:
        lines.append(f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */,")
    lines.append(f"\t\t\t\t{plist_ref_uuid} /* Info.plist */,")
    lines.append(f"\t\t\t\t{products_group_uuid} /* Products */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")
    lines.append(f"\t\t{products_group_uuid} /* Products */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{product_ref_uuid} /* {APP_NAME}.app */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Products;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")
    lines.append("/* End PBXGroup section */")

    # PBXNativeTarget
    lines.append("\n/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{target_uuid} /* {APP_NAME} */ = {{")
    lines.append("\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {build_config_list_target_uuid};")
    lines.append("\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{sources_phase_uuid} /* Sources */,")
    lines.append(f"\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,")
    lines.append(f"\t\t\t\t{resources_phase_uuid} /* Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tbuildRules = ();")
    lines.append("\t\t\tdependencies = ();")
    lines.append(f'\t\t\tname = "{APP_NAME}";')
    lines.append(f"\t\t\tproductName = {APP_NAME};")
    lines.append(f"\t\t\tproductReference = {product_ref_uuid};")
    lines.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    lines.append("\t\t};")
    lines.append("/* End PBXNativeTarget section */")

    # PBXProject
    lines.append("\n/* Begin PBXProject section */")
    lines.append(f"\t\t{root_uuid} /* Project object */ = {{")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = { LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; };")
    lines.append(f"\t\t\tbuildConfigurationList = {build_config_list_project_uuid};")
    lines.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (en, Base);")
    lines.append(f"\t\t\tmainGroup = {main_group_uuid};")
    lines.append(f"\t\t\tproductRefGroup = {products_group_uuid};")
    lines.append("\t\t\tprojectDirPath = \"\";")
    lines.append("\t\t\tprojectRoot = \"\";")
    lines.append("\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{target_uuid} /* {APP_NAME} */,")
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */")

    # PBXResourcesBuildPhase
    lines.append("\n/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{resources_phase_uuid} /* Resources */ = {{")
    lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = ();")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXResourcesBuildPhase section */")

    # PBXSourcesBuildPhase
    lines.append("\n/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{sources_phase_uuid} /* Sources */ = {{")
    lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for f in swift_files:
        lines.append(f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXSourcesBuildPhase section */")

    # XCBuildConfiguration (project)
    common_project = """\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};"""

    lines.append("\n/* Begin XCBuildConfiguration section */")
    lines.append(f"\t\t{debug_config_project_uuid} /* Debug */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append(common_project)
    lines.append("\t\t\tname = Debug;")
    lines.append("\t\t};")
    lines.append(f"\t\t{release_config_project_uuid} /* Release */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append(common_project)
    lines.append("\t\t\tname = Release;")
    lines.append("\t\t};")

    target_settings = f"""\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "{APP_NAME}/Info.plist";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};"""

    lines.append(f"\t\t{debug_config_target_uuid} /* Debug */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append(target_settings)
    lines.append("\t\t\tname = Debug;")
    lines.append("\t\t};")
    lines.append(f"\t\t{release_config_target_uuid} /* Release */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append(target_settings)
    lines.append("\t\t\tname = Release;")
    lines.append("\t\t};")
    lines.append("/* End XCBuildConfiguration section */")

    # XCConfigurationList
    lines.append("\n/* Begin XCConfigurationList section */")
    lines.append(f"\t\t{build_config_list_project_uuid} /* Build configuration list for PBXProject */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{debug_config_project_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{release_config_project_uuid} /* Release */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
    lines.append(f"\t\t{build_config_list_target_uuid} /* Build configuration list for PBXNativeTarget */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{debug_config_target_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{release_config_target_uuid} /* Release */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
    lines.append("/* End XCConfigurationList section */")

    lines.append("\t};")
    lines.append(f"\trootObject = {root_uuid} /* Project object */;")
    lines.append("}")

    with open(os.path.join(PROJ_DIR, "project.pbxproj"), "w") as fh:
        fh.write("\n".join(lines) + "\n")

    print(f"Generated {PROJ_DIR}/project.pbxproj with {len(swift_files)} Swift files.")


if __name__ == "__main__":
    main()
