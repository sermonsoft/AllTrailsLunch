#!/usr/bin/env python3
"""
Script to add test files to Xcode project.
This modifies the project.pbxproj file to include the test files.
"""

import os
import uuid
import re

def generate_uuid():
    """Generate a UUID in Xcode format (24 hex characters)"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project():
    project_path = "AllTrailsLunchApp.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_path):
        print(f"❌ Error: {project_path} not found")
        return False
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for the new files
    favorites_file_ref_uuid = generate_uuid()
    restaurant_file_ref_uuid = generate_uuid()
    favorites_build_file_uuid = generate_uuid()
    restaurant_build_file_uuid = generate_uuid()
    
    # Find the AllTrailsLunchAppTests group
    # Look for the existing test file to find the group
    test_group_match = re.search(r'(/\* AllTrailsLunchAppTests \*/.*?children = \()(.*?)(\);)', content, re.DOTALL)
    
    if not test_group_match:
        print("❌ Error: Could not find AllTrailsLunchAppTests group")
        return False
    
    # Add file references to the group
    group_start = test_group_match.group(1)
    group_children = test_group_match.group(2)
    group_end = test_group_match.group(3)
    
    # Add our new file references
    new_children = group_children.rstrip()
    if not new_children.endswith(','):
        new_children += ','
    new_children += f"\n\t\t\t\t{favorites_file_ref_uuid} /* FavoritesManagerTests.swift */,"
    new_children += f"\n\t\t\t\t{restaurant_file_ref_uuid} /* RestaurantManagerTests.swift */,"
    
    new_group = group_start + new_children + group_end
    content = content.replace(test_group_match.group(0), new_group)
    
    # Add PBXFileReference entries
    file_ref_section_match = re.search(r'(/\* Begin PBXFileReference section \*/)(.*?)(/\* End PBXFileReference section \*/)', content, re.DOTALL)
    
    if file_ref_section_match:
        file_refs = file_ref_section_match.group(2)
        new_file_refs = file_refs + f"""
\t\t{favorites_file_ref_uuid} /* FavoritesManagerTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FavoritesManagerTests.swift; sourceTree = "<group>"; }};
\t\t{restaurant_file_ref_uuid} /* RestaurantManagerTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RestaurantManagerTests.swift; sourceTree = "<group>"; }};
"""
        new_section = file_ref_section_match.group(1) + new_file_refs + file_ref_section_match.group(3)
        content = content.replace(file_ref_section_match.group(0), new_section)
    
    # Add PBXBuildFile entries
    build_file_section_match = re.search(r'(/\* Begin PBXBuildFile section \*/)(.*?)(/\* End PBXBuildFile section \*/)', content, re.DOTALL)
    
    if build_file_section_match:
        build_files = build_file_section_match.group(2)
        new_build_files = build_files + f"""
\t\t{favorites_build_file_uuid} /* FavoritesManagerTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {favorites_file_ref_uuid} /* FavoritesManagerTests.swift */; }};
\t\t{restaurant_build_file_uuid} /* RestaurantManagerTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {restaurant_file_ref_uuid} /* RestaurantManagerTests.swift */; }};
"""
        new_section = build_file_section_match.group(1) + new_build_files + build_file_section_match.group(3)
        content = content.replace(build_file_section_match.group(0), new_section)
    
    # Add to PBXSourcesBuildPhase for AllTrailsLunchAppTests
    # Find the test target's sources build phase
    sources_phase_match = re.search(r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);.*?runOnlyForDeploymentPostprocessing)', content, re.DOTALL)
    
    if sources_phase_match:
        # Check if this is the test target's build phase by looking nearby for AllTrailsLunchAppTests
        context_start = max(0, sources_phase_match.start() - 1000)
        context = content[context_start:sources_phase_match.end() + 1000]
        
        if 'AllTrailsLunchAppTests' in context:
            sources_start = sources_phase_match.group(1)
            sources_files = sources_phase_match.group(2)
            sources_end = sources_phase_match.group(3)
            
            new_sources = sources_files.rstrip()
            if not new_sources.endswith(','):
                new_sources += ','
            new_sources += f"\n\t\t\t\t{favorites_build_file_uuid} /* FavoritesManagerTests.swift in Sources */,"
            new_sources += f"\n\t\t\t\t{restaurant_build_file_uuid} /* RestaurantManagerTests.swift in Sources */,"
            
            new_phase = sources_start + new_sources + sources_end
            content = content.replace(sources_phase_match.group(0), new_phase)
    
    # Write the modified project file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added test files to Xcode project!")
    print(f"   - FavoritesManagerTests.swift (UUID: {favorites_file_ref_uuid})")
    print(f"   - RestaurantManagerTests.swift (UUID: {restaurant_file_ref_uuid})")
    return True

if __name__ == "__main__":
    print("🔧 Adding test files to Xcode project...")
    success = add_files_to_xcode_project()
    
    if success:
        print("\n✅ Done! You can now:")
        print("   1. Open the project in Xcode")
        print("   2. Build the project (⌘B)")
        print("   3. Run tests (⌘U)")
    else:
        print("\n❌ Failed to add files. Please add them manually in Xcode.")
        print("   See ADD_TEST_FILES_TO_XCODE.md for instructions.")

