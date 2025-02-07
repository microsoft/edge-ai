#!/usr/bin/env bash

WIKI_REPO_FOLDER=".wiki"

# Create the directory if it does not exist
if [ ! -d "$WIKI_REPO_FOLDER" ]; then
    mkdir -p $WIKI_REPO_FOLDER
fi

# Remove all contents in the work_dir except the .git folder
echo "Clearing wiki contents except for git folder ..."
find "./$WIKI_REPO_FOLDER" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +


# Function to update URLs in the copied documents
update_urls() {
    local file=$1
    local -n update_url_tuples=$2
    local src dest tuple
    # echo "Updating URLs in $file:"
    # Extract and print all URLs from the document that do not begin with
    # http:// or https:// and do not contain "media" or "mailto"
    grep -oP '(?<=\]\()[^)\s]+(?=\))|(?<=\]\<)[^>\s]+(?=\>)' "$file" | \
    grep -vP '^(http://|https://|#)' | \
    grep -v 'media' | \
    grep -v 'mailto' | \
    # Read each URL and update the URL in the document by iterating
    # over the tuples array and replacing the URL with the dest path
    # This will miss some URLs that are not in the tuples array
    # but without more engineering, this is the best we can do.
    while read -r url; do
        # echo "Updating URLs in $file:"
        # echo "url: $url"
        # If the $url begins with "./" then strip the "./"
        if [[ "$url" == ./* ]]; then
            stripped_url="${url#./}"
            # Add the stripped_url to the src path
            for tuple in "${update_url_tuples[@]}"; do
                src=$(echo "$tuple" | cut -d',' -f1 | tr -d '()')
                # xargs the second element to remove leading/trailing whitespace
                dest=$(echo "$tuple" | cut -d',' -f2 | tr -d '()' | xargs)
                # Look up the full path in the tuples array and get the matching dest path
                if [[ "$src" == *"$stripped_url"* ]]; then
                    # sed to replace the URL in the document
                    sed -i "s|$url|$dest|g" "$file"
                fi
            done
        fi
    done
}

# Function to copy documents from src to dest based on the tuples array
copy_documents() {
    local -n copy_docs_tuples=$1
    local src dest target_dest
    for tuple in "${copy_docs_tuples[@]}"; do
        src=$(echo "$tuple" | cut -d',' -f1 | tr -d '()')
        # xargs the second element to remove leading/trailing whitespace
        target_dest=$(echo "$tuple" | cut -d',' -f2 | tr -d '()' | xargs)
        # remove the "./" from the target_dest
        target_dest="${target_dest#./}"
        # append the WIKI_REPO_FOLDER to the target_dest
        dest="$WIKI_REPO_FOLDER/$target_dest"
        # make the directory if it does not exist
        if [ ! -d "$(dirname "$dest")" ]; then
            mkdir -p "$(dirname "$dest")"
        fi
        # echo "Copying $src to $dest"
        cp "$src" "$dest"
        # Call update_urls only if the file extension is .md
        # this will update the URLs in the copied markdown files
        # to align with the new wiki structure
        if [[ "$dest" == *.md ]]; then
            update_urls "$dest" copy_docs_tuples
        fi
    done
}

# Function to update the second element of the tuple for paths including "terraform" or "bicep"
update_paths() {
    local -n update_paths_tuples=$1
    local type=$2
    local src dest new_dest
    for entry in "${!update_paths_tuples[@]}"; do
        src=$(echo "${update_paths_tuples[$entry]}" | cut -d',' -f1 | tr -d '()')
        # xargs the second element to remove leading/trailing whitespace
        dest=$(echo "${update_paths_tuples[$entry]}" | cut -d',' -f2 | tr -d '()' | xargs)

        # If the dest is the './src' directory, update it to move that file
        # to the $type directory. These files will be duplicated for bicep
        # and terraform.
        if [[ "$dest" == *"./src/"* ]]; then
            new_dest="${dest/\.\/src/\.\/$type}"
            # echo "moving a core src file to: $new_dest"
            update_paths_tuples[entry]="($src, $new_dest)"
        fi

        # Create a camel-case version of the type for comparison
        # inbound the dest string will be "Terraform.md" or "Bicep.md"
        # and we want these files routed to the respective terraform or
        # bicep folders which happens in the if condition below
        type_caps=${type^}
        if [[ "$dest" == *"/$type/"* || "$dest" == *"/$type_caps.md" ]]; then
            new_dest="${dest/$type\/}"
            # this will replace the first occurrence of the $type in the path
            new_dest="${new_dest/\.\/src/\.\/$type}"
            # echo "new_dest: $new_dest"
            update_paths_tuples[entry]="($src, $new_dest)"
        fi
    done
}

# Define the folder paths to search for markdown files
FOLDER_PATHS=(
    "./.azdo"
    "./.devcontainer"
    "./.github"
    "./blueprints"
    "./docs"
    "./scripts"
    "./src"
    "./tests"
)

echo "Finding markdown docs contents..."

# Create an array of all markdown document and media file paths from
# the specified folders above.
markdown_files=()
for folder in "${FOLDER_PATHS[@]}"; do
    while IFS= read -r -d '' file; do
        markdown_files+=("$file")
    done < <(find "$folder" -type f \( -name "*.md" -o -name "*.png" \) -print0)
done

# Create tuples for src and dest paths, copies of the identical file path for now
src_dest_tuples=()
for file in "${markdown_files[@]}"; do
    src_dest_tuples+=("($file, $file)")
done

# Here we will process the tuples array and update the dest path for the
# README.md files to be the parent directory name in camel case.
# This will allow us to route the README.md files to the correct
# destination folder in the wiki, e.g. make folders clickable and display
# markdown.
#
# We will also remove the "docs/" from the dest path if it exists, to
# flatten the structure of the wiki.
for entry in "${!src_dest_tuples[@]}"; do
    src=$(echo "${src_dest_tuples[$entry]}" | cut -d',' -f1 | tr -d '()')
    # xargs the second element to remove leading/trailing whitespace
    dest=$(echo "${src_dest_tuples[$entry]}" | cut -d',' -f2 | tr -d '()' | xargs)

    # Replace README.md with the parent directory name in the dest path
    if [[ "$src" == *"/README.md" ]]; then
        # Get the parent directory name
        parent_dir=$(basename "$(dirname "$src")")
        # convert the parent directory name to camel case
        # camel_case_parent_dir=$(echo "${parent_dir#.}" | sed -r 's/(^|-)(\w)/\U\2/g')
        # Replace README.md with the parent directory name in the dest path
        # taking {dir-name}/README.md to {Dir-Name}.md
        new_dest="${src//\/$parent_dir\/README.md/\/$parent_dir.md}"
    else
        new_dest="$dest"
    fi
    # Remove "docs/" from the dest path if it exists
    if [[ "$new_dest" == *"/docs/"* ]]; then
        new_dest="${new_dest//\/docs\//\/}"
    fi
    # add the new tuple back into the tuples array
    src_dest_tuples[entry]="($src, $new_dest)"

done

# Update the destination paths to bring "terraform" or "bicep"
# path parts up front for organization. e.g. "src/005-onboarding-reqs
# becomes terraform/005-onboarding-reqs.md"
update_paths src_dest_tuples "terraform"
update_paths src_dest_tuples "bicep"

# After processing the tuples array, it will look like this:
# ...
# (./src/080-iot-ops-utility/terraform/README.md, ./terraform/080-iot-ops-utility/Terraform.md)
# (./src/080-iot-ops-utility/terraform/tests/README.md, ./terraform/080-iot-ops-utility/Tests.md)
# (./src/README.md, ./Src.md)
# (./tests/README.md, ./Tests.md)
# ...

# DEBUG Print the array
echo "Markdown document file paths:"
for file in "${src_dest_tuples[@]}"; do
    echo "$file"
done

# Copy the documents based on the tuples
copy_documents src_dest_tuples

# Rename main wiki readme
mv "$WIKI_REPO_FOLDER/docs.md" "$WIKI_REPO_FOLDER/getting-started.md"
cp "./CONTRIBUTING.md" "$WIKI_REPO_FOLDER/contributing.md"
cp "./CODE_OF_CONDUCT.md" "$WIKI_REPO_FOLDER/code-of-conduct.md"

# Create Azdo wiki .order file
echo "Creating .order file..."
echo "getting-started" > "$WIKI_REPO_FOLDER/.order"
echo "contributing" >> "$WIKI_REPO_FOLDER/.order"
echo "code-of-conduct" >> "$WIKI_REPO_FOLDER/.order"
