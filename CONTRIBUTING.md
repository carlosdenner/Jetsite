# Contributing to Jetsite

Thank you for your interest in contributing to Jetsite! This document provides guidelines for contributing to the project.

## Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/Jetsite.git
   cd Jetsite
   ```
3. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Code Style Guidelines

### Bash Scripting Standards

- Use `#!/usr/bin/env bash` for maximum compatibility
- Enable strict mode with `set -euo pipefail`
- Use meaningful variable names in UPPER_CASE for environment variables
- Add comments for complex logic sections
- Use consistent indentation (2 spaces)
- Quote variables to prevent word splitting: `"$VARIABLE"`

### Documentation Standards

- Keep README.md up to date with any functional changes
- Add inline comments for complex bash operations
- Use emoji in user-facing messages for better UX
- Document all command-line options and environment variables

## Testing

Before submitting a pull request:

1. Test the script with different scenarios:
   - Valid template repositories
   - Invalid template repositories
   - Empty inputs
   - Network connectivity issues

2. Test the fallback mechanism:
   - Try with repositories that don't support templates
   - Verify the fork-and-rename workflow

3. Verify cross-platform compatibility (if applicable)

## Submitting Changes

1. Ensure your code follows the style guidelines
2. Add or update tests as needed
3. Update documentation if you're changing functionality
4. Write a clear commit message:
   ```
   Add feature: brief description
   
   - Detailed explanation of what changed
   - Why the change was necessary
   - Any breaking changes
   ```

5. Push to your fork and submit a pull request

## Pull Request Guidelines

- Use a clear and descriptive title
- Include a summary of changes in the description
- Link any related issues
- Add screenshots for UI changes (if applicable)
- Ensure all checks pass

## Reporting Issues

When reporting bugs:

1. Use a clear and descriptive title
2. Describe the exact steps to reproduce the issue
3. Include your environment details:
   - Operating system
   - Bash version
   - GitHub CLI version
4. Include any error messages or logs
5. Describe the expected vs. actual behavior

## Feature Requests

When requesting features:

1. Use a clear and descriptive title
2. Explain the use case and why it would be valuable
3. Provide examples of how the feature would work
4. Consider backward compatibility

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain a positive environment

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with the "question" label
- Start a discussion in the repository
- Reach out to the maintainers

Thank you for contributing to Jetsite! 🚀
