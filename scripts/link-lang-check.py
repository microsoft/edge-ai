#!/usr/bin/env python3
"""
Language Path Link Checker and Fixer

This script finds and optionally fixes URLs in git-tracked text files that contain
the language path segment 'en-us'. It helps maintain links that work regardless
of user language settings by removing unnecessary language path segments.

Functionality:
    - Scans git-tracked text files for URLs containing 'en-us'
    - Identifies link locations by file and line number
    - Optionally removes 'en-us/' from URLs to make them language-neutral
    - Reports changes in human-readable or JSON format

Parameters:
    -f, --fix: Fix URLs by removing "en-us/" instead of just reporting them
    -v, --verbose: Increase output verbosity with detailed processing information

Returns:
    JSON array or console output: When not in fix mode, outputs a JSON array of found links
                                 When in fix mode, outputs human-readable summary of changes

Raises:
    None: The script handles errors internally without raising exceptions

Dependencies:
    - git: Required for identifying text files under source control
    - Python 3.6+: Uses f-strings and other modern Python features

Example:
    # Search for URLs containing 'en-us' and output as JSON
    python link-lang-check.py

    # Fix URLs by removing 'en-us/' with verbose output
    python link-lang-check.py -f -v

Notes:
    The script is designed to help maintain documentation links that work regardless
    of the user's language settings in their browser.

See Also:
    - Microsoft documentation guidance on language neutrality: https://learn.microsoft.com/style-guide/urls-web-addresses
"""
import argparse
import re
import subprocess
import os
import json
from collections import defaultdict


def get_git_text_files():
    """
    Get list of all text files under git source control, excluding binary files.

    Uses git's built-in binary detection to exclude non-text files from processing.

    Returns:
        list: A list of file paths to text files tracked by git.

    Raises:
        None: Errors are handled internally and reported to stdout.
    """
    # Use git's binary detection with -I flag (--no-binary)
    result = subprocess.run(
        ['git', 'grep', '-I', '--name-only', '-e', ''],
        capture_output=True,
        text=True
    )

    if result.returncode > 1:  # git grep returns 1 if no matches, which is okay
        print(f"Error executing git grep: {result.stderr}")
        return []

    return result.stdout.strip().split('\n') if result.stdout.strip() else []


def find_links(file_path, verbose=False):
    """
    Find links with 'en-us' in them and return details.

    Scans the specified file for URLs containing the 'en-us' path segment and
    collects information about each occurrence.

    Args:
        file_path (str): Path to the file to scan
        verbose (bool): Whether to output additional information during processing

    Returns:
        list: A list of dictionaries, each containing information about a link:
              'file': The file path
              'line_number': The line number where the link appears
              'original_url': The original URL with 'en-us'
              'fixed_url': The URL with 'en-us/' removed

    Raises:
        None: Exceptions are caught and handled internally.
    """
    links_found = []

    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
    except (UnicodeDecodeError, IOError) as e:
        if verbose:
            print(f"Could not read {file_path}: {e}")
        return links_found

    # Regular expression to find URLs containing "en-us/"
    url_pattern = re.compile(r'https?://[^\s<>"\']+?en-us/[^\s<>"\']+')

    for i, line in enumerate(lines):
        matches = url_pattern.findall(line)
        for match in matches:
            links_found.append({
                'file': file_path,
                'line_number': i + 1,
                'original_url': match,
                'fixed_url': match.replace("en-us/", "")
            })

    return links_found


def fix_links_in_file(file_path, links, verbose=False):
    """
    Fix links in a single file by removing 'en-us/' from URLs.

    Opens the file, replaces URLs containing 'en-us/' with versions without it,
    and writes the changes back to the file.

    Args:
        file_path (str): Path to the file to modify
        links (list): List of link dictionaries for the file, each containing:
                     'original_url': The original URL to replace
                     'fixed_url': The URL to replace it with
        verbose (bool): Whether to output additional information during processing

    Returns:
        bool: True if the file was modified, False otherwise

    Raises:
        None: Exceptions are caught and handled internally.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
    except (UnicodeDecodeError, IOError) as e:
        if verbose:
            print(f"Could not read {file_path}: {e}")
        return False

    # Replace each link
    modified_content = content
    for link in links:
        modified_content = modified_content.replace(link['original_url'], link['fixed_url'])

    # Only write if changes were made
    if modified_content != content:
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(modified_content)
            return True
        except IOError as e:
            if verbose:
                print(f"Could not write to {file_path}: {e}")
            return False
    return False


def fix_all_links(all_links, verbose=False):
    """
    Fix all links in their respective files.

    Groups links by file, then calls fix_links_in_file for each file.

    Args:
        all_links (list): List of all link dictionaries found across files
        verbose (bool): Whether to output additional information during processing

    Returns:
        int: Number of files that were successfully modified
    """
    # Group links by file
    links_by_file = defaultdict(list)
    for link in all_links:
        links_by_file[link['file']].append(link)

    files_modified = 0

    # Fix links in each file
    for file_path, links in links_by_file.items():
        if verbose:
            print(f"Fixing links in {file_path}...")

        if fix_links_in_file(file_path, links, verbose):
            files_modified += 1

    return files_modified


def prepare_json_output(links):
    """
    Prepare links for JSON output by formatting as an array of link objects.

    Creates a clean representation without internal fields used for processing.

    Args:
        links (list): The complete list of link dictionaries

    Returns:
        list: A list of dictionaries ready for JSON serialization, each containing:
              'file': The file path
              'line_number': The line number where the link appears
              'original_url': The original URL with 'en-us'
    """
    json_data = []
    for link in links:
        # Create a copy without the fixed_url field
        json_link = {
            'file': link['file'],
            'line_number': link['line_number'],
            'original_url': link['original_url']
        }
        json_data.append(json_link)
    return json_data


def main():
    """
    Main entry point for the script.

    Parses command line arguments, scans files for links with 'en-us', and either
    outputs them as JSON or fixes them by removing 'en-us/' from the URLs.

    Args:
        None: Arguments are parsed from sys.argv

    Returns:
        None: Results are printed to stdout
    """
    parser = argparse.ArgumentParser(description='Find and fix "en-us" in URLs in git-tracked files.')
    parser.add_argument('-f', '--fix', action='store_true', help='Fix the URLs by removing "en-us/"')
    parser.add_argument('-v', '--verbose', action='store_true', help='Increase output verbosity')
    args = parser.parse_args()

    if args.verbose:
        print("Getting list of git-tracked text files...")

    files = get_git_text_files()

    if args.verbose:
        print(f"Found {len(files)} git-tracked text files")

    all_links = []

    for file_path in files:
        if not os.path.isfile(file_path):
            if args.verbose:
                print(f"Skipping {file_path}: not a regular file")
            continue

        if args.verbose:
            print(f"Processing {file_path}...")

        links = find_links(file_path, args.verbose)
        all_links.extend(links)

    # Report findings
    if all_links:
        if args.fix:
            # Human-readable output when fixing links
            if args.verbose:
                print(f"\nFound {len(all_links)} URLs containing 'en-us':\n")
                for link_info in all_links:
                    print(f"File: {link_info['file']}, Line: {link_info['line_number']}")
                    print(f"  URL: {link_info['original_url']}")
                    print()

            files_modified = fix_all_links(all_links, args.verbose)
            print(f"Fixed {len(all_links)} URLs in {files_modified} files.")

            if args.verbose:
                print("\nDetails of fixes:")
                for link_info in all_links:
                    print(f"File: {link_info['file']}, Line: {link_info['line_number']}")
                    print(f"  Original: {link_info['original_url']}")
                    print(f"  Fixed: {link_info['fixed_url']}")
                    print()
        else:
            # JSON output when not fixing links
            json_output = prepare_json_output(all_links)
            print(json.dumps(json_output, indent=2))
    else:
        if not args.fix:
            # Empty JSON array if no links found
            print("[]")
        else:
            print("No URLs containing 'en-us' were found.")


if __name__ == "__main__":
    main()
