[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

A sample app that shows the use of `package:jenny` (Yarn Spinner)
for interactive dialogue.

### Building and publishing

This project uses `peanut` to deploy to GitHub Pages. 
Build thusly so that `$FLUTTER_BASE_HREF` is set up correctly.

```shell
peanut --extra-args "--base-href=/game_dialogue/"
git push origin --set-upstream gh-pages
```