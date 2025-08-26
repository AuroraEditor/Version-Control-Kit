## Aurora Editor Sunset Announcement

After much thought and consideration, we have decided to officially sunset Aurora Editor.  
Aurora started as a community-driven effort to build a fast, lightweight, and truly native IDE for macOS developers. It grew out of passion, collaboration, and a shared vision for an open alternative. Along the way, contributors poured in their time, energy, and creativity to shape what Aurora became.  
But as with all projects, there comes a time to reflect on sustainability and focus. With limited resources, shifting priorities, and new tools emerging in the developer ecosystem, we believe it’s the right moment to bring Aurora Editor’s journey to a graceful close.  
The code will remain available on GitHub for anyone who wishes to explore, fork, or continue the vision in new directions. We deeply appreciate everyone who wrote code, opened issues, shared feedback, or simply used Aurora in their daily work-you kept the project alive and meaningful.  
Thank you for being part of Aurora’s story!  
Even though Aurora Editor is setting, the light it inspired will live on in the community.  
  
— The Aurora Editor Team (<a href='https://github.com/0xWDG'>@0xWDG</a> & <a href='https://github.com/nanashili'>@nanashili</a>).

----

<p align="center">
  <img alt="Logo" src="https://user-images.githubusercontent.com/63672227/193885608-d6217c57-6a12-4470-a0c7-f1ecc80bc3f2.png" width="128px;" height="128px;">
</p>

# Version Control Kit

## Overview
The AuroraEditor Version Control Kit is a comprehensive tool designed to facilitate version control operations within the AuroraEditor environment. It enables actions such as committing, pulling, pushing, and fetching history for entire files or specific lines of code. This project is an extraction from the main AuroraEditor Repository and is currently under development.

## Features (Not limited to the below mentioned)
- **Committing Changes**: Track and commit changes to your codebase.
- **Pulling Updates**: Synchronize your local repository with changes from a remote repository.
- **Pushing Changes**: Send your local commits to a remote repository.
- **Fetching History**: Access the history of changes for files or individual lines of code.
- **Git Services**: Allows you to make calls to GitHub, BitBucket and GitLab. (Create an issue if you want more Git providers added.)

## Installation

### Requirements
- Swift 3.0 or later.
- macOS Monterey or later

### Using Swift Package Manager

1. **Add Dependency**: 
   Edit your `Package.swift` to include AuroraEditor Version Control Kit as a dependency:
   
   ```swift
   dependencies: [
     .package(url: "https://github.com/AuroraEditor/Version-Control-Kit.git", from: "Version-0")
   ]
   ```

   Else if you want the latest up to date version use the branch name:

   ```swift
   dependencies: [
     .package(url: "https://github.com/AuroraEditor/Version-Control-Kit.git", .branch("main"))
   ]
   ```
## Usage

The AuroraEditor Version Control Kit's source code is in the process of being thoroughly documented. While many functions include detailed explanations, cautionary notes, and examples with their requirements, there are some areas still pending comprehensive documentation. These will be addressed and updated in due time. Users can look forward to a future How-To guide that will provide additional structured guidance on using the toolkit's capabilities.

## Socials

<p align="center">
  <a href='https://twitter.com/Aurora_Editor' target='_blank'>
    <img alt="Twitter Follow" src="https://img.shields.io/twitter/follow/Aurora_Editor?color=f6579d&style=for-the-badge">
  </a>
  <a href='https://discord.gg/5aecJ4rq9D' target='_blank'>
    <img alt="Discord" src="https://img.shields.io/discord/997410333348077620?color=f98a6c&style=for-the-badge">
  </a>
</p>
   
## Licenses

### Intellectual Property License
- The AuroraEditor Version Control Logo is the copyright of AuroraEditor and Aurora Company.

### GNU Affero General Public License v3.0
- This project is licensed under the GNU AGPL V3 License.

