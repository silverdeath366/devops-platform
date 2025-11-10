import zipfile
import os

# Define the folder you want to zip
root_dir = "devops-platform-broken"
zip_filename = f"{root_dir}.zip"

# List of directory names to exclude
EXCLUDED_DIRS = {
    '.git',
    'node_modules',
    'venv',
    '.venv',
    '__pycache__',
    '.idea',
    '.vscode',
    'env',
}

# List of file patterns to exclude
EXCLUDED_EXTENSIONS = {
    '.log',
    '.pyc',
    '.DS_Store',
}

def should_exclude(path):
    # Split path and check each part against excluded dirs
    parts = path.split(os.sep)
    for part in parts:
        if part in EXCLUDED_DIRS:
            return True
    # Check for excluded file extensions
    if os.path.isfile(path):
        _, ext = os.path.splitext(path)
        if ext in EXCLUDED_EXTENSIONS:
            return True
    return False

with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for foldername, subfolders, filenames in os.walk(root_dir):
        # Skip excluded folders in-place to prevent traversal
        subfolders[:] = [d for d in subfolders if d not in EXCLUDED_DIRS]
        
        for filename in filenames:
            filepath = os.path.join(foldername, filename)
            if should_exclude(filepath):
                continue
            # Write file to zip, preserving relative path
            arcname = os.path.relpath(filepath, root_dir)
            zipf.write(filepath, arcname)

print(f"✅ Project zipped to: {zip_filename}")
