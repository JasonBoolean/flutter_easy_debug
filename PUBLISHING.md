# Publishing to pub.dev

Follow these steps to publish `easy_debug` to pub.dev.

## 1. Final Review
- **Repository URL**: Open `pubspec.yaml` and uncomment/fill in the `repository` line with your GitHub URL. This is critical for pub.dev verification score.
- **License**: Ensure `LICENSE` file has your correct name (already done).

## 2. Dry Run
Run this command to check for errors:
```bash
flutter pub publish --dry-run
```
Fix any warnings that appear.

## 3. Publish
```bash
flutter pub publish
```
1. Type `y` to confirm.
2. Click the link to zero-auth with your Google Account.
3. Success!

## 4. Verification
Visit [pub.dev](https://pub.dev/packages/easy_debug) to see your package.
