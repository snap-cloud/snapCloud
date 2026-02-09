# Snap!Cloud SASS (CSS)

> August 2024

`*.scss` files in this folder use a tool called [SASS][sass] to compile to "plain" CSS.

All files are compiled to `static/style/compiled/`.
Today, all compiled files are commited to the repo for easy deployment.
Both the `start.sh` script, and the `Procfile` automatically run the sass compiler and watch for changes.

If you are working on
## Bootstrap 5 & FontAwesome

While we are migrating setups, these tools are **not** run through SASS.
Those files are loaded like normal in the HTML head.

In the future, we can (should) customize bootstrap by compiling it ourselves...

[sass]: https://sass-lang.com/documentation/syntax/
