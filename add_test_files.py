#!/usr/bin/env python3

import os
import re
import uuid
import sys

def generate_uuid():
    """Generate a UUID in the format Xcode uses"""
    return uuid.uuid4().hex[:24].upper()

def add_test_files_to_project():
    project_file = "/Users/colemadden/Desktop/Pente/Pente.xcodeproj/project.pbxproj"
    test_files_dir = "/Users/colemadden/Desktop/Pente/PenteTests"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find all test files (excluding the ones we don't want)
    test_files = []
    for file in os.listdir(test_files_dir):
        if file.endswith('.swift') and file not in ['TestRunner.swift', 'PenteTests.swift']:
            test_files.append(file)
    
    print(f"Adding {len(test_files)} test files to project...")
    
    # Generate UUIDs for each file (2 per file - one for reference, one for build file)
    file_refs = {}
    build_files = {}
    
    for file in test_files:
        file_refs[file] = generate_uuid()
        build_files[file] = generate_uuid()
        print(f"  {file}: {file_refs[file]} / {build_files[file]}")
    
    # Find the PBXFileReference section and add our files
    file_ref_section = re.search(r'(\/\* Begin PBXFileReference section \*\/.*?)(\/\* End PBXFileReference section \*\/)', content, re.DOTALL)
    if file_ref_section:
        existing_refs = file_ref_section.group(1)
        new_refs = existing_refs
        
        for file in test_files:
            ref_line = f'\t\t{file_refs[file]} /* {file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file}; sourceTree = "<group>"; }};\n'
            new_refs += ref_line
        
        content = content.replace(file_ref_section.group(1), new_refs)
    
    # Find the PBXBuildFile section and add build files
    build_file_section = re.search(r'(\/\* Begin PBXBuildFile section \*\/.*?)(\/\* End PBXBuildFile section \*\/)', content, re.DOTALL)
    if build_file_section:
        existing_builds = build_file_section.group(1)
        new_builds = existing_builds
        
        for file in test_files:
            build_line = f'\t\t{build_files[file]} /* {file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[file]} /* {file} */; }};\n'
            new_builds += build_line
        
        content = content.replace(build_file_section.group(1), new_builds)
    
    # Find the PenteTests sources build phase and add our files
    sources_section = re.search(r'(503BD6522E2DA00D00280E36 \/\* Sources \*\/ = \{.*?files = \(\s*)(.*?)(\s*\);)', content, re.DOTALL)
    if sources_section:
        existing_files = sources_section.group(2)
        new_files_list = existing_files
        
        for file in test_files:
            file_line = f'\t\t\t\t{build_files[file]} /* {file} in Sources */,\n'
            new_files_list += file_line
        
        content = content.replace(sources_section.group(0), 
                                sources_section.group(1) + new_files_list + sources_section.group(3))
    
    # Find the PenteTests group and add file references
    group_section = re.search(r'(503BD6572E2DA00D00280E36 \/\* PenteTests \*\/ = \{.*?children = \(\s*)(.*?)(\s*\);)', content, re.DOTALL)
    if group_section:
        existing_children = group_section.group(2)
        new_children = existing_children
        
        for file in test_files:
            child_line = f'\t\t\t\t{file_refs[file]} /* {file} */,\n'
            new_children += child_line
        
        content = content.replace(group_section.group(0),
                                group_section.group(1) + new_children + group_section.group(3))
    
    # Write the modified content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added test files to Xcode project!")
    print("Now you can build and run tests with: xcodebuild test -project Pente.xcodeproj -scheme PenteTests")

if __name__ == "__main__":
    add_test_files_to_project()