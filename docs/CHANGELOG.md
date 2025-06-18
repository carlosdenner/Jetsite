# Changelog

All notable changes to the Jetsite project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project documentation
- Comprehensive README with usage examples
- Contributing guidelines
- Inline code documentation and comments

### Changed
- Enhanced user interface with emoji indicators
- Improved error messages and user feedback
- Better organization of script sections

### Fixed
- N/A (initial documented version)

## [1.0.0] - 2025-06-18

### Added
- Initial release of Jetsite
- Core functionality for forking GitHub template repositories
- Automatic repository creation with fallback mechanism
- Local cloning and VS Code integration
- GitHub CLI dependency checking
- Interactive user prompts for template and repository name selection
- Error handling and validation

### Features
- Create repositories from GitHub templates
- Fallback to fork-and-rename when template creation fails
- Automatic local cloning of new repositories
- VS Code integration for immediate project opening
- Cross-platform compatibility (bash environments)

### Dependencies
- GitHub CLI (gh) - Required
- Git - Required
- VS Code - Optional (for automatic project opening)

---

## Release Notes

### Version 1.0.0
This is the initial stable release of Jetsite. The script provides a streamlined workflow for developers who frequently create new projects from GitHub templates. Key benefits include:

- **Time Saving**: Automates the entire process from repository creation to local setup
- **Reliability**: Includes fallback mechanisms for maximum compatibility
- **User-Friendly**: Clear prompts and feedback throughout the process
- **IDE Integration**: Seamlessly opens projects in VS Code after creation

### Future Roadmap
- Support for private repository templates
- Configuration file support for default templates
- Integration with other IDEs (IntelliJ, Sublime Text, etc.)
- Project initialization hooks and custom scripts
- Batch processing for multiple repositories
